import 'package:anoxia/common/utils/sp_util.dart';
import 'package:anoxia/features/chat/presentation/widgets/effects/chat_effect_layer.dart';
import 'package:anoxia/features/chat/presentation/widgets/effects/chat_effect_rain.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/chat/effect/chat_effect_dispatcher.dart';
import 'package:anoxia/framework/provider/chat/effect/chat_effect_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/layout/layout_controller.dart';
import 'package:anoxia/framework/provider/setting/chat_effect_settings_provider.dart';
import 'package:anoxia/framework/provider/setting/general_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ActiveRoom extends ActiveRoomId {
  @override
  String? build() => 'r1';

  @override
  void setActive(String? roomId) => state = roomId;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ChatEffectDispatcher dispatcher;
  late ProviderContainer container;
  var taps = 0;

  Widget app({bool systemReduceMotion = false, String roomId = 'r1'}) =>
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: systemReduceMotion),
            child: child!,
          ),
          home: ChatEffectLayer(
            roomId: roomId,
            child: Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => taps++,
                  child: const Text('点我'),
                ),
              ),
            ),
          ),
        ),
      );

  void offer(
    String id, {
    String roomId = 'r1',
    DateTime? observedAt,
    String text = '生日快乐',
  }) {
    final now = DateTime.now();
    dispatcher.offer(
      ChatMessage(
        messageId: id,
        roomId: roomId,
        messageType: MessageType.text,
        content: text,
        timestamp: now.millisecondsSinceEpoch,
      ),
      observedAt: observedAt ?? now,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SPUtil.instance.init();
    await SPUtil.instance.clear();
    taps = 0;
    dispatcher = ChatEffectDispatcher();
    container = ProviderContainer(
      overrides: [
        chatEffectDispatcherProvider.overrideWith((ref) => dispatcher),
        activeRoomIdProvider.overrideWith(_ActiveRoom.new),
      ],
    );
  });
  tearDown(() {
    container.dispose();
    dispatcher.dispose();
  });

  testWidgets('只显示下落层，无弹窗且不阻碍点击，结束后释放', (tester) async {
    await tester.pumpWidget(app());
    offer('m1');
    await tester.pump();
    expect(find.byType(ChatEffectRain), findsOneWidget);
    final rain = tester.widget<ChatEffectRain>(find.byType(ChatEffectRain));
    expect(rain.particleCount, 24); // 800 宽基础档 24 × 生日规则 1.0
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('生日快乐'), findsNothing);
    await tester.tap(find.text('点我'));
    expect(taps, 1);
    await tester.pumpAndSettle();
    expect(find.byType(ChatEffectRain), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('想你了落亲亲红心并按满屏密度播放，关闭共用开关立即停止', (tester) async {
    await tester.pumpWidget(app());
    offer('kiss1', text: '想你了');
    await tester.pump();
    final rain = tester.widget<ChatEffectRain>(find.byType(ChatEffectRain));
    expect(rain.rule.id, 'kiss');
    expect(rain.rule.emojis, ['💋', '❤️']);
    expect(rain.particleCount, 36); // 24 × 满屏密度 1.5
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('想你了'), findsNothing);
    await tester.tap(find.text('点我'));
    expect(taps, 1);
    container.read(chatEffectsEnabledProvider.notifier).setEnabled(false);
    await tester.pump();
    expect(find.byType(ChatEffectRain), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('设置默认开启，关闭立即清理且重建 Provider 后保持关闭', (tester) async {
    await tester.pumpWidget(app());
    expect(container.read(chatEffectsEnabledProvider), isTrue);
    offer('m1');
    await tester.pump();
    container.read(chatEffectsEnabledProvider.notifier).setEnabled(false);
    await tester.pump();
    expect(find.byType(ChatEffectRain), findsNothing);
    offer('m2');
    await tester.pump();
    expect(find.byType(ChatEffectRain), findsNothing);
    container.invalidate(chatEffectsEnabledProvider);
    expect(container.read(chatEffectsEnabledProvider), isFalse);
  });

  testWidgets('应用或系统减少动效均禁止播放', (tester) async {
    await tester.pumpWidget(app());
    container.read(reduceMotionProvider.notifier).setEnabled(true);
    await tester.pump();
    offer('m1');
    await tester.pump();
    expect(find.byType(ChatEffectRain), findsNothing);
    container.read(reduceMotionProvider.notifier).setEnabled(false);
    await tester.pumpWidget(app(systemReduceMotion: true));
    offer('m2');
    await tester.pump();
    expect(find.byType(ChatEffectRain), findsNothing);
  });

  testWidgets('其他房间、进入页面前到达的消息不播放', (tester) async {
    final beforeEntry = DateTime.now().subtract(const Duration(seconds: 1));
    await tester.pumpWidget(app());
    offer('m1', roomId: 'r2');
    offer('m2', observedAt: beforeEntry);
    await tester.pump();
    expect(find.byType(ChatEffectRain), findsNothing);
    offer('m3');
    await tester.pump();
    expect(find.byType(ChatEffectRain), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('被路由覆盖立即停止，返回后不重放', (tester) async {
    await tester.pumpWidget(app());
    final context = tester.element(find.text('点我'));
    offer('m1');
    await tester.pump();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('设置页')),
      ),
    );
    await tester.pumpAndSettle();
    offer('m2');
    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    expect(find.byType(ChatEffectRain), findsNothing);
  });

  testWidgets('宽屏切到设置标签、切房间时停止', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app());
    offer('m1');
    await tester.pump();
    container.read(layoutControllerProvider.notifier).setIndex(6);
    await tester.pump();
    expect(find.byType(ChatEffectRain), findsNothing);
    offer('m2');
    container.read(layoutControllerProvider.notifier).setIndex(0);
    await tester.pump();
    expect(find.byType(ChatEffectRain), findsNothing);
    container.read(activeRoomIdProvider.notifier).setActive('r2');
    await tester.pumpWidget(app(roomId: 'r2'));
    offer('m3', roomId: 'r2');
    await tester.pump();
    expect(find.byType(ChatEffectRain), findsOneWidget);
    container.read(activeRoomIdProvider.notifier).setActive('r3');
    await tester.pump();
    expect(find.byType(ChatEffectRain), findsNothing);
  });

  testWidgets('进入后台停止，恢复前台不补播后台到达的消息', (tester) async {
    await tester.pumpWidget(app());
    offer('m1');
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    expect(find.byType(ChatEffectRain), findsNothing);
    final hiddenAt = DateTime.now();
    offer('m2');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    offer('m3', observedAt: hiddenAt);
    await tester.pump();
    expect(find.byType(ChatEffectRain), findsNothing);
  });
}
