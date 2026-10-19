// P0-3 AI 消息工具状态推进与流式收口测试。
//
// - [foldAiToolEvent] 纯函数：thinking 忽略 / delta 累积 / done 兜底 /
//   空结果 / 迟到增量。
// - 控制器经 Fake `AiRepository` 注入流事件：done 终态 / AiException /
//   断流（无 done 也要收口，不得悬挂 streaming）。
// - 总结控制器：内存 drift 种子 + currentRoom 覆写，验证未读文本组装、
//   首条未读记录与空结果降级。
import 'package:anoxia/domain/ai_stream_event.dart';
import 'package:anoxia/domain/repositories/ai_repository.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:anoxia/framework/local_cache/database.dart';
import 'package:anoxia/framework/local_cache/local_data_source.dart';
import 'package:anoxia/framework/provider/chat/message/ai_message_tools_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/core/ai_repository_provider.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements AiRepository {
  final Stream<AiStreamEvent> stream;
  _FakeRepository(this.stream);

  @override
  Stream<AiStreamEvent> askStream(String prompt, {String? conversationId}) =>
      stream;

  @override
  Never ask(String prompt) => throw UnimplementedError();
}

/// 抛 AiException 的流（模拟服务端 error 事件转异常）
Stream<AiStreamEvent> errorStream() async* {
  yield const AiDelta('部');
  throw const AiException('AI 服务暂不可用');
}

ChatMessage textMsg(String id, int seq, String content) => ChatMessage(
  messageId: id,
  clientMsgId: 'client-$id',
  roomId: 'r1',
  senderId: 2,
  seq: seq,
  messageType: MessageType.text,
  content: content,
  deliveryStatus: DeliveryStatus.sent,
);

