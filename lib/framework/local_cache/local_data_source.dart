import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:anoxia/common/utils/media_url_util.dart';
import '../domain/chat_contact_vo.dart';
import '../domain/chat_message.dart';
import '../domain/chat_room_vo.dart';
import '../domain/user_info.dart';
import '../protocol/message/message_enum.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import '../protocol/message/message_payload.dart';
import 'database.dart';
import 'session_epoch.dart';

class LocalDataSource {
  LocalDataSource(this.db, {SessionEpoch? sessionEpoch})
    : _sessionEpoch = sessionEpoch,
      _epoch = sessionEpoch?.value;

  final AppDatabase db;
  final SessionEpoch? _sessionEpoch;
  final int? _epoch;
  bool get isCurrentSession => _sessionEpoch?.value == _epoch;

  /// 核验必须在事务执行时进行；清缓存之前排队的旧写入也会被拒绝。
  Future<T> _write<T>(Future<T> Function() action) {
    return db.transaction(() async {
      void check() {
        if (!isCurrentSession) {
          throw StateError('stale session cache write');
        }
      }

      check();
      final result = await action();
      check();
      return result;
    });
  }

  Future<List<ChatRoomVO>> getConversations() async {
    final rows = await db.conversationDao.getConversations();
    return rows.map(_conversationFromRow).toList();
  }

  Stream<List<ChatRoomVO>> watchConversations() {
    return db.conversationDao.watchConversations().map(
      (rows) => rows.map(_conversationFromRow).toList(),
    );
  }

  Future<List<ChatMessage>> getMessagesForConversation(
    String convId, {
    int limit = 50,
    int offset = 0,
    int? beforeSeq,
  }) async {
    final rows = await db.messageDao.getMessagesForConversation(
      convId,
      limit: limit,
      offset: offset,
      beforeSeq: beforeSeq,
    );
    return rows.reversed.map(_messageFromRow).toList();
  }

  Stream<List<ChatMessage>> watchMessagesForConversation(
    String convId, {
    int? limit = 50,
    int offset = 0,
  }) {
    return db.messageDao
        .watchMessagesForConversation(convId, limit: limit, offset: offset)
        .map((rows) => rows.reversed.map(_messageFromRow).toList());
  }

  /// Persists an inbound message and its conversation projection atomically.
  /// This is the only write path for messages received from WebSocket.
  Future<bool> applyIncomingMessage(
    ChatMessage message, {
    required bool incrementUnread,
    bool clearUnread = false,
  }) async {
    return _write(() async {
      // 服务端给非发送方广播时可能不带 messageId/clientMsgId，用稳定派生 id 兜底，
      // 避免消息被静默丢弃（曾导致“对方收到但不显示”且无任何日志）。
      ChatMessage msg = message;
      final String messageId;
      {
        final candidate = message.messageId ?? message.clientMsgId;
        if (candidate == null || candidate.isEmpty) {
          final roomId = message.roomId ?? '';
          final senderId = message.senderId?.toString() ?? '';
          final seq = message.seq?.toString() ?? '';
          final ts = message.timestamp?.toString() ?? '';
          if (roomId.isEmpty) {
            debugLog(
              '[DB] applyIncomingMessage: 丢弃入站消息，messageId/clientMsgId 与 roomId 均为空',
            );
            return false;
          }
          messageId = 'fallback_${roomId}_${senderId}_${seq}_$ts';
          debugLog(
            '[DB] applyIncomingMessage: 入站消息缺 messageId，使用派生兜底 id=$messageId',
          );
          msg = message.copyWith(messageId: messageId);
        } else {
          messageId = candidate;
        }
      }
      final row = _messageToRow(
        msg.copyWith(deliveryStatus: DeliveryStatus.sent),
      );

      return db.transaction(() async {
        final existing = await db.messageDao.getMessageById(messageId);
        final previous =
            existing ??
            (row.clientMsgId == null
                ? null
                : await db.messageDao.getMessageByClientMsgId(
                    row.clientMsgId!,
                  ));
        final rowToPersist = previous == null
            ? row
            : row.copyWith(
                // ACK 和服务端回显是两个独立帧，抵达顺序不固定。较晚抵达
                // 的 seq=0 回显不能把 ACK 已写入的真实序号覆盖掉。
                seq: row.seq > previous.seq ? row.seq : previous.seq,
                clientMsgId: Value(row.clientMsgId ?? previous.clientMsgId),
                sentAt: Value(row.sentAt ?? previous.sentAt),
                localCreatedAt: previous.localCreatedAt,
              );
        await _ensureConversationExists(row.conversationId);
        await _ensureMessageSendersExist([rowToPersist]);
        await db.messageDao.insertOrUpdateMessage(rowToPersist);
        final persisted = await db.messageDao.getMessageById(rowToPersist.id);
        if (persisted?.isDeleted == true) return false;
        await db.conversationDao.updateIncomingMessage(
          conversationId: row.conversationId,
          messageId: messageId,
          preview: msg.content,
          messageType: msg.messageType == null
              ? null
              : MessageType.toCode(msg.messageType),
          seq: rowToPersist.seq,
          sentAt: rowToPersist.sentAt,
          incrementUnread: incrementUnread && previous == null,
          clearUnread: clearUnread,
        );
        await _advanceMessageWatermark(row.conversationId, message.seq);
        // 以是否按 clientMsgId 找到先前记录为准，而不是按 messageId：
        // 服务端会把自己的消息回显给发送方（ACK 与回显到达顺序不定），
        // 回显的 messageId 可能是服务端新 id 或派生兜底 id，此时 existing
        // 为 null，但按 clientMsgId 能找到已存在的记录 → 视为重复写入，
        // 避免自己的回显被当作新消息再次触发房间位置更新与通知。
        return previous == null;
      });
    });
  }

