import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:anoxia/framework/provider/core/call_repository_provider.dart';
import 'package:anoxia/platform/shims/window_manager_shim.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// 通话错误状态统一组件
///
/// 提供「取消 / 重新尝试」按钮：
/// - 取消：结束通话信令并关闭悬浮窗（或桌面通话窗口）
/// - 重新尝试：重新向服务端拉取新 token 后重连（避免复用过期 token 导致 LiveKit 401），
///   重试期间按钮展示加载指示，提供可见反馈
class CallErrorState extends ConsumerStatefulWidget {
  const CallErrorState({
    super.key,
    required this.roomId,
    this.title,
    this.errorText,
    this.detail,
    this.onRetry,
    this.onCancel,
  });

  /// 房间 ID（重新拉取 token / 结束通话信令用）
  final String roomId;

  /// 通话标题
  final String? title;

  /// 主错误文案（默认 call_connection_failed）
  final String? errorText;

  /// 错误详情
  final String? detail;

  /// 自定义重试逻辑（默认：重新拉取 token 并更新会话）
  final Future<void> Function()? onRetry;

  /// 自定义取消逻辑（默认：结束通话并关闭悬浮窗 / 窗口）
  final Future<void> Function()? onCancel;

  @override
  ConsumerState<CallErrorState> createState() => _CallErrorStateState();
}

class _CallErrorStateState extends ConsumerState<CallErrorState> {
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      if (widget.onRetry != null) {
        await widget.onRetry!();
      } else {
        await _defaultRetry();
      }
    } catch (_) {
      // 重试失败（网络 / 鉴权异常），保持当前错误态供用户再次操作
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  Future<void> _defaultRetry() async {
    if (DeviceUtil.isRealMobile() || DeviceUtil.isWeb) {
      // 直接向服务端拉取新 token，避免复用已过期的 LiveKit token
      final fresh = await ref
          .read(callRepositoryProvider)
          .fetchCallToken(widget.roomId);
      if (!mounted) return;
      ref.read(mobileCallSessionControllerProvider.notifier).updateToken(fresh);
    } else {
      // 桌面窗口页面监听 roomTokenProvider，刷新其缓存即可自动重建
      ref.invalidate(roomTokenProvider(widget.roomId));
    }
  }

  Future<void> _cancel() async {
    if (widget.onCancel != null) {
      await widget.onCancel!();
      return;
    }
    await _defaultCancel();
  }

  Future<void> _defaultCancel() async {
    ref
        .read(callInvitationControllerProvider.notifier)
        .endRoom(widget.roomId, title: widget.title);
    if (DeviceUtil.isRealMobile() || DeviceUtil.isWeb) {
      // 关闭悬浮窗并退出通话
      ref.read(mobileCallSessionControllerProvider.notifier).end();
    } else {
      // 桌面端关闭独立通话窗口
      await windowManager.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlertCircle,
              color: theme.colorScheme.error,
              size: 44,
            ),
            const SizedBox(height: 20),
            Text(
              widget.errorText ?? 'call_connection_failed'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.detail != null && widget.detail!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.detail!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _retrying ? null : _cancel,
                    child: Text('cancel'.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _retrying ? null : _retry,
                    child: _retrying
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : Text(
                            'call_retry'.tr(),
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
