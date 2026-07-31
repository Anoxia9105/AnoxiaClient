import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/chat_contact_vo.dart';
import '../domain/chat_message.dart';
import '../domain/chat_room_vo.dart';
import '../domain/user_info.dart';
import '../protocol/message/message_enum.dart';
import '../logs/talker.dart';
import '../protocol/message/message_payload.dart';
import 'database.dart';

class LocalDataSource {
  LocalDataSource(this.db);

  final AppDatabase db;

  Future<List<ChatRoomVO>> getConversations() async {
    final rows = await db.conversationDao.getConversations();
    log.debug('[DB] getConversations → ${rows.length} rows');
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
    log.debug(
      '[DB] getMessages convId=$convId offset=$offset → ${rows.length} rows',
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
    final row = _messageToRow(
      message.copyWith(deliveryStatus: DeliveryStatus.sent),
    );
    final messageId = message.messageId ?? message.clientMsgId;
    if (messageId == null || messageId.isEmpty) return false;

    return db.transaction(() async {
      final existing = await db.messageDao.getMessageById(messageId);
      await _ensureConversationExists(row.conversationId);
      await _ensureMessageSendersExist([row]);
      await db.messageDao.insertOrUpdateMessage(row);
      await db.conversationDao.updateIncomingMessage(
        conversationId: row.conversationId,
        messageId: messageId,
        preview: message.content,
        messageType: message.messageType == null
            ? null
            : MessageType.toCode(message.messageType),
        seq: message.seq,
        sentAt: _dateTimeFromMillis(message.timestamp),
        incrementUnread: incrementUnread && existing == null,
        clearUnread: clearUnread,
      );
      await _advanceMessageWatermark(row.conversationId, message.seq);
      return existing == null;
    });
  }

  Future<int> messageSyncWatermark(String convId) async {
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
    log.debug(
      '[DB] upsertConversation roomId=${room.roomId} peerId=${room.peerId}',
    );
    await _ensurePeerUsersExist([room]);
    return db.conversationDao.insertOrUpdateConversation(
      _conversationToCompanion(room),
    );
  }

  Future<void> upsertConversations(Iterable<ChatRoomVO> rooms) async {
    final roomList = rooms.toList();
    log.debug(
      '[DB] upsertConversations count=${roomList.length} ids=${roomList.map((r) => r.roomId).toList()}',
    );
    await _ensurePeerUsersExist(roomList);
    return db.conversationDao.insertOrUpdateConversations(
      roomList.map(_conversationToCompanion),
    );
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
      log.debug(
        '[DB] _ensurePeerUsersExist: insert ${missing.length} stub users, ids=${missing.map((u) => u.userId.value).toList()}',
      );
      await db.userDao.insertOrUpdateUsers(missing);
    }
  }

