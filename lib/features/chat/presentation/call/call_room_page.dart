import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/features/chat/presentation/call/component/call_error_state.dart';
import 'package:anoxia/features/chat/presentation/call/component/call_loading_state.dart';
import 'package:anoxia/features/chat/presentation/call/desktop/call_window_room_body.dart';
import 'package:anoxia/features/chat/presentation/call/mobile/call_mobile_room_body.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:anoxia/framework/provider/core/call_repository_provider.dart';
import 'package:anoxia/platform/shims/window_manager_shim.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:easy_localization/easy_localization.dart';
import 'component/call_disconnection_message.dart';

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
      loading: () => const CallLoadingState(),
      error: (err, _) => CallErrorState(
        roomId: roomId,
        title: ref.read(mobileCallSessionControllerProvider)?.title,
        errorText: 'call_connection_failed'.tr(),
        detail: err.toString(),
        onRetry: () => _retry(context, ref),
        onCancel: () => _cancelCall(context, ref),
      ),
      data: (roomState) {
        if (roomState.connectionState == lk.ConnectionState.disconnected) {
          return CallErrorState(
            roomId: roomId,
            recovering: roomState.isReconnecting,
            errorText:
                (roomState.isReconnecting
                        ? 'call_reconnecting'
                        : 'call_connection_failed')
                    .tr(),
            detail: callDisconnectionMessageKey(roomState.connectionError).tr(),
            onRetry: () => _retry(context, ref),
            onCancel: () => _cancelCall(context, ref),
          );
        }
        //  在这里根据设备类型进行端隔离分流！
        //  - 真实移动端：移动布局（CallMobileRoomBody，底部控制条）
        //  - Web 窄窗（宽度 < 1024，手机/平板尺寸）：移动布局
        //  - 真实桌面与 Web 宽屏（PC）：桌面布局（CommandBar + 参与者磁贴），
        //    配合全局浮层的悬浮窗最小化，即「悬浮窗 + 桌面通话」
        final useMobileLayout =
            DeviceUtil.isRealMobile() ||
            (DeviceUtil.isWeb && !DeviceUtil.isDesktop(context));
        if (useMobileLayout) {
          // 移动/Web 窄窗：走专门为移动端设计的布局
          return Column(
            children: [
              if (roomState.isReconnecting) const _ReconnectingBanner(),
              Expanded(
                child: CallMobileRoomBody(roomState: roomState, token: token),
              ),
            ],
          );
        } else {
          // 桌面/Web 宽屏：走桌面布局
          return CallWindowRoomBody(roomState: roomState, token: token);
        }
      },
    );
  }

  /// 重试：重新向服务端拉取新 token 并重连，
  /// 避免复用已过期（超 24h）的 LiveKit token 导致 401
  Future<void> _retry(BuildContext context, WidgetRef ref) async {
    final fresh = await ref.read(callRepositoryProvider).fetchCallToken(roomId);
    if (!context.mounted) return;
    await ref
        .read(roomControllerProvider(token).notifier)
        .prepareRetry(fresh, isActive: () => context.mounted);
    if (!context.mounted) return;
    // 服务端可能返回相同 JWT，显式清除对应错误缓存也必须生效。
    ref.invalidate(roomControllerProvider(fresh));
    if (DeviceUtil.isRealMobile() || DeviceUtil.isWeb) {
      ref.read(mobileCallSessionControllerProvider.notifier).updateToken(fresh);
    } else {
      CallRetryTokenNotification(fresh).dispatch(context);
    }
  }

  /// 取消：结束通话并关闭悬浮窗 / 通话窗口
  Future<void> _cancelCall(BuildContext context, WidgetRef ref) async {
    if (DeviceUtil.isRealDesktop()) {
      // 与对端挂断 / X 按钮共用窗口关闭流程，先卸载 UI，再等待媒体释放。
      await windowManager.close();
      return;
    }
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

/// 桌面窗口拥有 token，重试时通过通知替换预取值而不是重建旧 token。
class CallRetryTokenNotification extends Notification {
  CallRetryTokenNotification(this.token);
  final String token;
}

class _ReconnectingBanner extends StatelessWidget {
  const _ReconnectingBanner();
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Flexible(child: Text('call_reconnecting'.tr())),
        ],
      ),
    ),
  );
}
