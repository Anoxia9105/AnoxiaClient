// P1-3 会话设置云同步：reconcile 与乐观切换/回滚用例
//
// 覆盖：
// - ChatRoomVO.isMuted/isPinned 兼容解析（bool/数字/字符串/缺省）
// - 服务端真源 reconcile 覆盖本地；旧部署缺字段回落本地行为
// - 切换先本地生效（不等推送完成），随后异步推送
// - 推送失败（服务端拒绝/网络异常）回滚 + toast；旧部署 404 静默保留本地
import 'dart:async';

import 'package:anoxia/common/utils/sp_util.dart';
import 'package:anoxia/domain/repositories/room_repository.dart';
import 'package:anoxia/framework/core/toast_service.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/provider/chat/room/do_not_disturb_rooms_provider.dart';
import 'package:anoxia/framework/provider/chat/room/pinned_rooms_provider.dart';
import 'package:anoxia/framework/provider/core/room_repository_provider.dart';
import 'package:anoxia/framework/provider/core/toast_service_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef _UpdateHandler = Future<bool> Function(String roomId, bool value);

/// 可变行为的假仓库：用例中直接修改 onPinned/onDnd 切换成功/失败场景。
class _FakeRoomRepository implements RoomRepository {
  _UpdateHandler onPinned = (roomId, value) async => true;
  _UpdateHandler onDnd = (roomId, value) async => true;

  final pinnedCalls = <(String, bool)>[];
  final dndCalls = <(String, bool)>[];

  @override
  Future<bool> setRoomPinned(String roomId, bool isPinned) {
    pinnedCalls.add((roomId, isPinned));
    return onPinned(roomId, isPinned);
  }

