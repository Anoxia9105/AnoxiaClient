/// 本地数据库层
///
/// 基于 Drift 的 SQLite 数据库，管理用户、会话、消息、联系人等缓存表，
/// 包含数据库迁移策略和各个 DAO 访问器。
import 'package:drift/drift.dart';

// 用 dart.library.io 判定平台而非 dart.library.html：
// dart.library.html 仅在 JS 版 Web 为 true，WASM 版 Web 为 false，
// 会导致 --wasm 构建回退到 database_native.dart（依赖 dart:ffi）而编译失败。
// dart.library.io 在原生为 true、两种 Web 均为 false，故 Web(JS/WASM) 都走 database_web.dart。
import 'database_web.dart' if (dart.library.io) 'database_native.dart';
import 'tables.dart';

part 'database.g.dart';

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
/// 应用数据库
///
/// 基于 Drift 框架的 SQLite 数据库，管理所有本地缓存表。
/// 支持数据库迁移、会话缓存清理和索引优化。
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  @override
  int get schemaVersion => 3;

  /// 清除会话缓存
  ///
  /// 在事务中清空所有缓存表，用于登出或切换账号时重置本地数据。
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
/// 用户数据访问对象
///
/// 提供用户缓存的增删改查与流式监听。
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  /// 根据用户 ID 获取单个用户
  Future<CachedUser?> getUser(int userId) {
    return (select(
      cachedUsers,
    )..where((tbl) => tbl.userId.equals(userId))).getSingleOrNull();
  }

  /// 根据用户 ID 列表批量获取用户
  Future<List<CachedUser>> getUsersByIds(Iterable<int> userIds) {
    final ids = userIds.toSet().toList();
    if (ids.isEmpty) return Future.value(const []);
    return (select(cachedUsers)..where((tbl) => tbl.userId.isIn(ids))).get();
  }

  /// 流式监听单个用户的变化
  Stream<CachedUser?> watchUser(int userId) {
    return (select(
      cachedUsers,
    )..where((tbl) => tbl.userId.equals(userId))).watchSingleOrNull();
  }

  /// 插入或更新单个用户
  Future<void> insertOrUpdateUser(CachedUsersCompanion user) {
    return into(cachedUsers).insertOnConflictUpdate(user);
  }

  /// 批量插入或更新用户
  Future<void> insertOrUpdateUsers(Iterable<CachedUsersCompanion> users) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(cachedUsers, users.toList());
    });
  }
}