  Future<int> messageSyncWatermark(String convId) async {
    return _write(() async {
      final state = await db.syncStateDao.getState('messages', convId);
      if (state != null) return state.lastSeq;

      // One-time migration for databases created before the watermark existed.
      final watermark = await maxContinuousMessageSeq(convId);
      await db.syncStateDao.upsertState(
        scope: 'messages',
        scopeId: convId,
        lastSyncedAt: DateTime.now(),
        lastSeq: watermark,
      );
      return watermark;
    });
  }

  /// 将 messages 水位单调抬升到至少 [seq]（只增不回退）。
  ///
  /// 事务内「读当前水位 - 取大 - 写入」，防止 incremental sync 用早期批次快照
  /// 覆盖 WS push（_advanceMessageWatermark）已推进的水位导致水位回退，
  /// 进而破坏 push 路径的连续性 seq+1 判定。
  Future<void> advanceMessagesWatermarkAtLeast(String convId, int seq) async {
    return _write(() async {
      await db.transaction(() async {
        final state = await db.syncStateDao.getState('messages', convId);
        final current = state?.lastSeq ?? 0;
        await db.syncStateDao.upsertState(
          scope: 'messages',
          scopeId: convId,
          lastSyncedAt: DateTime.now(),
          lastSeq: seq > current ? seq : current,
        );
      });
    });
  }

  Future<void> _advanceMessageWatermark(String convId, int? seq) async {
    if (seq == null || seq <= 0) return;
    final current = await db.syncStateDao.getState('messages', convId);
    final watermark = current?.lastSeq ?? 0;
    // Only advance a continuous watermark. A gap is recovered by syncMessages.
    if (seq == watermark + 1) {
      await db.syncStateDao.upsertState(
        scope: 'messages',
        scopeId: convId,
        lastSyncedAt: DateTime.now(),
        lastSeq: seq,
      );
    }
  }

  Future<DateTime?> latestConversationUpdatedAt() {
    return db.conversationDao.getLatestUpdatedAt();
  }

  Future<int> maxMessageSeq(String convId) => db.messageDao.getMaxSeq(convId);

  Future<int> maxContinuousMessageSeq(String convId) async {
    final seqs = await db.messageDao.getMessageSeqsForConversation(convId);
    var watermark = 0;
    for (final seq in seqs) {
      if (seq == watermark + 1) {
        watermark = seq;
      } else if (seq > watermark + 1) {
        break;
      }
    }
    return watermark;
  }

  Future<DateTime?> latestMessageSentAt(String convId) {
    return db.messageDao.getLatestSentAt(convId);
  }

  Future<void> upsertConversation(ChatRoomVO room) async {
    return _write(() async {
      await _ensurePeerUsersExist([room]);
      return db.conversationDao.insertOrUpdateConversation(
        await _mergeConversationProjection(room),
      );
    });
  }