  @override
  Future<bool> setRoomDoNotDisturb(String roomId, bool isMuted) {
    dndCalls.add((roomId, isMuted));
    return onDnd(roomId, isMuted);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ToastRecorder implements ToastService {
  final messages = <String>[];

  @override
  void showToast(
    String message, {
    ToastType type = ToastType.info,
    Alignment align = Alignment.bottomCenter,
    Duration duration = const Duration(seconds: 3),
  }) {
    messages.add(message);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ChatRoomVO _room(String id, {bool? pinned, bool? muted}) {
  return ChatRoomVO(roomId: id, isPinned: pinned, isMuted: muted);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeRoomRepository repository;
  late _ToastRecorder toasts;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SPUtil.instance.init();
    repository = _FakeRoomRepository();
    toasts = _ToastRecorder();
    container = ProviderContainer(
      overrides: [
        roomRepositoryProvider.overrideWithValue(repository),
        toastServiceProvider.overrideWithValue(toasts),
      ],
    );
    addTearDown(container.dispose);
  });

  tearDown(() async {
    await SPUtil.instance.clear();
  });

  /// 推送被 unawaited，排空真实事件循环使其落地。
  Future<void> flushAsync() async {
    for (var i = 0; i < 16; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('ChatRoomVO 兼容字段解析', () {
    test('bool / 数字 / 字符串 均可解析，缺省为 null（旧部署回落）', () {
      final parsed = ChatRoomVO.fromJson({
        'roomId': 'r',
        'isPinned': true,
        'isMuted': 'false',
      });
      expect(parsed.isPinned, isTrue);
      expect(parsed.isMuted, isFalse);

      final numeric = ChatRoomVO.fromJson({'isPinned': 1, 'isMuted': 0});
      expect(numeric.isPinned, isTrue);
      expect(numeric.isMuted, isFalse);

      final legacy = ChatRoomVO.fromJson({'roomId': 'r'});
      expect(legacy.isPinned, isNull);
      expect(legacy.isMuted, isNull);
    });
  });

  group('PinnedRooms reconcile', () {
    test('服务端非空值覆盖本地（true 入列 / false 出列）', () async {
      await SPUtil.instance.setStringList(
        PinnedRooms.storageKey,
        ['room-1'],
      );
      final pinned = container.read(pinnedRoomsProvider.notifier);
      expect(pinned.isPinned('room-1'), isTrue);

      container.read(pinnedRoomsProvider.notifier).reconcileFromServer([
        _room('room-1', pinned: false),
        _room('room-2', pinned: true),
      ]);

      expect(container.read(pinnedRoomsProvider), {'room-2'});
      expect(SPUtil.instance.getStringList(PinnedRooms.storageKey), ['room-2']);
    });

    test('旧部署缺字段回落本地行为', () async {
      await SPUtil.instance.setStringList(
        PinnedRooms.storageKey,
        ['room-1'],
      );
      container.read(pinnedRoomsProvider.notifier);

      container.read(pinnedRoomsProvider.notifier).reconcileFromServer([
        _room('room-1'),
        _room('room-2'),
      ]);

      expect(container.read(pinnedRoomsProvider), {'room-1'});
    });

    test('未出现在服务端响应里的本地置顶保留（离线兜底）', () async {
      await SPUtil.instance.setStringList(
        PinnedRooms.storageKey,
        ['room-1'],
      );
      container.read(pinnedRoomsProvider.notifier);

      container
          .read(pinnedRoomsProvider.notifier)
          .reconcileFromServer([_room('room-2', pinned: true)]);

      expect(container.read(pinnedRoomsProvider), {'room-1', 'room-2'});
    });
  });

  group('PinnedRooms toggle', () {
    test('乐观生效：不等推送完成本地即生效并持久化', () async {
      final release = Completer<bool>();
      repository.onPinned = (roomId, value) => release.future;

      final pinned = container.read(pinnedRoomsProvider.notifier);

      // toggle 只等待本地生效，不等推送返回
      await pinned.toggle('room-x');

      expect(container.read(pinnedRoomsProvider), contains('room-x'));
      expect(
        SPUtil.instance.getStringList(PinnedRooms.storageKey),
        contains('room-x'),
      );

      release.complete(true);
      await flushAsync();
      expect(repository.pinnedCalls, contains(('room-x', true)));
    });

    test('推送失败回滚本地 + toast', () async {
      repository.onPinned = (roomId, value) async {
        throw Exception('network down');
      };
      final pinned = container.read(pinnedRoomsProvider.notifier);

      await pinned.toggle('room-y');
      await flushAsync();

      expect(container.read(pinnedRoomsProvider), isNot(contains('room-y')));
      expect(
        SPUtil.instance.getStringList(PinnedRooms.storageKey),
        isNot(contains('room-y')),
      );
      expect(toasts.messages, hasLength(1));
    });

    test('服务端业务失败同样回滚', () async {
      repository.onPinned = (roomId, value) async => false;
      final pinned = container.read(pinnedRoomsProvider.notifier);

      await pinned.toggle('room-fail');
      await flushAsync();

      expect(
        container.read(pinnedRoomsProvider),
        isNot(contains('room-fail')),
      );
      expect(toasts.messages, hasLength(1));
    });

    test('旧部署 404 静默保留本地新值', () async {
      repository.onPinned = (roomId, value) async {
        throw DioException(
          requestOptions: RequestOptions(path: '/chat/room/settings'),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
          ),
        );
      };
      final pinned = container.read(pinnedRoomsProvider.notifier);

      await pinned.toggle('room-z');
      await flushAsync();

      expect(container.read(pinnedRoomsProvider), contains('room-z'));
      expect(toasts.messages, isEmpty);
    });
  });

  group('DoNotDisturbRooms', () {
    test('reconcile 覆盖 / 缺字段回落本地', () async {
      await SPUtil.instance.setStringList(
        DoNotDisturbRooms.storageKey,
        ['room-local'],
      );
      final dnd = container.read(doNotDisturbRoomsProvider.notifier);
      expect(dnd.isEnabled('room-local'), isTrue);

      container
          .read(doNotDisturbRoomsProvider.notifier)
          .reconcileFromServer([
            _room('room-a', muted: true),
            _room('room-local', muted: false),
            _room('room-c'),
          ]);

      expect(
        container.read(doNotDisturbRoomsProvider),
        equals({'room-a'}),
      );
    });

    test('乐观切换先本地生效，推送成功固化', () async {
      final release = Completer<bool>();
      repository.onDnd = (roomId, value) => release.future;
      final dnd = container.read(doNotDisturbRoomsProvider.notifier);

      await dnd.setEnabled('room-d', true);

      expect(
        container.read(doNotDisturbRoomsProvider),
        contains('room-d'),
      );
      expect(
        SPUtil.instance.getStringList(DoNotDisturbRooms.storageKey),
        contains('room-d'),
      );

      release.complete(true);
      await flushAsync();
      expect(repository.dndCalls, contains(('room-d', true)));
    });

    test('推送失败回滚 + toast', () async {
      repository.onDnd = (roomId, value) async {
        throw Exception('boom');
      };
      final dnd = container.read(doNotDisturbRoomsProvider.notifier);

      await dnd.setEnabled('room-e', true);
      await flushAsync();

      expect(
        container.read(doNotDisturbRoomsProvider),
        isNot(contains('room-e')),
      );
      expect(toasts.messages, hasLength(1));
    });

    test('退房清理 remove 不推送服务端', () async {
      await SPUtil.instance.setStringList(
        DoNotDisturbRooms.storageKey,
        ['room-r'],
      );
      final dnd = container.read(doNotDisturbRoomsProvider.notifier);
      expect(dnd.isEnabled('room-r'), isTrue);

      await dnd.remove('room-r');
      await flushAsync();

      expect(repository.dndCalls, isEmpty);
      expect(
        container.read(doNotDisturbRoomsProvider),
        isNot(contains('room-r')),
      );
    });
  });
}