@DriftAccessor(tables: [Conversations])
/// 会话数据访问对象
///
/// 提供会话缓存的增删改查、流式监听、已读标记和最后消息更新。
class ConversationDao extends DatabaseAccessor<AppDatabase>
    with _$ConversationDaoMixin {
  ConversationDao(super.db);

  /// 获取所有未删除的会话列表
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

  /// 流式监听会话列表变化
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

  /// 根据会话 ID 获取单个会话
  Future<CachedConversation?> getConversation(String id) {
    return (select(
      conversations,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// 获取会话表中最新的更新时间
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

  /// 插入或更新单个会话
  Future<void> insertOrUpdateConversation(ConversationsCompanion conversation) {
    return into(conversations).insertOnConflictUpdate(conversation);
  }

  /// 批量插入或更新会话
  Future<void> insertOrUpdateConversations(
    Iterable<ConversationsCompanion> items,
  ) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(conversations, items.toList());
    });
  }

  /// 标记会话为已读
  ///
  /// [lastReadSeq] 可选，最后已读的消息序号。
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

  /// 标记会话为已删除
  Future<void> markDeleted(String conversationId) async {
    await (update(
      conversations,
    )..where((tbl) => tbl.id.equals(conversationId))).write(
      ConversationsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
        cachedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 更新会话状态
  Future<void> updateStatus(String conversationId, int status) async {
    await (update(
      conversations,
    )..where((tbl) => tbl.id.equals(conversationId))).write(
      ConversationsCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
        cachedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 更新收到新消息时的会话信息
  ///
  /// [incrementUnread] 是否递增未读计数；[clearUnread] 是否清空未读计数。
  Future<void> updateIncomingMessage({
    required String conversationId,
    required String messageId,
    required String preview,
    int? messageType,
    int? seq,
    DateTime? sentAt,
    required bool incrementUnread,
    bool clearUnread = false,
  }) async {
    final existing = await getConversation(conversationId);
    if (existing == null) return;

    await (update(
      conversations,
    )..where((tbl) => tbl.id.equals(conversationId))).write(
      ConversationsCompanion(
        unreadCount: incrementUnread
            ? Value(existing.unreadCount + 1)
            : clearUnread
            ? const Value(0)
            : const Value.absent(),
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

  /// 更新最后一条消息
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
/// 消息数据访问对象
///
/// 提供消息缓存的增删改查、流式监听、发送状态管理和临时 ID 替换。
class MessageDao extends DatabaseAccessor<AppDatabase> with _$MessageDaoMixin {
  MessageDao(super.db);

  /// 获取指定会话的消息列表
  ///
  /// [beforeSeq] 可选，获取该序号之前的消息用于分页加载。
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
        (tbl) => OrderingTerm(expression: tbl.sentAt, mode: OrderingMode.desc),
        (tbl) => OrderingTerm(expression: tbl.seq, mode: OrderingMode.desc),
      ]);
    if (limit != null) {
      query.limit(limit, offset: offset);
    }
    return query.watch();
  }

  /// 获取指定会话的最大消息序号
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

  /// 获取指定会话中所有消息的序号列表
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

  /// 获取指定会话中最新的消息发送时间
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

  /// 获取所有待发送或发送失败的消息
  Future<List<CachedMessage>> getPendingOutgoingMessages() {
    return (select(messages)
          ..where((tbl) => tbl.deliveryStatus.isIn(['SENDING', 'FAILED']))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.localCreatedAt)]))
        .get();
  }

  /// 插入或更新单条消息
  ///
  /// 若存在相同 client_msg_id 但不同 id 的旧记录（发送方 ACK/回声做
  /// 临时 ID → 服务端 ID 换绑），采用「原地 UPDATE 主键」而非「先删后插」：
  /// 单行 UPDATE 语句不会让 Drift 的 watch 在 delete/insert 之间发出一份
  /// 缺少该消息的快照，从而根治 Web(Worker) 上的消息闪退。
  Future<void> insertOrUpdateMessage(CachedMessage message) async {
    await transaction(() async {
      if (message.clientMsgId != null && message.clientMsgId != message.id) {
        // 主键换绑：把 clientMsgId 对应的旧行原地更新为服务端 id，避免空窗。
        final updated = await (update(messages)
              ..where((tbl) => tbl.id.equals(message.clientMsgId!)))
            .write(message.toCompanion(true));
        if (updated > 0) return;
        // 旧行不存在（异常竞态）时退化为普通 upsert。
      }
      await into(messages).insertOnConflictUpdate(message);
    });
  }

  /// 批量插入或更新消息
  Future<void> insertOrUpdateMessages(Iterable<CachedMessage> items) async {
    final list = items.toList();
    if (list.isEmpty) return;

    final clientMsgIds = <String>{
      for (final item in list)
        if (item.clientMsgId != null) item.clientMsgId!,
    };
    final ids = <String>{for (final item in list) item.id};

    await transaction(() async {
      // 清理 client_msg_id 相同但 id 不同的旧记录。
      //
      // 必须一次性批量删除：Web 上 drift 运行在 wasm worker 里，每条 SQL 都是一次
      // postMessage 往返；逐条 DELETE 会让 100 条历史消息落库耗时数秒，
      // 并且整个事务期间会阻塞 DB 队列（watch 流、后续查询全部排队）。
      if (clientMsgIds.isNotEmpty) {
        await (delete(messages)..where(
              (tbl) => tbl.clientMsgId.isIn(clientMsgIds) & tbl.id.isNotIn(ids),
            ))
            .go();
      }
      await batch((b) => b.insertAllOnConflictUpdate(messages, list));
    });
  }

  /// 用服务端 ID 替换临时消息 ID
  ///
  /// [temporaryId] 客户端生成的临时 ID；[serverId] 服务端返回的真实 ID。
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

  /// 更新消息发送状态
  ///
  /// [serverMessageId] 若与本地 ID 不同，则先替换临时 ID。
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

  /// 根据客户端消息 ID 获取消息
  Future<CachedMessage?> getMessageByClientMsgId(String clientMsgId) {
    return (select(
      messages,
    )..where((tbl) => tbl.clientMsgId.equals(clientMsgId))).getSingleOrNull();
  }

  /// 根据消息 ID 获取消息
  Future<CachedMessage?> getMessageById(String messageId) {
    return (select(
      messages,
    )..where((tbl) => tbl.id.equals(messageId))).getSingleOrNull();
  }

  /// 软删除单条消息
  Future<void> deleteMessage(String messageId) async {
    await (update(messages)..where((tbl) => tbl.id.equals(messageId))).write(
      MessagesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 软删除指定会话的所有消息
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
/// 同步状态数据访问对象
///
/// 管理增量同步的范围和进度状态。
class SyncStateDao extends DatabaseAccessor<AppDatabase>
    with _$SyncStateDaoMixin {
  SyncStateDao(super.db);

  /// 获取指定范围的同步状态
  Future<SyncState?> getState(String scope, [String scopeId = 'global']) {
    return (select(syncStates)..where(
          (tbl) => tbl.scope.equals(scope) & tbl.scopeId.equals(scopeId),
        ))
        .getSingleOrNull();
  }

  /// 插入或更新同步状态
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
/// 同步日志数据访问对象
///
/// 管理同步失败日志的记录和重试策略。
class SyncLogDao extends DatabaseAccessor<AppDatabase> with _$SyncLogDaoMixin {
  SyncLogDao(super.db);

  /// 获取可重试的同步日志
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

  /// 插入一条同步日志
  Future<int> insertLog(SyncLogsCompanion log) {
    return into(syncLogs).insert(log);
  }
}

@DriftAccessor(tables: [CachedContacts])
/// 联系人数据访问对象
///
/// 提供联系人缓存的增删改查、流式监听和在线状态更新。
class ContactDao extends DatabaseAccessor<AppDatabase> with _$ContactDaoMixin {
  ContactDao(super.db);

  /// 获取所有联系人
  Future<List<CachedContact>> getAllContacts() {
    return (select(cachedContacts)..orderBy([
          (tbl) =>
              OrderingTerm(expression: tbl.cachedAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  /// 流式监听所有联系人变化
  Stream<List<CachedContact>> watchAllContacts() {
    return (select(cachedContacts)..orderBy([
          (tbl) =>
              OrderingTerm(expression: tbl.cachedAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  /// 根据联系人 ID 获取单个联系人
  Future<CachedContact?> getContact(int contactId) {
    return (select(
      cachedContacts,
    )..where((tbl) => tbl.contactId.equals(contactId))).getSingleOrNull();
  }

  Future<void> insertOrUpdateContact(CachedContactsCompanion contact) {
    return into(cachedContacts).insertOnConflictUpdate(contact);
  }

  /// 批量插入或更新联系人
  Future<void> insertOrUpdateContacts(
    Iterable<CachedContactsCompanion> contacts,
  ) async {
    await batch(
      (b) => b.insertAllOnConflictUpdate(cachedContacts, contacts.toList()),
    );
  }

  /// 删除单个联系人
  Future<void> deleteContact(int contactId) {
    return (delete(
      cachedContacts,
    )..where((tbl) => tbl.contactId.equals(contactId))).go();
  }

  /// 更新联系人在线状态
  Future<void> updateOnlineStatus(int contactId, bool isOnline) {
    return (update(cachedContacts)
          ..where((tbl) => tbl.contactId.equals(contactId)))
        .write(CachedContactsCompanion(onlineStatus: Value(isOnline)));
  }

  /// 获取联系人表中最新的更新时间
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
