// 通话邀请浮层组件，根据不同的通话邀请阶段显示对应的 UI。
//
// - 桌面端（真实桌面）：来电阶段不渲染应用内弹窗，改为系统通知（右上角），
//   用户通过通知的接听/拒绝动作处理；呼出振铃由独立通话窗口展示；
//   其余阶段（忙线/取消/被拒等）保留轻量提示。
// - 手机端：1:1 来电显示全屏来电页，呼出显示全屏振铃页；
//   群呼邀请是「通知式」横幅（可加入/忽略）。
// - Web 端：来电保留顶部非遮挡横幅（可接听/拒绝），呼出显示全屏振铃页。
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/theme/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 通话邀请浮层
///
/// 监听 [callInvitationControllerProvider] 获取当前邀请状态，
/// 根据 [CallInvitationPhase] 切换展示不同的 UI。
class CallInvitationOverlay extends ConsumerWidget {
  const CallInvitationOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitation = ref.watch(callInvitationControllerProvider);
    if (invitation == null) return const SizedBox.shrink();

    return switch (invitation.phase) {
      CallInvitationPhase.incoming => DeviceUtil.isRealDesktop()
          ? const SizedBox.shrink()
          // 1:1 手机端全屏来电；Web 与群呼保留轻量横幅（通知式）
          : (DeviceUtil.isRealMobile() && !invitation.isGroup)
              ? _IncomingCallPage(invitation: invitation)
              : _IncomingCallBanner(invitation: invitation),
      CallInvitationPhase.outgoing => DeviceUtil.isRealDesktop()
          ? const SizedBox.shrink()
          : _OutgoingCallPage(invitation: invitation),
      CallInvitationPhase.acceptedElsewhere => const _CallNoticeCard(
        text: 'call_answered_elsewhere',
      ),
      CallInvitationPhase.rejectedElsewhere => const _CallNoticeCard(
        text: 'call_rejected_elsewhere',
      ),
      CallInvitationPhase.rejected => const _CallNoticeCard(
        text: 'call_rejected_by_peer',
      ),
      CallInvitationPhase.canceled => const _CallNoticeCard(
        text: 'call_invitation_cancelled',
      ),
      CallInvitationPhase.busy => const _CallNoticeCard(text: 'call_peer_busy'),
      CallInvitationPhase.ended => const _CallNoticeCard(text: 'call_ended'),
    };
  }
}

/// 全屏来电页（1:1，手机端）
///
/// 大头像 + 呼叫者名称 + 通话类型，底部提供 拒绝/接听（视频来电附
/// 「以语音方式接听」）。接听后由控制器发送 ACCEPT 并连接媒体。
class _IncomingCallPage extends ConsumerWidget {
  const _IncomingCallPage({required this.invitation});

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

    return ColoredBox(
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
                  AvatarWidget(size: 120, url: avatarUrl, name: displayName),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isVideo ? cs.tertiary : cs.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.surface, width: 2.5),
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
              // 拒绝 / 接听
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CallAction(
                    label: 'notification_call_reject'.tr(),
                    icon: HugeIcons.strokeRoundedCallEnd01,
                    backgroundColor: const Color(0xFFE53945),
                    onPressed: () => controller.reject(invitation),
                  ),
                  const SizedBox(width: 56),
                  _CallAction(
                    label: 'notification_call_accept'.tr(),
                    icon: isVideo
                        ? HugeIcons.strokeRoundedVideo01
                        : HugeIcons.strokeRoundedCall02,
                    backgroundColor: const Color(0xFF22C55E),
                    onPressed: () => controller.acceptAndOpen(invitation),
                  ),
                ],
              ),
              // 视频来电：以语音方式接听
              if (isVideo) ...[
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => controller.acceptAndOpen(
                    invitation,
                    media: CallInitialMedia.audio,
                  ),
                  child: Text(
                    'call_answer_as_voice'.tr(),
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                  ),
                ),
              ],
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

/// 全屏呼出振铃页（1:1，手机/Web）
///
/// 大头像 + 对方名称 + 「正在呼叫…」，底部提供 免提切换 与 挂断（取消呼叫）。
/// 振铃期不连接媒体，收到 CALL_ACCEPT 后由控制器启动通话会话。
class _OutgoingCallPage extends ConsumerWidget {
  const _OutgoingCallPage({required this.invitation});

  final CallInvitationState invitation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final gradient = Theme.of(context).extension<AppColors>()?.scaffoldGradient;
    final room = ref.watch(currentRoomProvider(invitation.roomId));
    final displayName = room?.roomName ?? invitation.title;
    final avatarUrl = room?.roomAvatar ?? invitation.roomAvatar;
    final speakerOn = ref.watch(
      callSpeakerPreferenceProvider(invitation.roomId),
    );
    final controller = ref.read(callInvitationControllerProvider.notifier);

