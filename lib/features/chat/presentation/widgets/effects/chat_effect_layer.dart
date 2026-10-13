import 'dart:async';

import 'package:anoxia/common/utils/motion_utils.dart';
import 'package:anoxia/framework/provider/auth/token_provider.dart';
import 'package:anoxia/framework/provider/chat/effect/chat_effect_dispatcher.dart';
import 'package:anoxia/framework/provider/chat/effect/chat_effect_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/layout/layout_controller.dart';
import 'package:anoxia/framework/provider/setting/chat_effect_settings_provider.dart';
import 'package:anoxia/framework/provider/setting/general_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_effect_rain.dart';

/// 房间级覆盖层，不进入全局 Overlay，不覆盖侧栏或其他窗口。
class ChatEffectLayer extends ConsumerStatefulWidget {
  const ChatEffectLayer({super.key, required this.roomId, required this.child});

  final String roomId;
  final Widget child;

  @override
  ConsumerState<ChatEffectLayer> createState() => _ChatEffectLayerState();
}

class _ChatEffectLayerState extends ConsumerState<ChatEffectLayer>
    with WidgetsBindingObserver {
  ChatEffectDispatcher? _dispatcher;
  StreamSubscription<ChatEffectEvent>? _subscription;
  ChatEffectEvent? _playing;
  DateTime _visibleSince = DateTime.now();
  bool _wasVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  bool _canPlay() {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
      return false;
    }
    final route = ModalRoute.of(context);
    return (route == null || route.isCurrent) &&
        TickerMode.valuesOf(context).enabled &&
        (route?.isFirst == false ||
            ref.read(layoutControllerProvider).currentIndex == 0) &&
        ref.read(activeRoomIdProvider) == widget.roomId &&
        ref.read(chatEffectsEnabledProvider) &&
        !ref.read(reduceMotionProvider) &&
        !isReduceMotion(context);
  }

  void _onEvent(ChatEffectEvent event) {
    if (!mounted || event.roomId != widget.roomId || !_canPlay()) return;
    if (event.observedAt.isBefore(_visibleSince) || _playing != null) return;
    if (_dispatcher?.claim(event) != true) return;
    setState(() => _playing = event);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 恢复前台时刷新边界，后台收到、稍后才落库的消息也不补播。
    _visibleSince = DateTime.now();
    if (mounted) setState(() => _playing = null);
  }

  @override
  void didUpdateWidget(covariant ChatEffectLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.roomId != oldWidget.roomId) {
      _playing = null;
      _visibleSince = DateTime.now();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(chatEffectsEnabledProvider);
    ref.watch(reduceMotionProvider);
    ref.watch(activeRoomIdProvider);
    ref.watch(layoutControllerProvider.select((state) => state.currentIndex));
    ref.watch(tokenCacheProvider);
    final dispatcher = ref.watch(chatEffectDispatcherProvider);
    if (!identical(_dispatcher, dispatcher)) {
      unawaited(_subscription?.cancel());
      _dispatcher = dispatcher;
      _subscription = dispatcher.events.listen(_onEvent);
      _playing = null;
      _visibleSince = DateTime.now();
    }
    final visible = _canPlay();
    if (visible && !_wasVisible) _visibleSince = DateTime.now();
    _wasVisible = visible;
    if (!visible) _playing = null;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_playing case final event?)
          Positioned.fill(
            // 键盘由系统绘制，覆盖层也从可绘制区扣除其占用高度。
            bottom: MediaQuery.viewInsetsOf(context).bottom,
            child: ChatEffectRain(
              key: ObjectKey(event),
              rule: event.rule,
              particleCount: MediaQuery.sizeOf(context).width > 1000 ? 36 : 24,
              onCompleted: () {
                if (mounted) setState(() => _playing = null);
              },
            ),
          ),
      ],
    );
  }
}
