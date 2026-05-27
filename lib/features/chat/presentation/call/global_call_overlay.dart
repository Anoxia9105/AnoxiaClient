import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/features/chat/presentation/call/call_room_page.dart';
import 'package:anoxia/features/chat/presentation/call/mobile_call_page.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pip/pip.dart';

/// 全局通话浮层（大厂方案核心组件）
class GlobalCallOverlay extends ConsumerStatefulWidget {
  const GlobalCallOverlay({super.key});

  @override
  ConsumerState<GlobalCallOverlay> createState() => _GlobalCallOverlayState();
}

class _GlobalCallOverlayState extends ConsumerState<GlobalCallOverlay> {
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

    // 💡 优化核心：让组件在外层永远保持 Positioned.fill 撑满屏幕，保障手势全局不丢失
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;

          // ─── 📱 形态 B：用户点击“缩小”进入的应用内小窗 ───
          if (isMinimized) {
            return Stack(
              children: [
                // 💡 占位透明层：故意不加颜色，配合 IgnorePointer 允许用户点击底层的聊天列表
                const IgnorePointer(child: SizedBox.expand()),

                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  left: session.position.dx,
                  top: session.position.dy,
                  child: GestureDetector(
                    // 拖拽手势：由于外层有 LayoutBuilder 撑满，此时全局拖拽绝不会断掉
                    onPanUpdate: (details) {
                      ref
                          .read(mobileCallSessionControllerProvider.notifier)
                          .updatePosition(
                            details.delta,
                            screenWidth,
                            screenHeight,
                          );
                    },
                    // 💡 手势松开：一键计算并完成自动吸边
                    onPanEnd: (_) {
                      ref
                          .read(mobileCallSessionControllerProvider.notifier)
                          .snapToEdge(screenWidth);
                    },
                    onTap: () async {
                      // ─── 🚀 修复核心：重新拉回全屏时，恢复系统级 PiP 的自动触发配置 ───
                      try {
                        final pip = Pip();
                        if (await pip.isSupported()) {
                          await pip.setup(
                            const PipOptions(
                              autoEnterEnabled: true,
                              aspectRatioX: 16,
                              aspectRatioY: 9,
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('Re-enable PiP auto enter error: $e');
                      }
                      // 点击应用内小窗，一键瞬间恢复全屏
                      ref
                          .read(mobileCallSessionControllerProvider.notifier)
                          .enterCallPage();
                    },
                    child: Material(
                      elevation: 10,
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      shadowColor: Colors.black45,
                      clipBehavior: Clip.antiAlias, // 代替 ClipRRect 进行边缘裁剪
                      child: SizedBox(
                        width: 120,
                        height: 180,
                        child: token != null
                            ? CallRoomPage(token: token) // 无缝复用视频流单例
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

          // ─── 📺 形态 C：正常全屏通话状态 ───
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
                  // 点击缩小：一键进入形态 B
                  try {
                    final pip = Pip();
                    if (await pip.isSupported()) {
                      await pip.setup(
                        const PipOptions(autoEnterEnabled: false),
                      );
                    }
                  } catch (e) {
                    debugPrint('Disable PiP auto enter error: $e');
                  }
                  // 然后再切换状态机进入小窗形态
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
