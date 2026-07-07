import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

import '../domain/ChatMessage.dart';
import '../domain/ChatRoomVO.dart';
import '../logs/talker.dart';
import '../protocol/message/MessageEunm.dart';
import 'local_data_source.dart';
import 'remote_data_source.dart';

class SyncRepository {
  SyncRepository({
    required LocalDataSource local,
    required RemoteDataSource remote,
    Connectivity? connectivity,
  }) : _local = local,
       _remote = remote,
       _connectivity = connectivity ?? Connectivity();

  final LocalDataSource _local;
  final RemoteDataSource _remote;
  final Connectivity _connectivity;

  /// 正在进行的 syncConversations Future（去重用）
  Future<void>? _syncConversationsInflight;

  /// 正在进行的 syncMessages Future，按 convId 去重
  final Map<String, Future<void>> _syncMessagesInflight = {};

  Stream<List<ChatRoomVO>> watchConversations() {
    return _local.watchConversations();
  }

  Stream<List<ChatMessage>> watchMessages(
    String convId, {
    int limit = 50,
    int offset = 0,
  }) {
    return _local.watchMessagesForConversation(
      convId,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<ChatRoomVO>> getConversations({bool sync = true}) async {
    final localRooms = await _local.getConversations();
    if (sync) unawaited(syncConversations());
    return localRooms;
  }

  Future<List<ChatMessage>> getMessagesForConversation(
    String convId, {
    int limit = 50,
    int offset = 0,
    bool sync = true,
  }) async {
    final localMessages = await _local.getMessagesForConversation(
      convId,
      limit: limit,
      offset: offset,
    );
    if (sync) unawaited(syncMessages(convId));
    return localMessages;
  }

  Future<void> syncConversations() {
    // 已有正在进行的同步，直接复用，避免并发重复请求
    return _syncConversationsInflight ??=
        _doSyncConversations().whenComplete(
          () => _syncConversationsInflight = null,
        );
  }

  Future<void> _doSyncConversations() async {
    if (!await _hasNetwork()) return;

    try {
      final since = await _local.latestConversationUpdatedAt();
      final remoteRooms = await _remote.fetchConversations(since: since);
      await _mergeConversations(remoteRooms);
      await _local.updateSyncState(
        scope: 'conversations',
        lastSyncedAt: DateTime.now(),
      );
    } catch (e, st) {
      log.error('syncConversations failed', e, st);
      await _local.logSyncFailure(
        scope: 'conversations',
        action: 'syncConversations',
        error: e,
      );
    }
  }

  Future<void> syncMessages(String convId, {DateTime? since}) {
    // 同一会话已在同步中，直接复用，避免并发重复请求
    return _syncMessagesInflight[convId] ??=
        _doSyncMessages(convId, since: since).whenComplete(
          () => _syncMessagesInflight.remove(convId),
        );
  }

  Future<void> _doSyncMessages(String convId, {DateTime? since}) async {
    if (!await _hasNetwork()) return;

    try {
      final lastSeq = await _local.maxMessageSeq(convId);
      final latestSentAt = since ?? await _local.latestMessageSentAt(convId);
      final remoteMessages = await _remote.fetchMessages(
        convId,
        since: latestSentAt,
        lastSeq: lastSeq,
      );
      await _local.upsertMessages(remoteMessages);
      final maxSeq = remoteMessages.fold<int>(
        lastSeq,
        (max, msg) => (msg.seq ?? 0) > max ? msg.seq! : max,
      );
      await _local.updateSyncState(
        scope: 'messages',
        scopeId: convId,
        lastSyncedAt: DateTime.now(),
        lastSeq: maxSeq,
      );
    } catch (e, st) {
      log.error('syncMessages failed: $convId', e, st);
      await _local.logSyncFailure(
        scope: 'messages',
        scopeId: convId,
        action: 'syncMessages',
        error: e,
      );
    }
  }

  Future<ChatMessage> sendMessage(ChatMessage message) async {
    final localMessage = _ensureLocalSendingMessage(message);
    await _local.upsertMessage(localMessage);

    if (!await _hasNetwork()) {
      return localMessage;
    }

    try {
      final result = await _remote.sendMessage(localMessage);
      if (result.message != null) {
        await _local.upsertMessage(
          result.message!.copyWith(deliveryStatus: DeliveryStatus.sent),
        );
      } else {
        await _local.updateDeliveryStatus(
          localMessage.messageId!,
          DeliveryStatus.sent,
          serverMessageId: result.messageId,
          seq: result.seq,
          sentAt: result.sentAt,
        );
      }
      return localMessage.copyWith(
        messageId: result.messageId,
        seq: result.seq,
        timestamp: result.sentAt?.millisecondsSinceEpoch,
        deliveryStatus: DeliveryStatus.sent,
      );
    } catch (e, st) {
      log.error('sendMessage failed', e, st);
      await _local.updateDeliveryStatus(
        localMessage.messageId!,
        DeliveryStatus.failed,
      );
      await _local.logSyncFailure(
        scope: 'messages',
        scopeId: localMessage.roomId,
        action: 'sendMessage',
        error: e,
      );
      return localMessage.copyWith(deliveryStatus: DeliveryStatus.failed);
    }
  }

  Future<void> retryPendingOutgoing() async {
    if (!await _hasNetwork()) return;

    final pending = await _local.pendingOutgoingMessages();
    for (final message in pending) {
      await sendMessage(
        message.copyWith(deliveryStatus: DeliveryStatus.sending),
      );
    }
  }

  Future<void> markAsRead(
    String conversationId, {
    String? messageId,
    int? seq,
  }) async {
    await _local.markConversationAsRead(conversationId, seq: seq);
    if (!await _hasNetwork()) return;

    try {
      await _remote.markAsRead(conversationId, seq: seq);
    } catch (e, st) {
      log.error('markAsRead failed', e, st);
      await _local.logSyncFailure(
        scope: 'conversations',
        scopeId: conversationId,
        action: 'markAsRead',
        error: e,
      );
    }
  }

  Future<void> cacheIncomingMessage(ChatMessage message) async {
    await _local.upsertMessage(
      message.copyWith(deliveryStatus: DeliveryStatus.sent),
    );
  }

  Future<void> cacheLocalMessage(ChatMessage message) {
    return _local.upsertMessage(message);
  }

  Future<void> onNetworkRecovered() async {
    await syncConversations();
    await retryPendingOutgoing();
  }

  Future<void> _mergeConversations(List<ChatRoomVO> remoteRooms) async {
    final localRooms = await _local.getConversations();
    final localById = {
      for (final room in localRooms)
        if (room.roomId != null) room.roomId!: room,
    };

    final merged = <ChatRoomVO>[];
    for (final remote in remoteRooms) {
      final id = remote.roomId;
      if (id == null) continue;
      final local = localById[id];
      if (local == null) {
        merged.add(remote);
        continue;
      }

      final localUpdated = _roomVersion(local);
      final remoteUpdated = _roomVersion(remote);
      if (remoteUpdated == null ||
          localUpdated == null ||
          remoteUpdated.isAfter(localUpdated) ||
          remoteUpdated.isAtSameMomentAs(localUpdated)) {
        merged.add(
          remote.copyWith(
            unreadCount: remote.unreadCount ?? local.unreadCount,
            lastReadSeq: remote.lastReadSeq ?? local.lastReadSeq,
          ),
        );
      } else {
        merged.add(local);
      }
    }
    await _local.upsertConversations(merged);
  }

  ChatMessage _ensureLocalSendingMessage(ChatMessage message) {
    final id = message.messageId ?? message.clientMsgId ?? const Uuid().v4();
    return ChatMessage(
      messageId: id,
      clientMsgId: message.clientMsgId ?? id,
      roomId: message.roomId,
      senderId: message.senderId,
      messageType: message.messageType,
      content: message.content,
      payload: message.payload,
      properties: message.properties,
      deliveryStatus: DeliveryStatus.sending,
      timestamp: message.timestamp ?? DateTime.now().millisecondsSinceEpoch,
      seq: message.seq ?? 0,
    );
  }

  DateTime? _roomVersion(ChatRoomVO room) {
    final lastTimestamp = room.lastMessage?.timestamp;
    if (lastTimestamp != null && lastTimestamp > 0) {
      return DateTime.fromMillisecondsSinceEpoch(lastTimestamp);
    }
    return room.createdAt;
  }

  Future<bool> _hasNetwork() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}
