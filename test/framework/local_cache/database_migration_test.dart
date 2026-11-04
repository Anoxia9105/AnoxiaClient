// drift 迁移回归测试。
//
// 策略（「先真实建库、再手工降级、最后跑迁移」）：
// 1. 用 AppDatabase 在文件库上写入 v5 真实 schema 与种子数据；
// 2. 用原生 sqlite3 手工把库降级到旧版本结构（v1：无 cached_contacts、
//    conversations 无 last_message_type；v3：无 input_drafts），
//    并把 user_version 重置；
// 3. 再次用 AppDatabase 打开同一文件，触发对应 onUpgrade 分支；
// 4. 断言旧数据完好、丢失结构补齐、user_version 推进到当前版本。
//
// P0-1（InputDrafts 表）已消费此模板；后续 schema 变更（P0-4 媒体查询这类
// 只读扩展除外）照抄「真实建库 → 降级 → 重开」写法并补分支断言。
import 'dart:io';

import 'package:anoxia/framework/local_cache/database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// drift 原生端 DateTime 以 unix 秒存储；种数据用同口径的固定时间。
final DateTime seedTime = DateTime.parse('2026-08-01 12:00:00');

/// 用 drift 真实 schema 建库并种入一条会话与一条消息。
Future<void> _seedFreshDatabase(String path) async {
  final db = AppDatabase(NativeDatabase(File(path)));
  await db.batch((batch) {
    batch.insert(
      db.cachedUsers,
      CachedUsersCompanion(
        userId: const Value(1),
        userName: const Value('demo'),
        nickName: const Value('演示用户'),
        email: const Value('demo@anoxia.cn'),
        phoneNumber: const Value(''),
        sex: const Value('0'),
        avatar: const Value(''),
        cachedAt: Value(seedTime),
      ),
    );
    batch.insert(
      db.conversations,
      ConversationsCompanion(
        id: const Value('room-seed'),
        name: const Value('种子会话'),
        type: const Value(0),
        status: const Value(0),
        peerId: const Value(1),
        unreadCount: const Value(3),
        lastReadSeq: const Value(0),
        updatedAt: Value(seedTime),
        cachedAt: Value(seedTime),
      ),
    );
    batch.insert(
      db.messages,
      MessagesCompanion(
        id: const Value('msg-seed'),
        conversationId: const Value('room-seed'),
        senderId: const Value(1),
        messageType: const Value(1),
        content: const Value('旧消息'),
        deliveryStatus: const Value('SENT'),
        seq: const Value(12),
        localCreatedAt: Value(seedTime),
        updatedAt: Value(seedTime),
      ),
    );
  });
  await db.close();
}

/// 手工把库降级到 v1 结构：删掉 v2 新增的联系人表、v3 新增的列，
/// 并把 user_version 重置回 1。
void _degradeToV1(String path) {
  final sqlite = sqlite3.open(path);
  sqlite.execute('DROP TABLE cached_contacts');
  sqlite.execute('ALTER TABLE conversations DROP COLUMN last_message_type');
  sqlite.execute('ALTER TABLE conversations DROP COLUMN hidden_at_seq');
  sqlite.execute('PRAGMA user_version = 1');
  sqlite.close();
}