  Future<void> upsertConversations(Iterable<ChatRoomVO> rooms) async {
    return _write(() async {
      final roomList = rooms.toList();
      await _ensurePeerUsersExist(roomList);
      for (final room in roomList) {
        await db.conversationDao.insertOrUpdateConversation(
          await _mergeConversationProjection(room),
        );
      }
    });
  }

  /// 确保 [rooms] 中所有 [ChatRoomVO.peerId] 在 cached_users 表中存在占位记录，
  /// 以满足 conversations.peer_id 的外键约束。
  Future<void> _ensurePeerUsersExist(Iterable<ChatRoomVO> rooms) async {
    final peerIds = rooms.map((r) => r.peerId).whereType<int>().toSet();
    if (peerIds.isEmpty) return;

    final existing = await db.userDao.getUsersByIds(peerIds);
    final existingIds = existing.map((u) => u.userId).toSet();
    final now = DateTime.now();
    final missing = peerIds
        .where((id) => !existingIds.contains(id))
        .map(
          (id) => CachedUsersCompanion(userId: Value(id), cachedAt: Value(now)),
        )
        .toList();
    if (missing.isNotEmpty) {
      await db.userDao.insertOrUpdateUsers(missing);
    }
  }

  Future<void> upsertMessage(ChatMessage message) async {
    return _write(() async {
      final row = _messageToRow(message);
      await db.transaction(() async {
        await _ensureConversationExists(row.conversationId);
        await _ensureMessageSendersExist([row]);
        await db.messageDao.insertOrUpdateMessage(row);
        if ((await db.messageDao.getMessageById(row.id))?.isDeleted == true) {
          return;
        }
        final roomId = message.roomId;
        if (roomId != null && roomId.isNotEmpty) {
          await db.conversationDao.updateLastMessage(
            conversationId: roomId,
            messageId: message.messageId ?? message.clientMsgId ?? '',
            preview: message.content,
            messageType: message.messageType == null
                ? null
                : MessageType.toCode(message.messageType),
            seq: message.seq,
            sentAt: _dateTimeFromMillis(message.timestamp),
          );
        }
      });
    });
  }

  Future<void> upsertMessages(Iterable<ChatMessage> messages) async {
    return _write(() async {
      final rows = messages.map(_messageToRow).toList();
      if (rows.isEmpty) return;

      for (final conversationId
          in rows.map((row) => row.conversationId).toSet()) {
        await _ensureConversationExists(conversationId);
      }
      await _ensureMessageSendersExist(rows);
      await db.messageDao.insertOrUpdateMessages(rows);
    });
  }

  /// 确保 [rows] 中所有 [CachedMessage.senderId] 在 cached_users 表中存在占位记录，
  /// 以满足 messages.sender_id 的外键约束。
  Future<void> _ensureMessageSendersExist(Iterable<CachedMessage> rows) async {
    final senderIds = rows.map((r) => r.senderId).whereType<int>().toSet();
    if (senderIds.isEmpty) return;

    final existing = await db.userDao.getUsersByIds(senderIds);
    final existingIds = existing.map((u) => u.userId).toSet();
    final now = DateTime.now();
    final missing = senderIds
        .where((id) => !existingIds.contains(id))
        .map(
          (id) => CachedUsersCompanion(userId: Value(id), cachedAt: Value(now)),
        )
        .toList();
    if (missing.isNotEmpty) {
      await db.userDao.insertOrUpdateUsers(missing);
    }
  }

  Future<void> upsertUser(UserInfo user) {
    return _write(() async {
      final now = DateTime.now();
      return db.userDao.insertOrUpdateUser(
        CachedUsersCompanion(
          userId: Value(user.userId),
          userName: Value(user.userName),
          nickName: Value(user.nickName),
          email: Value(user.email),
          phoneNumber: Value(user.phoneNumber),
          sex: Value(user.sex),
          avatar: Value(user.avatar),
          updatedAt: Value(now),
          cachedAt: Value(now),
        ),
      );
    });
  }

  Future<void> markConversationAsRead(String conversationId, {int? seq}) {
    return _write(() async {
      return db.conversationDao.markAsRead(conversationId, lastReadSeq: seq);
    });
  }

