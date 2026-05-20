import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/features/chat/presentation/call/mobile_call_page.dart';
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

class ChatBarHandlers {
  /// 发起或加入通话事件
  static void onCallPressed(BuildContext context, WidgetRef ref, ChatRoomVO room) {
    if ((room.roomId ?? '').isEmpty) {
      Toast.showToast('appbar_connection_lost'.tr());
      return;
    }
    if (DeviceUtil.isRealMobile()) {
      final roomId = room.roomId ?? '';
      final title = room.roomName ?? '';
      ref.read(mobileCallSessionControllerProvider.notifier).start(roomId: roomId, title: title);
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => MobileCallPage(roomId: roomId, title: title)));
    } else {
      ref.read(callWindowControllerProvider.notifier).openCallWindow(
        title: room.roomName ?? '',
        themeIndex: ref.read(themeIndexProvider),
        roomId: room.roomId ?? '',
      );
    }
  }

  /// 弹出添加成员 Dialog
  static void showAddMemberDialog(BuildContext context, ChatRoomVO room) {
    showDialog(
      context: context,
      builder: (context) => AddMemberDialogWidget(roomId: room.roomId!, roomName: room.roomName!),
    );
  }

  /// 处理全体禁言/解除禁言操作
  ///
  /// 显示确认弹窗，确认后执行禁言/解除禁言操作
  ///
  /// [context] 上下文
  /// [ref] WidgetRef 用于访问 Provider
  /// [roomId] 房间 ID
  /// [isMute] true 表示禁言，false 表示解除禁言
  static void showMuteRoomDialog(BuildContext context, WidgetRef ref, String roomId, bool isMute) {
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

  /// 处理踢出成员操作
  ///
  /// 显示确认弹窗，确认后执行踢出操作
  ///
  /// [context] 上下文
  /// [ref] WidgetRef 用于访问 Provider
  /// [roomId] 房间 ID
  /// [targetUserId] 目标用户 ID
  /// [targetUserName] 目标用户名
  static void showKickMemberDialog(BuildContext context, WidgetRef ref, String roomId, ChatRoomMemberVO member) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('chat_confirm_kick'.tr()),
        content: Text('chat_confirm_kick_content'.tr(args: [member.nickName ?? 'chat_unknown_user'.tr()])),
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