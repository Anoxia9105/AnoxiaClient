import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 来电卡片位于标题栏下方，私聊突出提醒，群聊保持非阻塞邀请。
class IncomingCallPrompt extends ConsumerWidget {
  const IncomingCallPrompt({super.key, required this.invitation});
  final CallInvitationState invitation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(callInvitationControllerProvider.notifier);
    return IncomingCallCard(
      key: ValueKey(invitation.inviteId),
      invitation: invitation,
      titleBarInset: DeviceUtil.isRealDesktop() ? kToolbarHeight : 0,
      onReject: () async {
        if (invitation.isGroup) {
          controller.dismissInvitation();
        } else {
          await controller.reject(invitation);
        }
      },
      onAccept: (media) => invitation.isGroup
          ? controller.joinGroupCall(invitation)
          : controller.acceptAndOpen(invitation, media: media),
    );
  }
}

/// 纯展示与交互组件，独立验证窗口适配和异步操作状态。
class IncomingCallCard extends StatefulWidget {
  const IncomingCallCard({
    super.key,
    required this.invitation,
    required this.onReject,
    required this.onAccept,
    this.titleBarInset = 0,
  });
  final CallInvitationState invitation;
  final double titleBarInset;
  final Future<void> Function() onReject;
  final Future<void> Function(CallInitialMedia) onAccept;

  @override
  State<IncomingCallCard> createState() => _IncomingCallCardState();
}

class _IncomingCallCardState extends State<IncomingCallCard> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _act(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invite = widget.invitation;
    final colors = Theme.of(context).colorScheme;
    final isVideo = invite.initialMedia == CallInitialMedia.video;
    final name = invite.isGroup
        ? invite.title
        : (invite.callerName.trim().isEmpty ? invite.title : invite.callerName);
    final mediaLabel = (isVideo ? 'call_media_video' : 'call_media_audio').tr();
    return Padding(
      padding: EdgeInsets.only(top: widget.titleBarInset),
      child: Stack(
        children: [
          if (!invite.isGroup)
            Positioned.fill(
              child: ModalBarrier(
                key: const ValueKey('incoming-call-backdrop'),
                dismissible: false,
                color: Colors.black.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.48
                      : 0.24,
                ),
              ),
            ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Align(
                  alignment: invite.isGroup
                      ? Alignment.topCenter
                      : Alignment.center,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: FocusScope(
                        autofocus: !invite.isGroup,
                        child: Semantics(
                          explicitChildNodes: true,
                          scopesRoute: true,
                          namesRoute: true,
                          label: 'call_incoming'.tr(),
                          liveRegion: true,
                          child: Material(
                            key: const ValueKey('incoming-call-card'),
                            color: colors.surfaceContainerHigh,
                            elevation: 24,
                            shadowColor: Colors.black.withValues(alpha: 0.24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                RadiusToken.xl,
                              ),
                              side: BorderSide(color: colors.outlineVariant),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Semantics(
                                    header: true,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isVideo
                                              ? Icons.videocam_rounded
                                              : Icons.call_rounded,
                                          color: colors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'call_incoming'.tr(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
                                                  color: colors.primary,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  AvatarWidget(
                                    size: 80,
                                    url: invite.isGroup
                                        ? invite.roomAvatar
                                        : invite.callerAvatar,
                                    name: name,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    invite.isGroup
                                        ? 'call_invitation_group_body'.tr(
                                            args: [
                                              invite.callerName,
                                              mediaLabel,
                                            ],
                                          )
                                        : (isVideo
                                                  ? 'call_invite_video_title'
                                                  : 'call_invite_audio_title')
                                              .tr(),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 28),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 304,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: FilledButton.icon(
                                            key: const ValueKey(
                                              'incoming-call-reject',
                                            ),
                                            style: FilledButton.styleFrom(
                                              minimumSize: const Size(0, 44),
                                              backgroundColor: const Color(
                                                0xFFD32F2F,
                                              ),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                            ),
                                            onPressed: _busy
                                                ? null
                                                : () => _act(widget.onReject),
                                            icon: Icon(
                                              invite.isGroup
                                                  ? Icons.close_rounded
                                                  : Icons.call_end_rounded,
                                              size: 20,
                                            ),
                                            label: Text(
                                              (invite.isGroup
                                                      ? 'call_ignore'
                                                      : 'notification_call_reject')
                                                  .tr(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: FilledButton.icon(
                                            key: const ValueKey(
                                              'incoming-call-accept',
                                            ),
                                            style: FilledButton.styleFrom(
                                              minimumSize: const Size(0, 44),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                            ),
                                            onPressed: _busy
                                                ? null
                                                : () => _act(
                                                    () => widget.onAccept(
                                                      invite.initialMedia,
                                                    ),
                                                  ),
                                            icon: _busy
                                                ? const SizedBox.square(
                                                    dimension: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : Icon(
                                                    isVideo
                                                        ? Icons.videocam_rounded
                                                        : Icons.call_rounded,
                                                    size: 20,
                                                  ),
                                            label: Text(
                                              (invite.isGroup
                                                      ? 'call_join_call'
                                                      : 'notification_call_accept')
                                                  .tr(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isVideo && !invite.isGroup) ...[
                                    const SizedBox(height: 12),
                                    TextButton.icon(
                                      onPressed: _busy
                                          ? null
                                          : () => _act(
                                              () => widget.onAccept(
                                                CallInitialMedia.audio,
                                              ),
                                            ),
                                      icon: const Icon(
                                        Icons.call_outlined,
                                        size: 18,
                                      ),
                                      label: Text('call_answer_as_voice'.tr()),
                                    ),
                                  ],
                                  if (_failed) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      'api_request_failed'.tr(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: colors.error),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