  /// 本地已读与待确认游标同事务提交；旧请求不能覆盖较大的游标。
  Future<void> queueReadCursor(String roomId, int seq) async {
    return _write(() async {
      if (seq <= 0) return;
      await db.transaction(() async {
        final room = await db.conversationDao.getConversation(roomId);
        if (room == null) return;
        final effectiveSeq = room.lastReadSeq > seq ? room.lastReadSeq : seq;
        await markConversationAsRead(roomId, seq: effectiveSeq);
        final pending = await db.syncStateDao.getState(
          'read_cursor_pending',
          roomId,
        );
        if (pending != null && pending.lastSeq >= effectiveSeq) return;
        await db.syncStateDao.upsertState(
          scope: 'read_cursor_pending',
          scopeId: roomId,
          lastSeq: effectiveSeq,
        );
      });
    });
  }

  Future<Map<String, int>> pendingReadCursors() async {
    final rows = await (db.select(
      db.syncStates,
    )..where((t) => t.scope.equals('read_cursor_pending'))).get();
    return {for (final row in rows) row.scopeId: row.lastSeq};
  }

  Future<void> acknowledgeReadCursor(String roomId, int seq) async {
    return _write(() async {
      await (db.delete(db.syncStates)..where(
            (t) =>
                t.scope.equals('read_cursor_pending') &
                t.scopeId.equals(roomId) &
                t.lastSeq.isSmallerOrEqualValue(seq),
          ))
          .go();
    });
  }

  Future<List<ChatMessage>> pendingOutgoingMessages() async {
    final rows = await db.messageDao.getPendingOutgoingMessages();
    // 兜底过滤：payload 里还是本地路径的消息不允许重放。
    // 正常路径下这类消息不会落库（见 ChatMessages.upsertMessage），
    // 但历史数据/异常写入仍可能留下脏行，重放会把本地路径当 URL 发给服务端。
    return rows
        .map(_messageFromRow)
        .where((message) => !_hasPendingLocalMedia(message))
        .toList();
  }

  /// 消息的媒体附件里是否还有未上传完成的本地路径
  bool _hasPendingLocalMedia(ChatMessage message) {
    final attachments = message.payload?.mediaAttachments;
    if (attachments == null || attachments.isEmpty) return false;
    return attachments.any(
      (attachment) => isPendingLocalMediaUrl(attachment.url),
    );
  }

  Future<ChatMessage?> getMessageByClientMsgId(String clientMsgId) async {
    final row = await db.messageDao.getMessageByClientMsgId(clientMsgId);
    return row == null ? null : _messageFromRow(row);
  }

  Future<ChatMessage?> getMessageById(String messageId) async {
    final row = await db.messageDao.getMessageById(messageId);
    return row == null ? null : _messageFromRow(row);
  }

  /// 业务永久拒绝仍显示失败，但不再随重连自动发送；用户手动重试可重置。
  Future<void> markOutgoingTerminal(String messageId) {
    return _write(
      () => db.messageDao.updateDeliveryStatus(messageId, 'FAILED_PERMANENT'),
    );
  }

  Future<void> updateDeliveryStatus(
    String messageId,
    DeliveryStatus status, {
    String? serverMessageId,
    int? seq,
    DateTime? sentAt,
  }) {
    return _write(() async {
      return db.messageDao.updateDeliveryStatus(
        messageId,
        status.toJson(),
        serverMessageId: serverMessageId,
        seq: seq,
        sentAt: sentAt,
      );
    });
  }

  Future<void> updateConversationForIncomingMessage(
    ChatMessage message, {
    required bool incrementUnread,
  }) async {
    return _write(() async {
      final roomId = message.roomId;
      final messageId = message.messageId ?? message.clientMsgId;
      if (roomId == null ||
          roomId.isEmpty ||
          messageId == null ||
          messageId.isEmpty) {
        return;
      }

      await db.conversationDao.updateIncomingMessage(
        conversationId: roomId,
        messageId: messageId,
        preview: message.content,
        messageType: message.messageType == null
            ? null
            : MessageType.toCode(message.messageType),
        seq: message.seq,
        sentAt: _dateTimeFromMillis(message.timestamp),
        incrementUnread: incrementUnread,
      );
    });
  }

  Future<void> markConversationDeleted(String conversationId) {
    return _write(() async {
      return db.conversationDao.markDeleted(conversationId);
    });
  }

