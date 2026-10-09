import 'package:anoxia/common/constants/call_window_sizes.dart';
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
  const CallAction({
    super.key,
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
        Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
      ],
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
            gradient: Theme.of(
              context,
            ).extension<AppColors>()?.scaffoldGradient,
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
              child: Text(
                text.tr(),
                style: TextStyle(color: cs.onInverseSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
