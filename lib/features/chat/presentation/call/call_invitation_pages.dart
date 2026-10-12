import 'package:anoxia/features/chat/presentation/call/component/outgoing_call_view.dart';
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/common/widgets/call_button.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/theme/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'call_invitation_widgets.dart';

class IncomingCallPage extends ConsumerWidget {
  const IncomingCallPage({super.key, required this.invitation});

  final CallInvitationState invitation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final gradient = Theme.of(context).extension<AppColors>()?.scaffoldGradient;
    final isVideo = invitation.initialMedia == CallInitialMedia.video;
    final displayName = invitation.callerName.isEmpty
        ? invitation.title
        : invitation.callerName;
    final avatarUrl = invitation.isGroup && invitation.roomAvatar.isNotEmpty
        ? invitation.roomAvatar
        : invitation.callerAvatar;
    final controller = ref.read(callInvitationControllerProvider.notifier);

    // 独立全屏页用 Scaffold 包裹，保证 Material/InkWell/系统栏适配完整
    return Scaffold(
      backgroundColor: gradient?.colors.first ?? cs.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: gradient?.colors.first ?? cs.surface,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Spacer(flex: 3),
                      // 头像 + 类型角标
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomRight,
                        children: [
                          AvatarWidget(
                            size: 120,
                            url: avatarUrl,
                            name: displayName,
                          ),
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isVideo ? cs.tertiary : cs.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: cs.surface,
                                  width: 2.5,
                                ),
                              ),
                              child: HugeIcon(
                                icon: isVideo
                                    ? HugeIcons.strokeRoundedVideo01
                                    : HugeIcons.strokeRoundedCall02,
                                size: 17,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isVideo
                            ? 'call_invite_video_title'.tr()
                            : 'call_invite_audio_title'.tr(),
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(flex: 4),
                      // 手机全屏来电页底部居中显示接听 / 拒绝按钮组。
                      Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CallActionButton.hangUp(
                              label: 'notification_call_reject'.tr(),
                              icon: HugeIcons.strokeRoundedCallEnd01,
                              onPressed: () => controller.reject(invitation),
                            ),
                            const SizedBox(width: 40),
                            CallActionButton.accept(
                              label: 'notification_call_accept'.tr(),
                              icon: isVideo
                                  ? HugeIcons.strokeRoundedVideo01
                                  : HugeIcons.strokeRoundedCall02,
                              onPressed: () =>
                                  controller.acceptAndOpen(invitation),
                            ),
                          ],
                        ),
                      ),
                      // 视频来电：以语音方式接听，与按钮组居中对齐。
                      if (isVideo) ...[
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: () => controller.acceptAndOpen(
                              invitation,
                              media: CallInitialMedia.audio,
                            ),
                            child: Text(
                              'call_answer_as_voice'.tr(),
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 最小化到全局悬浮窗
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Material(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'call_minimize_tooltip'.tr(),
                    onPressed: () => controller.minimizeInvitation(),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowDown01,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 全屏呼出振铃页（1:1，手机/Web）
///
/// 大头像 + 对方名称 + 「正在呼叫…」，底部提供 免提切换 与 挂断（取消呼叫）。
/// 振铃期不连接媒体，收到 CALL_ACCEPT 后由控制器启动通话会话。
class OutgoingCallPage extends ConsumerWidget {
  const OutgoingCallPage({super.key, required this.invitation});
  final CallInvitationState invitation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final room = ref.watch(currentRoomProvider(invitation.roomId));
    final speakerOn = ref.watch(
      callSpeakerPreferenceProvider(invitation.roomId),
    );
    final controller = ref.read(callInvitationControllerProvider.notifier);
    return OutgoingCallView(
      title: room?.roomName ?? invitation.title,
      avatarUrl: room?.roomAvatar ?? invitation.roomAvatar,
      onCancel: () => controller.cancelCurrent(),
      onMinimize: controller.minimizeInvitation,
      speakerAction: DeviceUtil.isRealMobile()
          ? CallAction(
              label:
                  (speakerOn
                          ? 'call_switch_to_earpiece'
                          : 'call_switch_to_speaker')
                      .tr(),
              icon: speakerOn
                  ? HugeIcons.strokeRoundedVolumeUp
                  : HugeIcons.strokeRoundedEar,
              backgroundColor: colors.surfaceContainerHighest,
              foregroundColor: colors.onSurfaceVariant,
              onPressed: () =>
                  ref
                          .read(
                            callSpeakerPreferenceProvider(
                              invitation.roomId,
                            ).notifier,
                          )
                          .state =
                      !speakerOn,
            )
          : null,
    );
  }
}