  Future<void> deleteConversationCache(String conversationId) async {
    return _write(() async {
      await db.transaction(() async {
        await (db.delete(
          db.messages,
        )..where((tbl) => tbl.conversationId.equals(conversationId))).go();
        await (db.delete(
          db.conversations,
        )..where((tbl) => tbl.id.equals(conversationId))).go();
        await (db.delete(db.syncStates)..where(
              (tbl) =>
                  tbl.scope.isIn(['messages', 'read_cursor_pending']) &
                  tbl.scopeId.equals(conversationId),
            ))
            .go();
      });
    });
  }

  /// 对账删除：移除服务端权威列表之外的所有本地会话
  ///
  /// 服务端 /chat/rooms 返回完整、无分页的当前用户房间列表，
  /// 不在其中的本地行（旧账号残留、已退群/被移除、服务器重置后的幽灵行）
  /// 一律连同其消息与同步水位一起清除，避免聊天列表出现「别人的房间」。
  Future<void> deleteConversationsNotIn(Iterable<String> keepIds) async {
    return _write(() async {
      final keep = keepIds.toSet();
      await db.transaction(() async {
        if (keep.isEmpty) {
          await db.delete(db.messages).go();
          await db.delete(db.conversations).go();
          await (db.delete(db.syncStates)..where(
                (tbl) => tbl.scope.isIn(['messages', 'read_cursor_pending']),
              ))
              .go();
          return;
        }
        await (db.delete(
          db.messages,
        )..where((tbl) => tbl.conversationId.isNotIn(keep))).go();
        await (db.delete(
          db.conversations,
        )..where((tbl) => tbl.id.isNotIn(keep))).go();
        await (db.delete(db.syncStates)..where(
              (tbl) =>
                  tbl.scope.isIn(['messages', 'read_cursor_pending']) &
                  tbl.scopeId.isNotIn(keep),
            ))
            .go();
      });
    });
  }

  Future<void> updateConversationStatus(String conversationId, int status) {
    return _write(() async {
      return db.conversationDao.updateStatus(conversationId, status);
    });
  }

  Future<void> deleteMessage(String messageId) async {
    return _write(() async {
      await db.transaction(() async {
        final message = await db.messageDao.getMessageById(messageId);
        await db.messageDao.deleteMessage(messageId);
        // 需要修复摘要的会话：消息行所在的会话 + 所有摘要仍指向该 id 的会话。
        // 后者覆盖“仅存在于房间列表摘要、尚未下载到消息表”的情况：
        // 此时 message 为空，但 tombstone 已保存，必须把摘要原文清掉，
        // 否则房间列表会一直残留已撤回的原文。
        final affected = <String>{};
        if (message != null) affected.add(message.conversationId);
        final stale =
            await (db.select(
              db.conversations,
            )..where((t) => t.lastMessageId.equals(messageId))).get();
        for (final row in stale) {
          affected.add(row.id);
        }
        for (final convId in affected) {
          final room = await db.conversationDao.getConversation(convId);
          if (room?.lastMessageId != messageId) continue;
          final latest =
              await (db.select(db.messages)
                    ..where(
                      (t) =>
                          t.conversationId.equals(convId) &
                          t.isDeleted.equals(false),
                    )
                    ..orderBy([
                      (t) => OrderingTerm(
                        expression: t.sentAt,
                        mode: OrderingMode.desc,
                      ),
                      (t) => OrderingTerm(
                        expression: t.seq,
                        mode: OrderingMode.desc,
                      ),
                    ])
                    ..limit(1))
                  .get();
          final replacement = latest.isEmpty ? null : latest.first;
          await (db.update(
            db.conversations,
          )..where((t) => t.id.equals(convId))).write(
            ConversationsCompanion(
              lastMessageId: Value(replacement?.id),
              lastMessagePreview: Value(replacement?.content),
              lastMessageType: Value(replacement?.messageType),
              lastMessageSeq: Value(replacement?.seq),
              lastMessageAt: Value(replacement?.sentAt),
              updatedAt: Value(
                replacement?.sentAt ?? room?.createdAt ?? DateTime.now(),
              ),
            ),
          );
        }
      });
    });
  }

