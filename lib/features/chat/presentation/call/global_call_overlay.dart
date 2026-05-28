import 'package:anoxia/features/chat/presentation/call/mobile_call_page.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pip/pip.dart';

class GlobalCallOverlay extends ConsumerStatefulWidget {
  const GlobalCallOverlay({super.key});

  @override
  ConsumerState<GlobalCallOverlay> createState() => _GlobalCallOverlayState();
}

class _GlobalCallOverlayState extends ConsumerState<GlobalCallOverlay>
    with WidgetsBindingObserver {
  final Pip _pip = Pip();

  static const MethodChannel _pipChannel = MethodChannel('pip');

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _listenNativePip();

    _initPip();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _pip.unregisterStateChangedObserver();

    super.dispose();
  }

  Future<void> _initPip() async {
    try {
      final supported = await _pip.isSupported();

      if (!supported) return;

      await _pip.setup(
        const PipOptions(
          aspectRatioX: 9,
          aspectRatioY: 16,
          autoEnterEnabled: true,
          seamlessResizeEnabled: false,
        ),
      );

      await _pip.registerStateChangedObserver(
        PipStateChangedObserver(
          onPipStateChanged: (state, error) {
            if (!mounted) return;

            switch (state) {
              case PipState.pipStateStarted:
                ref
                    .read(mobileCallSessionControllerProvider.notifier)
                    .setPipMode(true);

                break;

              case PipState.pipStateStopped:
                ref
                    .read(mobileCallSessionControllerProvider.notifier)
                    .exitPipMode();

                break;

              case PipState.pipStateFailed:
                debugPrint('PiP failed: $error');

                break;
            }
          },
        ),
      );
    } catch (e) {
      debugPrint('Init pip error: $e');
    }
  }

  void _listenNativePip() {
    _pipChannel.setMethodCallHandler((call) async {
      if (call.method == 'onPictureInPictureModeChanged') {
        final bool isInPip = call.arguments as bool;

        if (!mounted) return;

        if (isInPip) {
          ref
              .read(mobileCallSessionControllerProvider.notifier)
              .setPipMode(true);
        } else {
          ref.read(mobileCallSessionControllerProvider.notifier).exitPipMode();
        }
      }
    });
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    final session = ref.read(mobileCallSessionControllerProvider);

    if (session == null) return;

    if (session.isInPipMode) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      try {
        final supported = await _pip.isSupported();

        if (!supported) return;

        final active = await _pip.isActived();

        if (active) return;

        await _pip.start();
      } catch (e) {
        debugPrint('Auto start pip error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(mobileCallSessionControllerProvider);

    if (session == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        /// ─────────────────────────────
        /// 全屏通话层
        /// ─────────────────────────────
        ///
        /// ⚠️ PiP时不能销毁
        /// 必须保持Widget存活
        ///
        Positioned.fill(
          child: IgnorePointer(
            ignoring: session.minimized && !session.isInPipMode,

            child: AnimatedOpacity(
              opacity: session.minimized && !session.isInPipMode ? 0 : 1,

              duration: const Duration(milliseconds: 200),
              child: MobileCallPage(
                roomId: session.roomId,
                title: session.title,
              ),
            ),
          ),
        ),

        /// ─────────────────────────────
        /// Flutter悬浮窗
        /// ─────────────────────────────
        ///
        /// PiP状态隐藏
        ///
        if (session.minimized && !session.isInPipMode)
          Positioned(
            left: session.position.dx,
            top: session.position.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                ref
                    .read(mobileCallSessionControllerProvider.notifier)
                    .updatePosition(
                      details.delta,
                      MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height,
                    );
              },

              onPanEnd: (_) {
                ref
                    .read(mobileCallSessionControllerProvider.notifier)
                    .snapToEdge(MediaQuery.of(context).size.width);
              },

              /// 点击恢复全屏
              onTap: () {
                ref
                    .read(mobileCallSessionControllerProvider.notifier)
                    .enterCallPage();
              },

              child: Material(
                elevation: 10,

                borderRadius: BorderRadius.circular(14),

                clipBehavior: Clip.antiAlias,

                child: SizedBox(
                  width: 120,
                  height: 180,

                  child: Stack(
                    fit: StackFit.expand,

                    children: [
                      /// ⚠️ 这里不能新建第二个页面
                      ///
                      /// 只做缩略图
                      ///
                      Container(color: Colors.black),

                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            const Icon(
                              Icons.call,
                              color: Colors.white,
                              size: 30,
                            ),

                            const SizedBox(height: 8),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),

                              child: Text(
                                session.title,

                                maxLines: 2,

                                overflow: TextOverflow.ellipsis,

                                textAlign: TextAlign.center,

                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
