import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/features/chat/presentation/call/desktop/call_window_room_body.dart';
import 'package:anoxia/features/chat/presentation/call/mobile/call_mobile_room_body.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

/// 通话房间页面
///
/// 通话功能的核心页面，负责：
/// - 管理房间连接状态
/// - 根据布局模式切换显示方式
/// - 处理重连状态显示
/// - 显示历史消息面板
class CallRoomPage extends ConsumerWidget {
  /// 房间令牌
  final String token;

  const CallRoomPage({super.key, required this.token});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomControllerProvider(token));

    return roomAsync.when(
      loading: () => _buildLoadingState(),
      error: (err, _) => _buildErrorState(err.toString(), ref, token),
      data: (roomState) {
        //  在这里根据设备类型进行端隔离分流！
        if (DeviceUtil.isRealMobile()) {
          // 移动端：走专门为移动端设计的布局，传入 token 和 roomState
          return CallMobileRoomBody(roomState: roomState, token: token);
        } else {
          // 桌面端：直接走全屏的桌面布局，传入 token 和 roomState
          return CallWindowRoomBody(roomState: roomState, token: token);
        }
      },
    );
  }

  /// 构建加载中状态
  Widget _buildLoadingState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.ring_volume_rounded, size: 34),
            const SizedBox(height: 14),
            Text(
              'call_connecting_to_room'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'call_please_wait'.tr(),
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(String error, WidgetRef ref, String token) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
            const SizedBox(height: 24),
            Text(
              'call_connection_failed'.tr(),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: const TextStyle(fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => ref.invalidate(roomControllerProvider(token)),
                child: Text(
                  'call_retry'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