  /// 对已经应用过的撤回不重复写库；无消息行的撤回也保存 tombstone。
  Future<void> applyRecalls(Iterable<String> messageIds) async {
    return _write(() async {
      final ids = messageIds.toSet();
      if (ids.isEmpty) return;
      final known =
          await (db.select(db.syncStates)..where(
                (t) => t.scope.equals('message_deleted') & t.scopeId.isIn(ids),
              ))
              .get();
      final knownIds = known.map((t) => t.scopeId).toSet();
      for (final id in ids.difference(knownIds)) {
        await deleteMessage(id);
      }
    });
  }

  Future<void> deleteMessagesForConversation(String conversationId) {
    return _write(() async {
      return db.messageDao.deleteMessagesForConversation(conversationId);
    });
  }

  Future<void> updateSyncState({
    required String scope,
    String scopeId = 'global',
    DateTime? lastSyncedAt,
    int? lastSeq,
  }) {
    return _write(() async {
      return db.syncStateDao.upsertState(
        scope: scope,
        scopeId: scopeId,
        lastSyncedAt: lastSyncedAt,
        lastSeq: lastSeq,
      );
    });
  }

  Future<void> logSyncFailure({
    required String scope,
    String? scopeId,
    required String action,
    required Object error,
    int retryCount = 0,
  }) {
    return _write(() async {
      final now = DateTime.now();
      return db.syncLogDao
          .insertLog(
            SyncLogsCompanion(
              scope: Value(scope),
              scopeId: Value(scopeId),
              action: Value(action),
              status: const Value('FAILED'),
              message: Value(error.toString()),
              createdAt: Value(now),
              nextRetryAt: Value(
                now.add(Duration(minutes: 1 << retryCount.clamp(0, 5))),
              ),
              retryCount: Value(retryCount),
            ),
          )
          .then((_) {});
    });
  }

  Future<ConversationsCompanion> _mergeConversationProjection(
    ChatRoomVO room,
  ) async {
    final incoming = _conversationToCompanion(room);
    final existing = await db.conversationDao.getConversation(
      room.roomId ?? '',
    );
    final messageId =
        room.lastMessage?.messageId ?? room.lastMessage?.clientMsgId;
    final deleted =
        messageId != null &&
        (await db.syncStateDao.getState('message_deleted', messageId)) != null;
    final newerLocal =
        existing != null &&
        ((existing.lastMessageSeq ?? 0) > (room.lastMessage?.seq ?? 0) ||
            ((existing.lastMessageSeq ?? 0) == 0 &&
                existing.lastMessageAt != null &&
                existing.lastMessageAt!.isAfter(
                  _dateTimeFromMillis(room.lastMessage?.timestamp) ??
                      DateTime(1970),
                )));
    if (!deleted && !newerLocal) return incoming;
    // 本地要保留的摘要本身也可能是指向 tombstone 的历史残留
    // （旧版本撤回仅在摘要时未清理）。最终摘要绝不能指向已删除 id，
    // 否则残留会借助“保护本地较新摘要”逻辑永久存活。
    if (existing != null && existing.lastMessageId != null) {
      final existingDeleted =
          (await db.syncStateDao.getState(
            'message_deleted',
            existing.lastMessageId!,
          )) !=
          null;
      if (existingDeleted) {
        final latest =
            await (db.select(db.messages)
                  ..where(
                    (t) =>
                        t.conversationId.equals(existing.id) &
                        t.isDeleted.equals(false),
                  )
                  ..orderBy([
                    (t) => OrderingTerm(
                      expression: t.sentAt,
                      mode: OrderingMode.desc,
                    ),
                    (t) => OrderingTerm(
                      expression: t.seq,
                      mode: OrderingMode.desc,
                    ),
                  ])
                  ..limit(1))
                .get();
        final replacement = latest.isEmpty ? null : latest.first;
        return incoming.copyWith(
          lastMessageId: Value(replacement?.id),
          lastMessagePreview: Value(replacement?.content),
          lastMessageType: Value(replacement?.messageType),
          lastMessageSeq: Value(replacement?.seq),
          lastMessageAt: Value(replacement?.sentAt),
          updatedAt: Value(
            replacement?.sentAt ?? existing.createdAt ?? DateTime.now(),
          ),
        );
      }
    }
    return incoming.copyWith(
      lastMessageId: Value(existing?.lastMessageId),
      lastMessagePreview: Value(existing?.lastMessagePreview),
      lastMessageType: Value(existing?.lastMessageType),
      lastMessageSeq: Value(existing?.lastMessageSeq),
      lastMessageAt: Value(existing?.lastMessageAt),
      updatedAt: Value(existing?.updatedAt ?? DateTime.now()),
    );
  }

