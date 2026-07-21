import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
import 'package:anoxia/framework/provider/chat/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:anoxia/framework/provider/theme/theme_controller.dart';
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
                      url: invitation.callerAvatar,
                      name: invitation.callerName.isEmpty
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
                      ? '邀请你进行视频通话'
                      : '邀请你进行语音通话',
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

  Future<void> _openCall(WidgetRef ref, CallInvitationState invitation) async {
    if (DeviceUtil.isRealMobile()) {
      ref
          .read(mobileCallSessionControllerProvider.notifier)
          .start(
            roomId: invitation.roomId,
            title: invitation.title,
            initialMedia: invitation.initialMedia,
          );
      return;
    }

    await ref
        .read(callWindowControllerProvider.notifier)
        .openCallWindow(
          title: invitation.title,
          themeIndex: ref.read(themeIndexProvider),
          roomId: invitation.roomId,
          initialMedia: invitation.initialMedia,
          isGroup: invitation.isGroup,
          token: await ref.read(roomTokenProvider(invitation.roomId).future),
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
              child: Text(text, style: TextStyle(color: cs.onInverseSurface)),
            ),
          ),
        ),
      ),
    );
  }
}