/// 手工把库降级到 v3 结构：删掉 v4 新增的输入草稿表并重置 user_version。
void _degradeToV3(String path) {
  final sqlite = sqlite3.open(path);
  sqlite.execute('DROP TABLE input_drafts');
  sqlite.execute('ALTER TABLE conversations DROP COLUMN hidden_at_seq');
  sqlite.execute('PRAGMA user_version = 3');
  sqlite.close();
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('anoxia_migration_test');
  });

  tearDown(() async {
    // Windows 下文件句柄释放有延迟，删不掉时短暂重试。
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        tempDir.deleteSync(recursive: true);
        return;
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  });

  String dbPath(String name) => '${tempDir.path}/$name.db';

  test('新版 schemaVersion 为 5：改表必须同步迁移策略', () async {
    final db = AppDatabase(NativeDatabase.memory());
    expect(db.schemaVersion, 5);
    await db.close();
  });

  test('从零建库：beforeOpen 索引就位、外键开启与时间戳可写', () async {
    final db = AppDatabase(NativeDatabase(File(dbPath('fresh.db'))));
    final fkRow =
        (await db.customSelect('PRAGMA foreign_keys').get()).first.data;
    expect(fkRow['foreign_keys'], 1);

    final indexNames =
        (await db.customSelect("PRAGMA index_list('conversations')").get())
            .map((e) => e.data['name'] as String)
            .toSet();
    expect(indexNames, contains('idx_conversations_updated_at'));
    expect(indexNames, contains('idx_conversations_peer_id'));

    final messageIndexNames =
        (await db.customSelect("PRAGMA index_list('messages')").get())
            .map((e) => e.data['name'] as String)
            .toSet();
    expect(messageIndexNames, contains('idx_messages_conversation_seq'));
    expect(messageIndexNames, contains('idx_messages_delivery_status'));
    await db.close();
  });

  test('v1 → v5：旧会话/消息保留，联系人表、last_message_type、草稿表补齐', () async {
    final path = dbPath('v1.db');
    await _seedFreshDatabase(path);
    _degradeToV1(path);

    final db = AppDatabase(NativeDatabase(File(path)));
    final conversation = await (db.select(
      db.conversations,
    )..where((tbl) => tbl.id.equals('room-seed'))).getSingleOrNull();
    expect(conversation, isNotNull);
    expect(conversation!.unreadCount, 3);
    expect(conversation.name, '种子会话');

    final message = await (db.select(
      db.messages,
    )..where((tbl) => tbl.id.equals('msg-seed'))).getSingleOrNull();
    expect(message, isNotNull);
    expect(message!.content, '旧消息');
    expect(message.seq, 12);

    // v2 结构恢复：联系人表为空表可用
    final contacts = await db.select(db.cachedContacts).get();
    expect(contacts, isEmpty);
    // v3 结构恢复：last_message_type 列为 NULL
    expect(conversation.lastMessageType, isNull);
    // v4 结构恢复：草稿表为空表可用
    expect(await db.select(db.inputDrafts).get(), isEmpty);

    final version =
        (await db.customSelect('PRAGMA user_version').get()).first.data;
    expect(version['user_version'], 5);
    await db.close();
  });

  test('v3 → v5：input_drafts 表补齐，旧会话/消息不受影响', () async {
    final path = dbPath('v3_to_v4.db');
    await _seedFreshDatabase(path);
    _degradeToV3(path);

    final db = AppDatabase(NativeDatabase(File(path)));
    final conversation = await (db.select(
      db.conversations,
    )..where((tbl) => tbl.id.equals('room-seed'))).getSingleOrNull();
    expect(conversation, isNotNull);
    expect(conversation!.name, '种子会话');

    // v4 结构恢复：草稿表为空表可用
    final drafts = await db.select(db.inputDrafts).get();
    expect(drafts, isEmpty);

    final version =
        (await db.customSelect('PRAGMA user_version').get()).first.data;
    expect(version['user_version'], 5);
    await db.close();
  });

  test('v4 → v5：保留历史并新增会话隐藏水位', () async {
    final path = dbPath('v4.db');
    await _seedFreshDatabase(path);
    final sqlite = sqlite3.open(path);
    sqlite.execute('ALTER TABLE conversations DROP COLUMN hidden_at_seq');
    sqlite.execute('PRAGMA user_version = 4');
    sqlite.close();
    final db = AppDatabase(NativeDatabase(File(path)));
    addTearDown(db.close);
    final room = await db.conversationDao.getConversation('room-seed');
    expect(room, isNotNull);
    expect(room!.hiddenAtSeq, isNull);
    expect(await db.select(db.messages).get(), hasLength(1));
  });

  test('v5：输入草稿跨重启保留，clearSessionCache 时一并清除', () async {
    final path = dbPath('draft.db');
    // 第一段：真实建库并写一份草稿
    final first = AppDatabase(NativeDatabase(File(path)));
    await first
        .into(first.inputDrafts)
        .insert(
          InputDraftsCompanion.insert(
            roomId: 'room-a',
            deltaJson: const Value('[{"insert":"草稿内容\\n"}]'),
            plainText: const Value('草稿内容'),
            updatedAt: seedTime,
          ),
        );
    final seededCount = await first.select(first.inputDrafts).get();
    expect(seededCount, hasLength(1));
    await first.close();

    // 第二段：重新打开（模拟重启），草稿仍在
    final db = AppDatabase(NativeDatabase(File(path)));
    final draft = await (db.select(
      db.inputDrafts,
    )..where((tbl) => tbl.roomId.equals('room-a'))).getSingleOrNull();
    expect(draft, isNotNull);
    expect(draft!.plainText, '草稿内容');
    expect(draft.deltaJson, '[{"insert":"草稿内容\\n"}]');

    // 登出/切账号：clearSessionCache 必须带走个人草稿
    await db.clearSessionCache();
    expect(await db.select(db.inputDrafts).get(), isEmpty);
    await db.close();
  });
}