  ConversationsCompanion _conversationToCompanion(ChatRoomVO room) {
    final now = DateTime.now();
    final lastMessage = room.lastMessage;
    final lastAt = _dateTimeFromMillis(lastMessage?.timestamp);
    return ConversationsCompanion(
      id: Value(room.roomId ?? ''),
      name: Value(room.roomName),
      avatar: Value(room.roomAvatar),
      description: Value(room.roomDescription),
      type: Value(room.roomType ?? 0),
      status: Value(room.roomStatus ?? 0),
      peerId: Value(room.peerId),
      unreadCount: Value(room.unreadCount ?? 0),
      lastReadSeq: Value(room.lastReadSeq ?? 0),
      lastMessageId: Value(lastMessage?.messageId ?? lastMessage?.clientMsgId),
      lastMessagePreview: Value(lastMessage?.content),
      lastMessageType: Value(
        lastMessage?.messageType == null
            ? null
            : MessageType.toCode(lastMessage?.messageType),
      ),
      lastMessageSeq: Value(lastMessage?.seq),
      lastMessageAt: Value(lastAt),
      createdAt: Value(room.createdAt),
      updatedAt: Value(lastAt ?? room.createdAt ?? now),
      cachedAt: Value(now),
      isDeleted: const Value(false),
    );
  }

  Future<void> _ensureConversationExists(String conversationId) async {
    final existing = await db.conversationDao.getConversation(conversationId);
    if (existing != null) return;
    final now = DateTime.now();
    await db.conversationDao.insertOrUpdateConversation(
      ConversationsCompanion(
        id: Value(conversationId),
        updatedAt: Value(now),
        cachedAt: Value(now),
      ),
    );
  }

  CachedMessage _messageToRow(ChatMessage message) {
    final now = DateTime.now();
    final id = message.messageId ?? message.clientMsgId;
    final roomId = message.roomId;
    if (id == null || id.isEmpty) {
      throw ArgumentError.value(id, 'message.id', 'message id is required');
    }
    if (roomId == null || roomId.isEmpty) {
      throw ArgumentError.value(
        roomId,
        'message.roomId',
        'room id is required',
      );
    }

    return CachedMessage(
      id: id,
      clientMsgId: message.clientMsgId,
      conversationId: roomId,
      senderId: message.senderId,
      messageType: MessageType.toCode(message.messageType),
      content: message.content,
      payloadJson: _jsonEncodeOrNull(message.payload?.toJson()),
      propertiesJson: _jsonEncodeOrNull(message.properties),
      deliveryStatus: message.deliveryStatus.toJson(),
      seq: message.seq ?? 0,
      sentAt: _dateTimeFromMillis(message.timestamp),
      localCreatedAt: now,
      updatedAt: now,
      isDeleted: false,
    );
  }

  ChatRoomVO _conversationFromRow(CachedConversation row) {
    final lastMessage = row.lastMessageId == null
        ? null
        : ChatMessage(
            messageId: row.lastMessageId,
            roomId: row.id,
            messageType: row.lastMessageType == null
                ? null
                : MessageType.fromCode(row.lastMessageType),
            content: row.lastMessagePreview ?? '',
            seq: row.lastMessageSeq,
            timestamp: row.lastMessageAt?.millisecondsSinceEpoch,
          );
    return ChatRoomVO(
      roomId: row.id,
      roomName: row.name,
      roomAvatar: row.avatar,
      roomDescription: row.description,
      roomStatus: row.status,
      roomType: row.type,
      createdAt: row.createdAt,
      lastReadSeq: row.lastReadSeq,
      peerId: row.peerId,
      unreadCount: row.unreadCount,
      lastMessage: lastMessage,
    );
  }

