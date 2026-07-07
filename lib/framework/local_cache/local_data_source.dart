import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/ChatMessage.dart';
import '../domain/ChatRoomVO.dart';
import '../domain/UserInfo.dart';
import '../protocol/message/MessageEunm.dart';
import '../protocol/message/MessagePayload.dart';
import 'database.dart';

class LocalDataSource {
  LocalDataSource(this.db);

  final AppDatabase db;

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
  }) async {
    final rows = await db.messageDao.getMessagesForConversation(
      convId,
      limit: limit,
      offset: offset,
    );
    return rows.reversed.map(_messageFromRow).toList();
  }

  Stream<List<ChatMessage>> watchMessagesForConversation(
    String convId, {
    int limit = 50,
    int offset = 0,
  }) {
    return db.messageDao
        .watchMessagesForConversation(convId, limit: limit, offset: offset)
        .map((rows) => rows.map(_messageFromRow).toList());
  }

  Future<DateTime?> latestConversationUpdatedAt() {
    return db.conversationDao.getLatestUpdatedAt();
  }

  Future<int> maxMessageSeq(String convId) => db.messageDao.getMaxSeq(convId);

  Future<DateTime?> latestMessageSentAt(String convId) {
    return db.messageDao.getLatestSentAt(convId);
  }

  Future<void> upsertConversation(ChatRoomVO room) {
    return db.conversationDao.insertOrUpdateConversation(
      _conversationToCompanion(room),
    );
  }

  Future<void> upsertConversations(Iterable<ChatRoomVO> rooms) {
    return db.conversationDao.insertOrUpdateConversations(
      rooms.map(_conversationToCompanion),
    );
  }

  Future<void> upsertMessage(ChatMessage message) async {
    final row = _messageToRow(message);
    await _ensureConversationExists(row.conversationId);
    await db.messageDao.insertOrUpdateMessage(row);
    final roomId = message.roomId;
    if (roomId != null && roomId.isNotEmpty) {
      await db.conversationDao.updateLastMessage(
        conversationId: roomId,
        messageId: message.messageId ?? message.clientMsgId ?? '',
        preview: message.content,
        seq: message.seq,
        sentAt: _dateTimeFromMillis(message.timestamp),
      );
    }
  }

  Future<void> upsertMessages(Iterable<ChatMessage> messages) async {
    final rows = messages.map(_messageToRow).toList();
    for (final conversationId
        in rows.map((row) => row.conversationId).toSet()) {
      await _ensureConversationExists(conversationId);
    }
    await db.messageDao.insertOrUpdateMessages(rows);
  }

  Future<void> upsertUser(UserInfo user) {
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
    return db.conversationDao.markAsRead(conversationId, lastReadSeq: seq);
  }

  Future<List<ChatMessage>> pendingOutgoingMessages() async {
    final rows = await db.messageDao.getPendingOutgoingMessages();
    return rows.map(_messageFromRow).toList();
  }

  Future<void> updateDeliveryStatus(
    String messageId,
    DeliveryStatus status, {
    String? serverMessageId,
    int? seq,
    DateTime? sentAt,
  }) {
    return db.messageDao.updateDeliveryStatus(
      messageId,
      status.toJson(),
      serverMessageId: serverMessageId,
      seq: seq,
      sentAt: sentAt,
    );
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
}