    return ColoredBox(
      color: gradient?.colors.first ?? cs.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),
              AvatarWidget(size: 120, url: avatarUrl, name: displayName),
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
                'call_calling'.tr(),
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
              ),
              const Spacer(flex: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CallAction(
                    label: speakerOn
                        ? 'call_switch_to_earpiece'.tr()
                        : 'call_switch_to_speaker'.tr(),
                    icon: speakerOn
                        ? HugeIcons.strokeRoundedVolumeUp
                        : HugeIcons.strokeRoundedEar,
                    backgroundColor: cs.surfaceContainerHighest,
                    foregroundColor: cs.onSurfaceVariant,
                    onPressed: () {
                      ref
                          .read(
                            callSpeakerPreferenceProvider(invitation.roomId)
                                .notifier,
                          )
                          .state = !speakerOn;
                    },
                  ),
                  const SizedBox(width: 56),
                  _CallAction(
                    label: 'call_cancel_call'.tr(),
                    icon: HugeIcons.strokeRoundedCallEnd01,
                    backgroundColor: const Color(0xFFE53945),
                    onPressed: () => controller.cancelCurrent(),
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

/// 全屏页面上的大号圆形动作按钮（带下方文字标签）
class _CallAction extends StatelessWidget {
  const _CallAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final List<List<dynamic>> icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: backgroundColor ?? cs.primary,
          shape: const CircleBorder(),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: 68,
              child: HugeIcon(
                icon: icon,
                size: 28,
                color: foregroundColor ?? Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
        ),
      ],
    );
  }
}

/// 顶部来电横幅
///
/// 非遮挡式：仅横幅区域拦截触摸，其余区域透传给下层界面。
/// 展示来电者头像、名称和通话类型，并提供接听/拒绝按钮。
/// 群呼横幅是「通知式」：按钮为 忽略/加入（加入式直连，不发 ACCEPT 信令）。
class _IncomingCallBanner extends ConsumerWidget {
  const _IncomingCallBanner({required this.invitation});

  final CallInvitationState invitation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isGroup = invitation.isGroup;
    final mediaLabel = invitation.initialMedia.value == 'video'
        ? 'call_invite_video_title'.tr()
        : 'call_invite_audio_title'.tr();

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Material(
            color: cs.surface,
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      AvatarWidget(
                        size: 48,
                        url: isGroup && invitation.roomAvatar.isNotEmpty
                            ? invitation.roomAvatar
                            : invitation.callerAvatar,
                        name: isGroup
                            ? invitation.title
                            : invitation.callerName.isEmpty
                            ? invitation.title
                            : invitation.callerName,
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: invitation.initialMedia.value == 'video'
                              ? cs.tertiary
                              : cs.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.surface, width: 2),
                        ),
                        child: HugeIcon(
                          icon: invitation.initialMedia.value == 'video'
                              ? HugeIcons.strokeRoundedVideo01
                              : HugeIcons.strokeRoundedCall02,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          invitation.callerName.isEmpty
                              ? invitation.title
                              : invitation.callerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mediaLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RoundActionButton(
                    tooltip: isGroup
                        ? 'call_ignore'.tr()
                        : 'notification_call_reject'.tr(),
                    backgroundColor: const Color(0xFFE53945),
                    icon: isGroup
                        ? HugeIcons.strokeRoundedCancel01
                        : HugeIcons.strokeRoundedCallEnd01,
                    onPressed: () {
                      final controller = ref
                          .read(callInvitationControllerProvider.notifier);
                      if (isGroup) {
                        controller.dismissInvitation();
                      } else {
                        controller.reject(invitation);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _RoundActionButton(
                    tooltip: isGroup
                        ? 'call_join_call'.tr()
                        : 'notification_call_accept'.tr(),
                    backgroundColor: cs.primary,
                    icon: isGroup
                        ? HugeIcons.strokeRoundedCallAdd
                        : HugeIcons.strokeRoundedCall02,
                    onPressed: () async {
                      final controller = ref
                          .read(callInvitationControllerProvider.notifier);
                      if (isGroup) {
                        await controller.joinGroupCall(invitation);
                      } else {
                        await controller.acceptAndOpen(invitation);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 来电横幅上的圆形动作按钮
class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    required this.tooltip,
    required this.backgroundColor,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final Color backgroundColor;
  final List<List<dynamic>> icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 44,
            child: HugeIcon(icon: icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// 通话通知提示卡片
///
/// 在通话被其他地方接听/拒绝、邀请取消、对方忙线、通话结束等场景下，
/// 显示简短的通知文本。
class _CallNoticeCard extends StatelessWidget {
  const _CallNoticeCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.inverseSurface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 16,
                  offset: Offset(0, 8),
                  color: Color(0x26000000),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Text(text.tr(), style: TextStyle(color: cs.onInverseSurface)),
            ),
          ),
        ),
      ),
    );
  }
}
