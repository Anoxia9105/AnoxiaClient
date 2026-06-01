import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/features/chat/presentation/widgets/add_member_dialog_widget.dart';
import 'package:anoxia/framework/domain/ChatRoomMemberVO.dart';
import 'package:anoxia/framework/domain/ChatRoomVO.dart';
import 'package:anoxia/framework/provider/chat/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/framework/provider/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';

/// 聊天栏操作处理器
///
/// 提供聊天房间 AppBar 中各类操作的静态方法，包括：
/// - 发起/加入通话
/// - 添加成员
/// - 全体禁言/解除禁言
/// - 踢出成员
class ChatBarHandlers {
  /// 发起或加入通话
  ///
  /// 根据设备类型选择不同的通话方式：
  /// - 移动端：驱动全局大厂 Stack 浮层（GlobalCallOverlay）自适应全屏展现
  /// - 桌面端：打开独立的通话窗口
  ///
  /// [context] 构建上下文
  /// [ref] Riverpod 的 WidgetRef，用于访问 Provider
  /// [room] 当前聊天房间数据
  static void onCallPressed(
    BuildContext context,
    WidgetRef ref,
    ChatRoomVO room,
  ) {
    if ((room.roomId ?? '').isEmpty) {
      Toast.showToast('appbar_connection_lost'.tr());
      return;
    }
    
    if (DeviceUtil.isRealMobile()) {
      final currentSession = ref.read(mobileCallSessionControllerProvider);
      if (currentSession != null) {
        if (currentSession.roomId == room.roomId) {
          // 💡 状态机逻辑回正：点击相同房间，纯状态控制切回全屏
          ref
              .read(mobileCallSessionControllerProvider.notifier)
              .enterCallPage();
        } else {
          Toast.showToast('当前正在其他通话中');
        }
        return;
      }

      // 💡 首次起呼/进入房间：移除了旧的透明路由 push 代码，由全局组件自适应接管
      final roomId = room.roomId ?? '';
      final title = room.roomName ?? '';
      ref
          .read(mobileCallSessionControllerProvider.notifier)
          .start(roomId: roomId, title: title);
          
    } else {
      /// 桌面端直接打开通话窗口
      ref
          .read(callWindowControllerProvider.notifier)
          .openCallWindow(
            title: room.roomName ?? '',
            themeIndex: ref.read(themeIndexProvider),
            roomId: room.roomId ?? '',
          );
    }
  }


  /// 显示全体禁言/解除禁言确认对话框
  ///
  /// 弹出确认弹窗，用户确认后执行禁言或解除禁言操作
  ///
  /// [context] 构建上下文
  /// [ref] Riverpod 的 WidgetRef，用于访问 Provider
  /// [roomId] 房间 ID
  /// [isMute] true 表示执行禁言操作，false 表示解除禁言
  static void showMuteRoomDialog(
    BuildContext context,
    WidgetRef ref,
    String roomId,
    bool isMute,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isDanger = isMute;
    final title = isMute ? 'chat_mute_all'.tr() : 'chat_unmute_all'.tr();
    final description = isMute
        ? 'chat_mute_confirm'.tr()
        : 'chat_unmute_confirm'.tr();

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool submitting = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: (isDanger ? cs.errorContainer : cs.primaryContainer)
                        .withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: HugeIcon(
                    icon: isMute
                        ? HugeIcons.strokeRoundedVolumeMute02
                        : HugeIcons.strokeRoundedVolumeHigh,
                    size: 18,
                    color: isDanger ? cs.error : cs.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedAlert02,
                        size: 14,
                        color: isDanger ? cs.error : cs.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isMute
                              ? 'chat_mute_effect_hint'.tr()
                              : 'chat_unmute_effect_hint'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              OutlinedButton(
                onPressed: submitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: Text('dialog_cancel'.tr()),
              ),
              FilledButton.icon(
                onPressed: submitting
                    ? null
                    : () async {
                        setState(() => submitting = true);
                        final cancelLoading = BotToast.showLoading();
                        try {
                          final success = await ref
                              .read(roomListServiceProvider.notifier)
                              .muteRoom(roomId, isMute);
                          cancelLoading();
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          BotToast.showText(
                            text: success
                                ? (isMute
                                      ? 'chat_mute_success'.tr()
                                      : 'chat_unmute_success'.tr())
                                : 'chat_operation_retry_failed'.tr(),
                          );
                        } catch (e) {
                          cancelLoading();
                          setState(() => submitting = false);
                          BotToast.showText(
                            text: 'chat_operation_failed'.tr(
                              args: [e.toString()],
                            ),
                          );
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: isDanger ? cs.error : cs.primary,
                  foregroundColor: isDanger ? cs.onError : cs.onPrimary,
                ),
                icon: submitting
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDanger ? cs.onError : cs.onPrimary,
                          ),
                        ),
                      )
                    : HugeIcon(
                        icon: isMute
                            ? HugeIcons.strokeRoundedVolumeMute02
                            : HugeIcons.strokeRoundedVolumeHigh,
                        size: 16,
                        color: isDanger ? cs.onError : cs.onPrimary,
                      ),
                label: Text('chat_confirm_btn'.tr()),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 显示踢出成员确认对话框
  ///
  /// 弹出确认弹窗，用户确认后执行踢出成员操作
  ///
  /// [context] 构建上下文
  /// [ref] Riverpod 的 WidgetRef，用于访问 Provider
  /// [roomId] 房间 ID
  /// [member] 要踢出的成员信息
  static void showKickMemberDialog(
    BuildContext context,
    WidgetRef ref,
    String roomId,
    ChatRoomMemberVO member,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('chat_confirm_kick'.tr()),
        content: Text(
          'chat_confirm_kick_content'.tr(
            args: [member.nickName ?? 'chat_unknown_user'.tr()],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('dialog_cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final cancelLoading = BotToast.showLoading();
              try {
                final success = await ref
                    .read(roomMemberServiceProvider.notifier)
                    .kickMember(roomId, member.userId ?? -1);
                cancelLoading();
                BotToast.showText(
                  text: success
                      ? 'chat_kick_success'.tr()
                      : 'chat_kick_failed'.tr(),
                );
              } catch (e) {
                cancelLoading();
                BotToast.showText(
                  text: 'chat_operation_failed'.tr(args: [e.toString()]),
                );
              }
            },
            child: Text(
              'chat_confirm_btn'.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