  Future<void> upsertMessage(ChatMessage message) async {
    final row = _messageToRow(message);
    log.debug(
      '[DB] upsertMessage id=${message.messageId} room=${message.roomId} seq=${message.seq} status=${message.deliveryStatus}',
    );
    await db.transaction(() async {
      await _ensureConversationExists(row.conversationId);
      await _ensureMessageSendersExist([row]);
      await db.messageDao.insertOrUpdateMessage(row);
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
  }

  Future<void> upsertMessages(Iterable<ChatMessage> messages) async {
    final rows = messages.map(_messageToRow).toList();
    if (rows.isEmpty) return;

    log.debug('[DB] upsertMessages count=${rows.length}');
    for (final conversationId
        in rows.map((row) => row.conversationId).toSet()) {
      await _ensureConversationExists(conversationId);
    }
    await _ensureMessageSendersExist(rows);
    await db.messageDao.insertOrUpdateMessages(rows);
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
      log.debug(
        '[DB] _ensureMessageSendersExist: insert ${missing.length} stub users, ids=${missing.map((u) => u.userId.value).toList()}',
      );
      await db.userDao.insertOrUpdateUsers(missing);
    }
  }

  Future<void> upsertUser(UserInfo user) {
    log.debug('[DB] upsertUser userId=${user.userId} name=${user.nickName}');
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
  }

  Future<void> markConversationAsRead(String conversationId, {int? seq}) {
    log.debug('[DB] markConversationAsRead convId=$conversationId seq=$seq');
    return db.conversationDao.markAsRead(conversationId, lastReadSeq: seq);
  }

  Future<List<ChatMessage>> pendingOutgoingMessages() async {
    final rows = await db.messageDao.getPendingOutgoingMessages();
    log.debug('[DB] pendingOutgoingMessages → ${rows.length} pending');
    return rows.map(_messageFromRow).toList();
  }

  Future<ChatMessage?> getMessageByClientMsgId(String clientMsgId) async {
    final row = await db.messageDao.getMessageByClientMsgId(clientMsgId);
    return row == null ? null : _messageFromRow(row);
  }

  Future<ChatMessage?> getMessageById(String messageId) async {
    final row = await db.messageDao.getMessageById(messageId);
    return row == null ? null : _messageFromRow(row);
  }

  Future<void> updateDeliveryStatus(
    String messageId,
    DeliveryStatus status, {
    String? serverMessageId,
    int? seq,
    DateTime? sentAt,
  }) {
    log.debug(
      '[DB] updateDeliveryStatus id=$messageId → $status serverMsgId=$serverMessageId seq=$seq',
    );
    return db.messageDao.updateDeliveryStatus(
      messageId,
      status.toJson(),
      serverMessageId: serverMessageId,
      seq: seq,
      sentAt: sentAt,
    );
  }

  Future<void> updateConversationForIncomingMessage(
    ChatMessage message, {
    required bool incrementUnread,
  }) async {
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
  }

  Future<void> markConversationDeleted(String conversationId) {
    return db.conversationDao.markDeleted(conversationId);
  }

  Future<void> deleteConversationCache(String conversationId) async {
    log.debug('[DB] deleteConversationCache convId=$conversationId');
    await db.transaction(() async {
      await (db.delete(
        db.messages,
      )..where((tbl) => tbl.conversationId.equals(conversationId))).go();
      await (db.delete(
        db.conversations,
      )..where((tbl) => tbl.id.equals(conversationId))).go();
      await (db.delete(db.syncStates)..where(
            (tbl) =>
                tbl.scope.equals('messages') &
                tbl.scopeId.equals(conversationId),
          ))
          .go();
    });
  }

  Future<void> updateConversationStatus(String conversationId, int status) {
    return db.conversationDao.updateStatus(conversationId, status);
  }

  Future<void> deleteMessage(String messageId) {
    return db.messageDao.deleteMessage(messageId);
  }

  Future<void> deleteMessagesForConversation(String conversationId) {
    return db.messageDao.deleteMessagesForConversation(conversationId);
  }

  Future<void> updateSyncState({
    required String scope,
    String scopeId = 'global',
    DateTime? lastSyncedAt,
    int? lastSeq,
  }) {
    return db.syncStateDao.upsertState(
      scope: scope,
      scopeId: scopeId,
      lastSyncedAt: lastSyncedAt,
      lastSeq: lastSeq,
    );
  }

  Future<void> logSyncFailure({
    required String scope,
    String? scopeId,
    required String action,
    required Object error,
    int retryCount = 0,
  }) {
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
    log.debug(
      '[DB] _ensureConversationExists: create stub convId=$conversationId',
    );
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
    return ChatMessage(
      messageId: row.id,
      clientMsgId: row.clientMsgId,
      roomId: row.conversationId,
      senderId: row.senderId,
      messageType: MessageType.fromCode(row.messageType),
      content: row.content,
      payload: payloadMap == null ? null : MessagePayload.fromJson(payloadMap),
      properties:
          propertiesMap?.map(
            (key, value) => MapEntry(key, value?.toString() ?? ''),
          ) ??
          const {},
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
    log.debug('[DB] getContacts → ${rows.length} rows');
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
    final valid = contacts.where((c) => c.contactId != null).toList();
    if (valid.isEmpty) return;
    log.debug('[DB] upsertContacts count=${valid.length}');
    await db.contactDao.insertOrUpdateContacts(valid.map(_contactToCompanion));
  }

  /// 插入或更新单个联系人
  Future<void> upsertContact(ChatContactVO contact) async {
    if (contact.contactId == null) return;
    log.debug('[DB] upsertContact contactId=${contact.contactId}');
    await db.contactDao.insertOrUpdateContact(_contactToCompanion(contact));
  }

  /// 删除联系人（解除好友时调用）
  Future<void> deleteContact(int contactId) async {
    log.debug('[DB] deleteContact contactId=$contactId');
    await db.contactDao.deleteContact(contactId);
  }

  /// 更新联系人在线状态（由 WebSocket 触发，只更新 DB 字段，不影响完整联系人信息）
  Future<void> updateContactOnlineStatus(int contactId, bool isOnline) {
    return db.contactDao.updateOnlineStatus(contactId, isOnline);
  }

  /// 获取最近联系人更新时间（用于增量同步）
  Future<DateTime?> latestContactUpdatedAt() {
    return db.contactDao.getLatestUpdatedAt();
  }

  // ── 私有转换 ──────────────────────────────────────────────────────────────

  Future<void> clearSessionCache() async {
    log.info('[DB] clearSessionCache: remove chat/contact local data');
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