void main() {
  group('foldAiToolEvent（纯函数）', () {
    test('thinking 增量与哨兵都被忽略', () {
      const base = AiToolState(streaming: true, text: 'a');
      final afterData = foldAiToolEvent(base, const AiThinking('思'));
      expect(afterData.text, 'a');
      expect(afterData.streaming, isTrue);
      final afterSentinel = foldAiToolEvent(afterData, const AiThinking(null));
      expect(afterSentinel.streaming, isTrue);
    });

    test('delta 累积 + 保留 firstUnreadId', () {
      final s = foldAiToolEvent(
        const AiToolState(streaming: true, firstUnreadMessageId: 'm1'),
        const AiDelta('部'),
      );
      expect(s.text, '部');
      expect(s.streaming, isTrue);
      expect(s.firstUnreadMessageId, 'm1');
    });

    test('done 兜底：增量为空用 done.text', () {
      final s = foldAiToolEvent(
        const AiToolState(streaming: true),
        const AiDone(null, '全文', false),
      );
      expect(s.text, '全文');
      expect(s.streaming, isFalse);
      expect(s.isEmptyResult, isFalse);
    });

    test('done 且全文为空 → 空结果态', () {
      final s = foldAiToolEvent(
        const AiToolState(streaming: true),
        const AiDone(null, '', false),
      );
      expect(s.isEmptyResult, isTrue);
      expect(s.streaming, isFalse);
    });

    test('done 之后迟到的 delta 被忽略', () {
      final done = foldAiToolEvent(
        const AiToolState(streaming: true),
        const AiDone(null, '终稿', false),
      );
      final after = foldAiToolEvent(done, const AiDelta('迟到'));
      expect(after.text, '终稿');
      expect(after.streaming, isFalse);
    });
  });

  group('AiTranslateController（Fake 流注入）', () {
    test('done 终态：正文 + 非流式 + 无错误', () async {
      final container = ProviderContainer(
        overrides: [
          aiRepositoryProvider.overrideWith(
            (ref) => _FakeRepository(
              Stream.fromIterable([
                const AiThinking('思考'),
                const AiDelta('你'),
                const AiDelta('好'),
                const AiDone(null, '', false),
              ]),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(aiTranslateControllerProvider('m1|zh').notifier)
          .translate('hello', language: '简体中文');

      final state = container.read(aiTranslateControllerProvider('m1|zh'));
      expect(state.text, '你好');
      expect(state.streaming, isFalse);
      expect(state.error, isNull);
    });

    test('AiException → 错误态（服务端 message 直出）', () async {
      final container = ProviderContainer(
        overrides: [
          aiRepositoryProvider.overrideWith(
            (ref) => _FakeRepository(errorStream()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(aiTranslateControllerProvider('m2|zh').notifier)
          .translate('hello', language: '简体中文');

      final state = container.read(aiTranslateControllerProvider('m2|zh'));
      expect(state.error, 'AI 服务暂不可用');
      expect(state.text, isNull);
      expect(state.streaming, isFalse);
    });

    test('断流（无 done 且无内容）→ 兜底错误 key', () async {
      final container = ProviderContainer(
        overrides: [
          aiRepositoryProvider.overrideWith(
            (ref) => _FakeRepository(
              Stream.fromIterable([const AiThinking('思考')]),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(aiTranslateControllerProvider('m3|zh').notifier)
          .translate('hello', language: '简体中文');

      final state = container.read(aiTranslateControllerProvider('m3|zh'));
      expect(state.error, 'chat_ai.translate_failed');
      expect(state.streaming, isFalse);
    });

    test('断流（无 done 但有内容）→ 收口为非流式正文，不悬挂转圈', () async {
      final container = ProviderContainer(
        overrides: [
          aiRepositoryProvider.overrideWith(
            (ref) => _FakeRepository(
              Stream.fromIterable([const AiDelta('半途结果')]),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(aiTranslateControllerProvider('m4|zh').notifier)
          .translate('hello', language: '简体中文');

      final state = container.read(aiTranslateControllerProvider('m4|zh'));
      expect(state.text, '半途结果');
      expect(state.streaming, isFalse);
      expect(state.error, isNull);
    });
  });

  group('AiUnreadSummaryController（内存库 + currentRoom 覆写）', () {
    late AppDatabase db;
    late LocalDataSource source;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      source = LocalDataSource(db);
    });
    tearDown(() {
      container.dispose();
      return db.close();
    });

    ProviderContainer makeContainer(AiRepository repo) {
      return ProviderContainer(
        overrides: [
          currentRoomProvider('r1').overrideWith(
            (ref) => ChatRoomVO(
              roomId: 'r1',
              roomType: 0,
              peerId: 2,
              lastReadSeq: 5,
              unreadCount: 3,
            ),
          ),
          localDataSourceProvider.overrideWith((ref) => source),
          aiRepositoryProvider.overrideWith((ref) => repo),
        ],
      );
    }

    test('组装未读文本流并保留首条未读', () async {
      await source.upsertMessage(textMsg('early', 3, '已读区'));
      await source.upsertMessage(textMsg('u1', 6, '未读一'));
      await source.upsertMessage(textMsg('u2', 7, '未读二'));
      await source.upsertMessage(textMsg('media', 8, ''));
      container = makeContainer(
        _FakeRepository(
          Stream.fromIterable([const AiDelta('要点'), const AiDone(null, '', false)]),
        ),
      );

      await container
          .read(aiUnreadSummaryControllerProvider('r1').notifier)
          .summarize(language: '简体中文');

      final state = container.read(aiUnreadSummaryControllerProvider('r1'));
      expect(state.text, '要点');
      expect(state.firstUnreadMessageId, 'u1');
      expect(state.isEmptyResult, isFalse);
    });

    test('媒体-only 未读 → 空结果态（不发起 AI 流）', () async {
      container = makeContainer(
        _FakeRepository(
          // 不应被消费：若流被消费就代表逻辑错了，直接挂掉测试
          Stream.fromIterable([const AiDone(null, '不该被调用', false)]),
        ),
      );
      await source.upsertMessage(textMsg('pic', 6, ''));

      await container
          .read(aiUnreadSummaryControllerProvider('r1').notifier)
          .summarize(language: '简体中文');

      final state = container.read(aiUnreadSummaryControllerProvider('r1'));
      expect(state.isEmptyResult, isTrue);
      expect(state.text, isNull);
      // 空结果也要给出「跳到最早未读」目标（第一条未读消息是图片）
      expect(state.firstUnreadMessageId, 'pic');
    });

    test('本地查询失败（脏库）→ 空结果而非抛错', () async {
      // 注入一个已关闭的数据库实例模拟查询失败
      final deadDb = AppDatabase(NativeDatabase.memory());
      await deadDb.close();
      container = ProviderContainer(
        overrides: [
          currentRoomProvider('r1').overrideWith(
            (ref) => ChatRoomVO(
              roomId: 'r1',
              roomType: 0,
              peerId: 2,
              lastReadSeq: 5,
              unreadCount: 3,
            ),
          ),
          localDataSourceProvider.overrideWith((ref) => LocalDataSource(deadDb)),
          aiRepositoryProvider.overrideWith(
            (ref) => _FakeRepository(
              Stream.fromIterable([const AiDone(null, 'x', false)]),
            ),
          ),
        ],
      );

      await container
          .read(aiUnreadSummaryControllerProvider('r1').notifier)
          .summarize(language: '简体中文');

      final state = container.read(aiUnreadSummaryControllerProvider('r1'));
      expect(state.isEmptyResult, isTrue);
    });
  });
}
