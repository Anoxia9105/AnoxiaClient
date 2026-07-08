import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
import 'package:anoxia/framework/provider/chat/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

class CallInvitationOverlay extends ConsumerWidget {
  const CallInvitationOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitation = ref.watch(callInvitationControllerProvider);
    if (invitation == null) return const SizedBox.shrink();

    return switch (invitation.phase) {
      CallInvitationPhase.incoming => _IncomingCallCard(invitation: invitation),
      CallInvitationPhase.acceptedElsewhere => const _CallNoticeCard(
        text: '已在其他设备接听',
      ),
      CallInvitationPhase.rejectedElsewhere => const _CallNoticeCard(
        text: '已在其他设备拒绝',
      ),
      CallInvitationPhase.canceled => const _CallNoticeCard(text: '通话邀请已取消'),
      CallInvitationPhase.busy => const _CallNoticeCard(text: '对方忙线中'),
      CallInvitationPhase.ended => const _CallNoticeCard(text: '通话已结束'),
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
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(18),
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
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedCall02,
                    size: 30,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  invitation.title.isEmpty ? '通话邀请' : invitation.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  '邀请你加入通话',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 22),
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
                        label: const Text('拒绝'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          await ref
                              .read(callInvitationControllerProvider.notifier)
                              .accept(invitation);
                          await _openCall(ref, invitation);
                        },
                        icon: const Icon(Icons.call),
                        label: const Text('接听'),
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

  Future<void> _openCall(
    WidgetRef ref,
    CallInvitationState invitation,
  ) async {
    if (DeviceUtil.isRealMobile()) {
      ref
          .read(mobileCallSessionControllerProvider.notifier)
          .start(roomId: invitation.roomId, title: invitation.title);
      return;
    }

    await ref
        .read(callWindowControllerProvider.notifier)
        .openCallWindow(
          title: invitation.title,
          themeIndex: ref.read(themeIndexProvider),
          roomId: invitation.roomId,
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
              child: Text(
                text,
                style: TextStyle(color: cs.onInverseSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
