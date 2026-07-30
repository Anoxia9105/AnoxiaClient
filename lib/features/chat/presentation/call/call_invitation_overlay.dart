import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CallInvitationOverlay extends ConsumerWidget {
  const CallInvitationOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitation = ref.watch(callInvitationControllerProvider);
    if (invitation == null) return const SizedBox.shrink();

    return switch (invitation.phase) {
      CallInvitationPhase.incoming => _IncomingCallCard(invitation: invitation),
      CallInvitationPhase.acceptedElsewhere => const _CallNoticeCard(
        text: 'call_answered_elsewhere',
      ),
      CallInvitationPhase.rejectedElsewhere => const _CallNoticeCard(
        text: 'call_rejected_elsewhere',
      ),
      CallInvitationPhase.canceled => const _CallNoticeCard(text: 'call_invitation_cancelled'),
      CallInvitationPhase.busy => const _CallNoticeCard(text: 'call_peer_busy'),
      CallInvitationPhase.ended => const _CallNoticeCard(text: 'call_ended'),
      CallInvitationPhase.outgoing => const SizedBox.shrink(),
    };
  }
}

class _IncomingCallCard extends ConsumerWidget {
  const _IncomingCallCard({required this.invitation});

  final CallInvitationState invitation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 30,
                  offset: Offset(0, 16),
                  color: Color(0x33000000),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    AvatarWidget(
                      size: 84,
                      url:
                          invitation.isGroup && invitation.roomAvatar.isNotEmpty
                          ? invitation.roomAvatar
                          : invitation.callerAvatar,
                      name: invitation.isGroup
                          ? invitation.title
                          : invitation.callerName.isEmpty
                          ? invitation.title
                          : invitation.callerName,
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: invitation.initialMedia.value == 'video'
                            ? cs.tertiary
                            : cs.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.surface, width: 3),
                      ),
                      child: Icon(
                        invitation.initialMedia.value == 'video'
                            ? Icons.videocam_rounded
                            : Icons.call_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  invitation.callerName.isEmpty
                      ? invitation.title
                      : invitation.callerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  invitation.initialMedia.value == 'video'
                      ? 'call_invite_video_title'.tr()
                      : 'call_invite_audio_title'.tr(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          ref
                              .read(callInvitationControllerProvider.notifier)
                              .reject(invitation);
                        },
                        icon: const Icon(Icons.call_end),
                        label: Text('notification_call_reject'.tr()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          await ref
                              .read(callInvitationControllerProvider.notifier)
                              .acceptAndOpen(invitation);
                        },
                        icon: const Icon(Icons.call),
                        label: Text('notification_call_accept'.tr()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
