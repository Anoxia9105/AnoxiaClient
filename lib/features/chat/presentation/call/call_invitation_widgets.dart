import 'package:anoxia/common/constants/call_window_sizes.dart';
import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:anoxia/framework/theme/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
/// 全屏页面上的大号圆形动作按钮（带下方文字标签）
class CallAction extends StatelessWidget {
  const CallAction({super.key, 
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
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: HugeIcon(
                    icon: icon,
                    size: 22,
                    color: foregroundColor ?? Colors.white,
                  ),
                ),
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

/// 来电通知卡片
///
/// 非遮挡式：仅卡片区域拦截触摸，其余区域透传给下层界面。
/// 展示来电者头像、名称和通话类型，并提供接听/拒绝按钮。
/// 真实桌面 + Web PC 宽屏停在右上角（[alignTopRight]），
/// 真实手机 + Web 移动窄屏与移动端群呼停顶部居中；
/// 群呼卡片是「通知式」：按钮为 忽略/加入（加入式直连，不发 ACCEPT 信令）。
class IncomingCallBanner extends ConsumerWidget {
  const IncomingCallBanner({super.key, 
    required this.invitation,
    this.alignTopRight = false,
  });

  final CallInvitationState invitation;

  /// 是否为桌面/Web 的右上角卡片样式（内容自适应、限宽）。
  final bool alignTopRight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>();
    final isGroup = invitation.isGroup;
    final mediaLabel = invitation.initialMedia.value == 'video'
        ? 'call_invite_video_title'.tr()
        : 'call_invite_audio_title'.tr();

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: alignTopRight ? Alignment.topRight : Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Material(
            color: cs.surface,
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(RadiusToken.xl),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize:
                    alignTopRight ? MainAxisSize.min : MainAxisSize.max,
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
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: alignTopRight ? 200 : double.infinity,
                      ),
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
                  ),
                  const SizedBox(width: 8),
                  RoundActionButton(
                    tooltip: isGroup
                        ? 'call_ignore'.tr()
                        : 'notification_call_reject'.tr(),
                    backgroundColor: appColors?.danger ?? const Color(0xFFE53945),
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
                  RoundActionButton(
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

/// 来电通知卡片上的圆形动作按钮
class RoundActionButton extends StatelessWidget {
  const RoundActionButton({super.key, 
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
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: HugeIcon(icon: icon, size: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 通话邀请悬浮窗（最小化态）
///
/// 可拖拽并吸附屏幕边缘，点击恢复全屏邀请页。
/// 尺寸与音频通话悬浮窗一致（150×56），振铃期无媒体画面，仅图标+名称+状态。
class MinimizedInvitationBubble extends ConsumerWidget {
  const MinimizedInvitationBubble({super.key, required this.invitation});

  final CallInvitationState invitation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isVideo = invitation.initialMedia == CallInitialMedia.video;
    final displayName = invitation.callerName.isEmpty
        ? invitation.title
        : invitation.callerName;
    final statusText = invitation.phase == CallInvitationPhase.incoming
        ? 'call_incoming'.tr()
        : 'call_calling'.tr();

    return GestureDetector(
      onPanUpdate: (details) {
        ref
            .read(callInvitationControllerProvider.notifier)
            .updateInvitationPosition(
              details.delta,
              MediaQuery.sizeOf(context).width,
              MediaQuery.sizeOf(context).height,
            );
      },
      onPanEnd: (_) {
        ref
            .read(callInvitationControllerProvider.notifier)
            .snapInvitationToEdge(MediaQuery.sizeOf(context).width);
      },
      onTap: () {
        ref.read(callInvitationControllerProvider.notifier).restoreInvitation();
      },
      child: Material(
        elevation: 10,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(RadiusToken.xl),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: CallWindowSizes.audioWidth,
          height: CallWindowSizes.audioHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: Theme.of(context).extension<AppColors>()?.scaffoldGradient,
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(RadiusToken.xl),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primary.withValues(alpha: 0.12),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: isVideo
                        ? HugeIcons.strokeRoundedVideo01
                        : HugeIcons.strokeRoundedCall02,
                    color: cs.primary,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
class CallNoticeCard extends StatelessWidget {
  const CallNoticeCard({super.key, required this.text});

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
              borderRadius: BorderRadius.circular(RadiusToken.lg),
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
