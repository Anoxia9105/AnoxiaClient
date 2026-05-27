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

class _GlobalCallOverlayState extends ConsumerState<GlobalCallOverlay>
    with WidgetsBindingObserver {
  final Pip _pip = Pip();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 挂载生命周期监听
    _initPipListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 卸载生命周期监听
    _pip.unregisterStateChangedObserver();
    super.dispose();
  }

  /// ─── 🚀 核心一：强制初始化全量参数，彻底消灭 Java 拆箱 NPE ───
  Future<void> _initPipListener() async {
    try {
      if (await _pip.isSupported()) {
        // 首次进入时，必须提供全量参数，确保底层 mPipParams 绝对不为空！
        await _pip.setup(
          const PipOptions(
            autoEnterEnabled: true,
            aspectRatioX: 9,
            aspectRatioY: 16,
            controlStyle: 2,
            useExternalStateMonitor: false,
            seamlessResizeEnabled: false,
          ),
        );

        await _pip.registerStateChangedObserver(
          PipStateChangedObserver(
            onPipStateChanged: (state, error) {
              switch (state) {
                case PipState.pipStateStarted:
                  // 保存当前状态（用于退出PiP时恢复悬浮窗）
                  ref.read(mobileCallSessionControllerProvider.notifier).setPipMode(true);
                  break;
                case PipState.pipStateStopped:
                  // 退出PiP时恢复之前的悬浮窗状态
                  ref.read(mobileCallSessionControllerProvider.notifier).exitPipMode();
                  // 从画中画恢复全屏后，重置为全屏比例
                  _pip.setup(
                    const PipOptions(
                      autoEnterEnabled: true,
                      aspectRatioX: 9,
                      aspectRatioY: 16,
                      useExternalStateMonitor: false,
                      seamlessResizeEnabled: false,
                    ),
                  );
                  break;
                case PipState.pipStateFailed:
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

  /// ─── 🚀 核心二：应用内小窗模式下，按 Home 键主动强启画中画 ───
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    final session = ref.read(mobileCallSessionControllerProvider);
    if (session == null) return;

    if (session.minimized &&
        (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused)) {
      try {
        if (await _pip.isSupported() && !(await _pip.isActived())) {
          // 强行触发画中画前，再巩固一次参数配置
          await _pip.setup(
            const PipOptions(
              autoEnterEnabled: true,
              aspectRatioX: 2,
              aspectRatioY: 3,
              controlStyle: 2,
              useExternalStateMonitor: false,
              seamlessResizeEnabled: false, // 防拆箱崩溃
            ),
          );
          await _pip.start();
        }
      } catch (e) {
        debugPrint('Force start PiP error: $e');
      }
    }

    // ⚠️ 关键修复：当应用从后台恢复时，主动检查 PiP 状态
    // 解决原生层异常导致状态不同步的问题
    if (state == AppLifecycleState.resumed) {
      try {
        if (await _pip.isSupported()) {
          final isPipActive = await _pip.isActived();
          debugPrint('--- [生命周期恢复] PiP 状态检测: $isPipActive ---');
          
          // 如果当前状态认为在 PiP 中，但实际不在，则重置状态
          if (session.isInPipMode && !isPipActive) {
            debugPrint('--- [状态同步修复] 强制退出 PiP 模式 ---');
            ref.read(mobileCallSessionControllerProvider.notifier).exitPipMode();
          }
        }
      } catch (e) {
        debugPrint('Error checking PiP state on resume: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(mobileCallSessionControllerProvider);
    if (session == null) return const SizedBox.shrink();

    final isMinimized = session.minimized;
    final isInPipMode = session.isInPipMode;
    final token = session.token;

    // ─── 形态 A：系统画中画 ───
    if (isInPipMode && token != null) {
      // 💡 加入 Material 包裹，防止部分视频渲染器在独立窗口失去上下文背景
      return Material(
        color: Colors.black,
        child: CallRoomPage(token: token),
      );
    }

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;

          // ─── 形态 B：应用内小窗 ───
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
                          .updatePosition(
                            details.delta,
                            screenWidth,
                            screenHeight,
                          );
                    },
                    onPanEnd: (_) {
                      ref
                          .read(mobileCallSessionControllerProvider.notifier)
                          .snapToEdge(screenWidth);
                    },
                    onTap: () {
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // ─── 形态 C：正常全屏通话状态 ───
          return Scaffold(
            backgroundColor: DeviceUtil.isRealDesktop()
                ? Colors.transparent
                : Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              title: Text(
                session.title.isEmpty
                    ? 'appbar_start_meeting'.tr()
                    : session.title,
              ),
              leading: IconButton(
                icon: const Icon(Icons.fullscreen_exit, size: 28),
                onPressed: () async {
                  try {
                    if (await _pip.isSupported()) {
                      // 动态设置为小窗比例，依然强制传递布尔值防空指针！
                      await _pip.setup(
                        const PipOptions(
                          autoEnterEnabled: true,
                          aspectRatioX: 2,
                          aspectRatioY: 3,
                          controlStyle: 2,
                          useExternalStateMonitor: false, // 必须显式写出
                          seamlessResizeEnabled: false, // 必须显式写出
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Setup PiP error: $e');
                  }
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
