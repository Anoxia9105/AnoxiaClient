import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'anoxia_im.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(
  tables: [
    CachedUsers,
    Conversations,
    Messages,
    SyncStates,
    SyncLogs,
    CachedContacts,
  ],
  daos: [
    UserDao,
    ConversationDao,
    MessageDao,
    SyncStateDao,
    SyncLogDao,
    ContactDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  Future<void> clearSessionCache() async {
    await transaction(() async {
      await delete(messages).go();
      await delete(conversations).go();
      await delete(cachedContacts).go();
      await delete(syncStates).go();
      await delete(syncLogs).go();
      await delete(cachedUsers).go();
    });
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // v1 → v2: 新增联系人缓存表
      if (from < 2) {
        await m.createTable(cachedContacts);
      }
      // v2 -> v3: Persist last message type so cached conversations can
      // restore system-message semantics after app restart.
      if (from < 3) {
        await m.addColumn(conversations, conversations.lastMessageType);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_conversations_updated_at '
        'ON conversations(updated_at DESC)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_conversations_peer_id '
        'ON conversations(peer_id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_messages_conversation_seq '
        'ON messages(conversation_id, seq DESC)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_messages_conversation_sent_at '
        'ON messages(conversation_id, sent_at DESC)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_messages_delivery_status '
        'ON messages(delivery_status)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sync_logs_retry '
        'ON sync_logs(status, next_retry_at)',
      );
    },
  );
}

@DriftAccessor(tables: [CachedUsers])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  Future<CachedUser?> getUser(int userId) {
    return (select(
      cachedUsers,
    )..where((tbl) => tbl.userId.equals(userId))).getSingleOrNull();
  }

  Future<List<CachedUser>> getUsersByIds(Iterable<int> userIds) {
    final ids = userIds.toSet().toList();
    if (ids.isEmpty) return Future.value(const []);
    return (select(cachedUsers)..where((tbl) => tbl.userId.isIn(ids))).get();
  }

  Stream<CachedUser?> watchUser(int userId) {
    return (select(
      cachedUsers,
    )..where((tbl) => tbl.userId.equals(userId))).watchSingleOrNull();
  }

  Future<void> insertOrUpdateUser(CachedUsersCompanion user) {
    return into(cachedUsers).insertOnConflictUpdate(user);
  }

  Future<void> insertOrUpdateUsers(Iterable<CachedUsersCompanion> users) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(cachedUsers, users.toList());
    });
  }
}

