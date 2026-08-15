import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/features/chat/presentation/call/component/call_error_state.dart';
import 'package:anoxia/features/chat/presentation/call/desktop/call_window_room_body.dart';
import 'package:anoxia/features/chat/presentation/call/mobile/call_mobile_room_body.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:anoxia/framework/provider/core/call_repository_provider.dart';
import 'package:anoxia/platform/shims/window_manager_shim.dart';
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

  /// 房间 ID（用于重新拉取 token 与结束通话信令）
  final String roomId;

  const CallRoomPage({super.key, required this.token, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomControllerProvider(token));

    return roomAsync.when(
      loading: () => _buildLoadingState(context),
      error: (err, _) => CallErrorState(
        roomId: roomId,
        title: ref.read(mobileCallSessionControllerProvider)?.title,
        errorText: 'call_connection_failed'.tr(),
        detail: err.toString(),
        onRetry: () => _retry(context, ref),
        onCancel: () => _cancelCall(context, ref),
      ),
      data: (roomState) {
        //  在这里根据设备类型进行端隔离分流！
        //  移动端与 Web 端统一走移动布局（CallMobileRoomBody，含移动端控制条）；
        //  仅真实桌面端渲染桌面布局（CommandBar + 参与者磁贴）。
        //  Web 端由 MobileCallPage 提供主题外壳。
        if (DeviceUtil.isRealMobile() || DeviceUtil.isWeb) {
          // 移动/Web：走专门为移动端设计的布局，传入 token 和 roomState
          return CallMobileRoomBody(roomState: roomState, token: token);
        } else {
          // 桌面端：直接走全屏的桌面布局，传入 token 和 roomState
          return CallWindowRoomBody(roomState: roomState, token: token);
        }
      },
    );
  }

  /// 构建加载中状态
  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 14),
          Text(
            'call_loading'.tr(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 重试：重新向服务端拉取新 token 并重连，
  /// 避免复用已过期（超 24h）的 LiveKit token 导致 401
  Future<void> _retry(BuildContext context, WidgetRef ref) async {
    try {
      if (DeviceUtil.isRealMobile() || DeviceUtil.isWeb) {
        // 移动/Web：直接向服务端拉取新 token（绕过 provider 缓存），
        // 更新会话 token 后由 MobileCallPage 触发重建
        final fresh = await ref
            .read(callRepositoryProvider)
            .fetchCallToken(roomId);
        if (!context.mounted) return;
        ref.read(mobileCallSessionControllerProvider.notifier).updateToken(fresh);
      } else {
        // 桌面窗口页面监听 roomTokenProvider，刷新其缓存即可自动重建
        ref.invalidate(roomTokenProvider(roomId));
      }
    } catch (_) {
      // Token 刷新失败（网络/鉴权异常），降级为使用当前 token 重连
      if (!context.mounted) return;
      ref.invalidate(roomControllerProvider(token));
    }
  }

  /// 取消：结束通话并关闭悬浮窗 / 通话窗口
  Future<void> _cancelCall(BuildContext context, WidgetRef ref) async {
    final session = ref.read(mobileCallSessionControllerProvider);
    final notifier = ref.read(roomControllerProvider(token).notifier);

    // 通知对端通话结束
    ref
        .read(callInvitationControllerProvider.notifier)
        .endRoom(roomId, title: session?.title);

    // 断开 LiveKit（错误态下会直接标记 token 不重连）
    await notifier.leave();

    if (!context.mounted) return;

    if (DeviceUtil.isRealMobile() || DeviceUtil.isWeb) {
      // 关闭悬浮窗并退出通话
      ref.read(mobileCallSessionControllerProvider.notifier).end();
    } else {
      // 桌面端关闭独立通话窗口
      await windowManager.close();
    }
  }
}
