import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/features/chat/presentation/call/call_room_page.dart';
import 'package:anoxia/features/chat/presentation/call/mobile_call_page.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pip/pip.dart';

class GlobalCallOverlay extends ConsumerStatefulWidget {
  const GlobalCallOverlay({super.key});

  @override
  ConsumerState<GlobalCallOverlay> createState() => _GlobalCallOverlayState();
}

class _GlobalCallOverlayState extends ConsumerState<GlobalCallOverlay> {
  final Pip _pip = Pip();

  @override
  void initState() {
    super.initState();
    _initPipListener();
  }

  /// ─── 监听系统画中画生命周期 ───
  Future<void> _initPipListener() async {
    try {
      if (await _pip.isSupported()) {
        await _pip.registerStateChangedObserver(
          PipStateChangedObserver(
            onPipStateChanged: (state, error) {
              switch (state) {
                case PipState.pipStateStarted:
                  // 系统成功进入画中画
                  ref.read(mobileCallSessionControllerProvider.notifier).setPipMode(true);
                  break;
                case PipState.pipStateStopped:
                  // ─── 核心防御：从画中画点回应用，或者画中画被关闭 ───
                  ref.read(mobileCallSessionControllerProvider.notifier).exitPipMode();
                  break;
                case PipState.pipStateFailed:
                  debugPrint('PiP failed: $error');
                  ref.read(mobileCallSessionControllerProvider.notifier).exitPipMode();
                  break;
              }
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('Register PiP Observer Error: $e');
    }
  }

  @override
  void dispose() {
    // 释放原生监听，防内存泄漏
    _pip.unregisterStateChangedObserver();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(mobileCallSessionControllerProvider);
    if (session == null) return const SizedBox.shrink();

    final isMinimized = session.minimized;
    final isInPipMode = session.isInPipMode;
    final token = session.token;

    // ─── 🎬 形态 A：系统画中画（切桌面时） ───
    if (isInPipMode && token != null) {
      return CallRoomPage(token: token);
    }

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;

          // ─── 📱 形态 B：应用内小窗 ───
          if (isMinimized) {
            return Stack(
              children: [
                const IgnorePointer(child: SizedBox.expand()),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  left: session.position.dx,
                  top: session.position.dy,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      ref
                          .read(mobileCallSessionControllerProvider.notifier)
                          .updatePosition(details.delta, screenWidth, screenHeight);
                    },
                    onPanEnd: (_) {
                      ref
                          .read(mobileCallSessionControllerProvider.notifier)
                          .snapToEdge(screenWidth);
                    },
                    onTap: () {
                      // 点击小窗恢复全屏：此时不需要重新 setup，全屏默认已允许 PiP
                      ref
                          .read(mobileCallSessionControllerProvider.notifier)
                          .enterCallPage();
                    },
                    child: Material(
                      elevation: 10,
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      shadowColor: Colors.black45,
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        width: 120,
                        height: 180,
                        child: token != null
                            ? CallRoomPage(token: token)
                            : const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // ─── 📺 形态 C：正常全屏通话状态 ───
          return Scaffold(
            backgroundColor: DeviceUtil.isRealDesktop()
                ? Colors.transparent
                : Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              title: Text(
                session.title.isEmpty ? 'appbar_start_meeting'.tr() : session.title,
              ),
              leading: IconButton(
                icon: const Icon(Icons.fullscreen_exit, size: 28),
                onPressed: () async {
                  // ─── 🚀 解决 Bug 1 的核心：进入应用内小窗时，绝对不能关闭 autoEnterEnabled ───
                  // 而是应该针对小窗的纵向比例（120x180 => 2:3）重新动态调整系统 PiP 比例
                  try {
                    if (await _pip.isSupported()) {
                      await _pip.setup(
                        const PipOptions(
                          autoEnterEnabled: true,
                          aspectRatioX: 2,
                          aspectRatioY: 3, // 匹配应用内小窗的比例
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Setup PiP error: $e');
                  }
                  
                  // 切换状态机进入小窗形态
                  ref
                      .read(mobileCallSessionControllerProvider.notifier)
                      .minimize();
                },
              ),
            ),
            body: MobileCallPage(roomId: session.roomId, title: session.title),
          );
        },
      ),
    );
  }
}