@DriftAccessor(tables: [Conversations])
class ConversationDao extends DatabaseAccessor<AppDatabase>
    with _$ConversationDaoMixin {
  ConversationDao(super.db);

  Future<List<CachedConversation>> getConversations() {
    return (select(conversations)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.updatedAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Stream<List<CachedConversation>> watchConversations() {
    return (select(conversations)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.updatedAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .watch();
  }

  Future<CachedConversation?> getConversation(String id) {
    return (select(
      conversations,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<DateTime?> getLatestUpdatedAt() async {
    final row =
        await (select(conversations)
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.updatedAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row?.updatedAt;
  }

  Future<void> insertOrUpdateConversation(ConversationsCompanion conversation) {
    return into(conversations).insertOnConflictUpdate(conversation);
  }

  Future<void> insertOrUpdateConversations(
    Iterable<ConversationsCompanion> items,
  ) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(conversations, items.toList());
    });
  }

  Future<void> markAsRead(String conversationId, {int? lastReadSeq}) async {
    await (update(
      conversations,
    )..where((tbl) => tbl.id.equals(conversationId))).write(
      ConversationsCompanion(
        unreadCount: const Value(0),
        lastReadSeq: lastReadSeq == null
            ? const Value.absent()
            : Value(lastReadSeq),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markDeleted(String conversationId) async {
    await (update(conversations)..where((tbl) => tbl.id.equals(conversationId)))
        .write(
          ConversationsCompanion(
            isDeleted: const Value(true),
            updatedAt: Value(DateTime.now()),
            cachedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> updateStatus(String conversationId, int status) async {
    await (update(conversations)..where((tbl) => tbl.id.equals(conversationId)))
        .write(
          ConversationsCompanion(
            status: Value(status),
            updatedAt: Value(DateTime.now()),
            cachedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> updateIncomingMessage({
    required String conversationId,
    required String messageId,
    required String preview,
    int? messageType,
    int? seq,
    DateTime? sentAt,
    required bool incrementUnread,
  }) async {
    final existing = await getConversation(conversationId);
    if (existing == null) return;

    await (update(conversations)..where((tbl) => tbl.id.equals(conversationId)))
        .write(
          ConversationsCompanion(
            unreadCount: incrementUnread
                ? Value(existing.unreadCount + 1)
                : const Value(0),
            lastMessageId: Value(messageId),
            lastMessagePreview: Value(preview),
            lastMessageType: Value(messageType),
            lastMessageSeq: Value(seq),
            lastMessageAt: Value(sentAt),
            updatedAt: Value(sentAt ?? DateTime.now()),
            cachedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> updateLastMessage({
    required String conversationId,
    required String messageId,
    required String preview,
    int? messageType,
    int? seq,
    DateTime? sentAt,
  }) async {
    await (update(
      conversations,
    )..where((tbl) => tbl.id.equals(conversationId))).write(
      ConversationsCompanion(
        lastMessageId: Value(messageId),
        lastMessagePreview: Value(preview),
        lastMessageType: Value(messageType),
        lastMessageSeq: Value(seq),
        lastMessageAt: Value(sentAt),
        updatedAt: Value(sentAt ?? DateTime.now()),
        cachedAt: Value(DateTime.now()),
      ),
    );
  }
}

@DriftAccessor(tables: [Messages])
class MessageDao extends DatabaseAccessor<AppDatabase> with _$MessageDaoMixin {
  MessageDao(super.db);

  Future<List<CachedMessage>> getMessagesForConversation(
    String conversationId, {
    int limit = 50,
    int offset = 0,
    int? beforeSeq,
  }) {
    return (select(messages)
          ..where(
            (tbl) =>
                tbl.conversationId.equals(conversationId) &
                tbl.isDeleted.equals(false) &
                (beforeSeq == null
                    ? const Constant(true)
                    : tbl.seq.isSmallerThanValue(beforeSeq)),
          )
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.seq, mode: OrderingMode.desc),
            (tbl) =>
                OrderingTerm(expression: tbl.sentAt, mode: OrderingMode.desc),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  Stream<List<CachedMessage>> watchMessagesForConversation(
    String conversationId, {
    int? limit = 50,
    int offset = 0,
  }) {
    final query = select(messages)
      ..where(
        (tbl) =>
            tbl.conversationId.equals(conversationId) &
            tbl.isDeleted.equals(false),
      )
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.seq),
        (tbl) => OrderingTerm(expression: tbl.sentAt),
      ]);
    if (limit != null) {
      query.limit(limit, offset: offset);
    }
    return query.watch();
  }

  Future<int> getMaxSeq(String conversationId) async {
    final row =
        await (select(messages)
              ..where((tbl) => tbl.conversationId.equals(conversationId))
              ..orderBy([
                (tbl) =>
                    OrderingTerm(expression: tbl.seq, mode: OrderingMode.desc),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row?.seq ?? 0;
  }

  Future<List<int>> getMessageSeqsForConversation(String conversationId) async {
    final rows =
        await (select(messages)
              ..where(
                (tbl) =>
                    tbl.conversationId.equals(conversationId) &
                    tbl.isDeleted.equals(false) &
                    tbl.seq.isBiggerThanValue(0),
              )
              ..orderBy([(tbl) => OrderingTerm(expression: tbl.seq)]))
            .get();
    return rows.map((row) => row.seq).toList();
  }

  Future<DateTime?> getLatestSentAt(String conversationId) async {
    final row =
        await (select(messages)
              ..where((tbl) => tbl.conversationId.equals(conversationId))
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.sentAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row?.sentAt;
  }

  Future<List<CachedMessage>> getPendingOutgoingMessages() {
    return (select(messages)
          ..where((tbl) => tbl.deliveryStatus.isIn(['SENDING', 'FAILED']))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.localCreatedAt)]))
        .get();
  }

  Future<void> insertOrUpdateMessage(CachedMessage message) async {
    // 若存在相同 client_msg_id 但不同 id 的旧记录（临时 ID → 服务端 ID），先删除
    if (message.clientMsgId != null) {
      await (delete(messages)..where(
            (tbl) =>
                tbl.clientMsgId.equals(message.clientMsgId!) &
                tbl.id.isNotValue(message.id),
          ))
          .go();
    }
    await into(messages).insertOnConflictUpdate(message);
  }

  Future<void> insertOrUpdateMessages(Iterable<CachedMessage> items) async {
    final list = items.toList();
    await transaction(() async {
      // 批量清理 client_msg_id 相同但 id 不同的旧记录
      for (final item in list) {
        if (item.clientMsgId != null) {
          await (delete(messages)..where(
                (tbl) =>
                    tbl.clientMsgId.equals(item.clientMsgId!) &
                    tbl.id.isNotValue(item.id),
              ))
              .go();
        }
      }
      await batch((b) => b.insertAllOnConflictUpdate(messages, list));
    });
  }

  Future<void> replaceTemporaryMessageId({
    required String temporaryId,
    required String serverId,
    int? serverSeq,
    DateTime? sentAt,
  }) async {
    await transaction(() async {
      final temp = await (select(
        messages,
      )..where((tbl) => tbl.id.equals(temporaryId))).getSingleOrNull();
      if (temp == null) return;

      await (delete(messages)..where((tbl) => tbl.id.equals(temporaryId))).go();
      await into(messages).insertOnConflictUpdate(
        temp.copyWith(
          id: serverId,
          deliveryStatus: 'SENT',
          seq: serverSeq ?? temp.seq,
          sentAt: Value(sentAt ?? temp.sentAt),
          updatedAt: DateTime.now(),
        ),
      );
    });
  }

  Future<void> updateDeliveryStatus(
    String messageId,
    String status, {
    String? serverMessageId,
    int? seq,
    DateTime? sentAt,
  }) async {
    final target = serverMessageId ?? messageId;
    if (serverMessageId != null && serverMessageId != messageId) {
      await replaceTemporaryMessageId(
        temporaryId: messageId,
        serverId: serverMessageId,
        serverSeq: seq,
        sentAt: sentAt,
      );
      return;
    }

    await (update(messages)..where((tbl) => tbl.id.equals(target))).write(
      MessagesCompanion(
        deliveryStatus: Value(status),
        seq: seq == null ? const Value.absent() : Value(seq),
        sentAt: sentAt == null ? const Value.absent() : Value(sentAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<CachedMessage?> getMessageByClientMsgId(String clientMsgId) {
    return (select(
      messages,
    )..where((tbl) => tbl.clientMsgId.equals(clientMsgId))).getSingleOrNull();
  }

  Future<CachedMessage?> getMessageById(String messageId) {
    return (select(
      messages,
    )..where((tbl) => tbl.id.equals(messageId))).getSingleOrNull();
  }

  Future<void> deleteMessage(String messageId) async {
    await (update(messages)..where((tbl) => tbl.id.equals(messageId))).write(
      MessagesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteMessagesForConversation(String conversationId) async {
    await (update(
      messages,
    )..where((tbl) => tbl.conversationId.equals(conversationId))).write(
      MessagesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

@DriftAccessor(tables: [SyncStates])
class SyncStateDao extends DatabaseAccessor<AppDatabase>
    with _$SyncStateDaoMixin {
  SyncStateDao(super.db);

  Future<SyncState?> getState(String scope, [String scopeId = 'global']) {
    return (select(syncStates)..where(
          (tbl) => tbl.scope.equals(scope) & tbl.scopeId.equals(scopeId),
        ))
        .getSingleOrNull();
  }

  Future<void> upsertState({
    required String scope,
    String scopeId = 'global',
    DateTime? lastSyncedAt,
    int? lastSeq,
  }) {
    final now = DateTime.now();
    return into(syncStates).insertOnConflictUpdate(
      SyncStatesCompanion(
        scope: Value(scope),
        scopeId: Value(scopeId),
        lastSyncedAt: Value(lastSyncedAt),
        lastSeq: lastSeq == null ? const Value.absent() : Value(lastSeq),
        updatedAt: Value(now),
      ),
    );
  }
}

@DriftAccessor(tables: [SyncLogs])
class SyncLogDao extends DatabaseAccessor<AppDatabase> with _$SyncLogDaoMixin {
  SyncLogDao(super.db);

  Future<List<SyncLogEntry>> getRetryableLogs(DateTime now) {
    return (select(syncLogs)
          ..where(
            (tbl) =>
                tbl.status.equals('FAILED') &
                (tbl.nextRetryAt.isSmallerOrEqualValue(now) |
                    tbl.nextRetryAt.isNull()),
          )
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)]))
        .get();
  }

  Future<int> insertLog(SyncLogsCompanion log) {
    return into(syncLogs).insert(log);
  }
}

@DriftAccessor(tables: [CachedContacts])
class ContactDao extends DatabaseAccessor<AppDatabase> with _$ContactDaoMixin {
  ContactDao(super.db);

  Future<List<CachedContact>> getAllContacts() {
    return (select(cachedContacts)..orderBy([
          (tbl) =>
              OrderingTerm(expression: tbl.cachedAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  Stream<List<CachedContact>> watchAllContacts() {
    return (select(cachedContacts)..orderBy([
          (tbl) =>
              OrderingTerm(expression: tbl.cachedAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  Future<CachedContact?> getContact(int contactId) {
    return (select(
      cachedContacts,
    )..where((tbl) => tbl.contactId.equals(contactId))).getSingleOrNull();
  }

  Future<void> insertOrUpdateContact(CachedContactsCompanion contact) {
    return into(cachedContacts).insertOnConflictUpdate(contact);
  }

  Future<void> insertOrUpdateContacts(
    Iterable<CachedContactsCompanion> contacts,
  ) async {
    await batch(
      (b) => b.insertAllOnConflictUpdate(cachedContacts, contacts.toList()),
    );
  }

  Future<void> deleteContact(int contactId) {
    return (delete(
      cachedContacts,
    )..where((tbl) => tbl.contactId.equals(contactId))).go();
  }

  Future<void> updateOnlineStatus(int contactId, bool isOnline) {
    return (update(cachedContacts)
          ..where((tbl) => tbl.contactId.equals(contactId)))
        .write(CachedContactsCompanion(onlineStatus: Value(isOnline)));
  }

  Future<DateTime?> getLatestUpdatedAt() async {
    final row =
        await (select(cachedContacts)
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.updatedAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row?.updatedAt;
  }
}