  ChatMessage _messageFromRow(CachedMessage row) {
    final payloadMap = _decodeJsonMap(row.payloadJson);
    final propertiesMap = _decodeJsonMap(row.propertiesJson);
    final payload = payloadMap == null
        ? null
        : MessagePayload.fromJson(payloadMap);
    final baseProperties =
        propertiesMap?.map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
        ) ??
        const {};
    return ChatMessage(
      messageId: row.id,
      clientMsgId: row.clientMsgId,
      roomId: row.conversationId,
      senderId: row.senderId,
      messageType: MessageType.fromCode(row.messageType),
      content: row.content,
      payload: payload,
      // V6 老缓存行的系统展示变量可能只存在 payload.system.properties 里
      // （properties 列当时为空），加载时一并合并，避免回显“--”残缺文案。
      properties: ChatMessage.mergeSystemProperties(baseProperties, payload),
      deliveryStatus: DeliveryStatus.from(row.deliveryStatus),
      timestamp:
          row.sentAt?.millisecondsSinceEpoch ??
          row.localCreatedAt.millisecondsSinceEpoch,
      seq: row.seq,
    );
  }

  String? _jsonEncodeOrNull(Object? value) {
    if (value == null) return null;
    return jsonEncode(value);
  }

  Map<String, dynamic>? _decodeJsonMap(String? value) {
    if (value == null || value.isEmpty) return null;
    final decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  }

  DateTime? _dateTimeFromMillis(int? millis) {
    if (millis == null || millis <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 联系人缓存
  // ─────────────────────────────────────────────────────────────────────────

  /// 获取本地所有联系人
  Future<List<ChatContactVO>> getContacts() async {
    final rows = await db.contactDao.getAllContacts();
    return rows.map(_contactFromRow).toList();
  }

  /// 监听联系人列表变化（响应式）
  Stream<List<ChatContactVO>> watchContacts() {
    return db.contactDao.watchAllContacts().map(
      (rows) => rows.map(_contactFromRow).toList(),
    );
  }

  /// 插入或更新联系人列表
  Future<void> upsertContacts(Iterable<ChatContactVO> contacts) async {
    return _write(() async {
      final valid = contacts.where((c) => c.contactId != null).toList();
      if (valid.isEmpty) return;
      await db.contactDao.insertOrUpdateContacts(
        valid.map(_contactToCompanion),
      );
    });
  }

  /// 成功的全量响应与本地对账；异常响应由调用方拒绝，不能当作空列表。
  Future<void> replaceContacts(List<ChatContactVO> contacts) async {
    return _write(() async {
      if (contacts.any((c) => c.contactId == null)) {
        throw const FormatException('contact id is required');
      }
      await db.transaction(() async {
        await upsertContacts(contacts);
        final ids = contacts.map((c) => c.contactId!).toSet();
        await (db.delete(
          db.cachedContacts,
        )..where((t) => t.contactId.isNotIn(ids))).go();
      });
    });
  }

  /// 插入或更新单个联系人
  Future<void> upsertContact(ChatContactVO contact) async {
    return _write(() async {
      if (contact.contactId == null) return;
      await db.contactDao.insertOrUpdateContact(_contactToCompanion(contact));
    });
  }

  /// 删除联系人（解除好友时调用）
  Future<void> deleteContact(int contactId) async {
    return _write(() async {
      await db.contactDao.deleteContact(contactId);
    });
  }

  /// 更新联系人在线状态（由 WebSocket 触发，只更新 DB 字段，不影响完整联系人信息）
  Future<void> updateContactOnlineStatus(int contactId, bool isOnline) {
    return _write(() async {
      return db.contactDao.updateOnlineStatus(contactId, isOnline);
    });
  }

  /// 获取最近联系人更新时间（用于增量同步）
  Future<DateTime?> latestContactUpdatedAt() {
    return db.contactDao.getLatestUpdatedAt();
  }

  // ── 私有转换 ──────────────────────────────────────────────────────────────

  Future<void> clearSessionCache() async {
    await db.clearSessionCache();
  }

  ChatContactVO _contactFromRow(CachedContact row) {
    return ChatContactVO(
      contactId: row.contactId,
      remark: row.remark,
      nickName: row.nickName,
      avatar: row.avatar,
      sex: row.sex,
      onlineStatus: row.onlineStatus,
    );
  }

  CachedContactsCompanion _contactToCompanion(ChatContactVO c) {
    final now = DateTime.now();
    return CachedContactsCompanion(
      contactId: Value(c.contactId!),
      remark: Value(c.remark),
      nickName: Value(c.nickName),
      avatar: Value(c.avatar),
      sex: Value(c.sex),
      onlineStatus: Value(c.onlineStatus ?? false),
      updatedAt: Value(now),
      cachedAt: Value(now),
    );
  }
}
