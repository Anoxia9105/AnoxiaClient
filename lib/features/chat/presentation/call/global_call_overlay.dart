import 'package:anoxia/features/chat/presentation/call/call_room_page.dart';
import 'package:anoxia/features/chat/presentation/call/mobile_call_page.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 全局通话浮层（大厂方案核心组件）
class GlobalCallOverlay extends ConsumerStatefulWidget {
  const GlobalCallOverlay({super.key});

  @override
  ConsumerState<GlobalCallOverlay> createState() => _GlobalCallOverlayState();
}

class _GlobalCallOverlayState extends ConsumerState<GlobalCallOverlay> {
  // 用于实现应用内小窗拖拽的位置变量（改为基于右上角定位：dx代表距右边，dy代表距上边）
  Offset _offset = const Offset(16, 150);

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

                Positioned(
                  right: _offset.dx,
                  top: _offset.dy,
                  child: GestureDetector(
                    // 拖拽手势：由于外层有 LayoutBuilder 撑满，此时全局拖拽绝不会断掉
                    onPanUpdate: (details) {
                      setState(() {
                        double newDx = _offset.dx - details.delta.dx;
                        double newDy = _offset.dy + details.delta.dy;
                        // 边界防御：防止拖出屏幕可视区域
                        _offset = Offset(
                          newDx.clamp(16.0, screenWidth - 136.0),
                          newDy.clamp(50.0, screenHeight - 210.0),
                        );
                      });
                    },
                    onTap: () {
                      // 点击应用内小窗，一键瞬间恢复全屏
                      ref
                          .read(mobileCallSessionControllerProvider.notifier)
                          .enterCallPage();
                    },
                    child: Container(
                      width: 120,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: token != null
                            ? CallRoomPage(token: token) // 无缝复用视频流单例
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
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: Text(
                session.title.isEmpty ? 'appbar_start_meeting'.tr() : session.title,
              ),
              leading: IconButton(
                icon: const Icon(Icons.fullscreen_exit, size: 28),
                onPressed: () {
                  // 点击缩小：一键进入形态 B
                  ref.read(mobileCallSessionControllerProvider.notifier).minimize();
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