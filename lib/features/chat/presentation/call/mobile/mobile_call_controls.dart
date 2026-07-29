import 'package:anoxia/framework/domain/RoomState.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pip/pip.dart';

import 'mobile_call_timer.dart';
import '../component/call_invite_members_button.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';

class MobileCallControls extends ConsumerWidget {
  const MobileCallControls({
    super.key,
    required this.state,
    required this.roomId,
    required this.title,
    required this.isVideoCall,
  });

  final RoomState state;
  final String roomId;
  final String title;
  final bool isVideoCall;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(roomControllerProvider(state.token).notifier);
    final isGroup = ref.watch(callIsGroupProvider(roomId));
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: MobileCallTimer(joinedAt: state.joinedAt),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xE620222A),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 26,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                _CallControlButton(
                  tooltip: state.micEnabled ? '麦克风静音' : '开启麦克风',
                  icon: state.micEnabled ? Icons.mic : Icons.mic_off,
                  active: state.micEnabled,
                  onPressed: notifier.toggleMic,
                ),
                const SizedBox(width: 10),
                _CallControlButton(
                  tooltip: state.speakerOn ? '切换到听筒' : '切换到扬声器',
                  icon: state.speakerOn
                      ? Icons.volume_up_rounded
                      : Icons.hearing_rounded,
                  active: state.speakerOn,
                  onPressed: notifier.toggleSpeaker,
                ),
                if (isVideoCall) ...[
                  const SizedBox(width: 10),
                  _CallControlButton(
                    tooltip: state.cameraEnabled ? '关闭摄像头' : '开启摄像头',
                    icon: state.cameraEnabled
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    active: state.cameraEnabled,
                    onPressed: notifier.toggleCamera,
                  ),
                  const SizedBox(width: 10),
                  _CallControlButton(
                    tooltip: 'call_switch_camera_tooltip'.tr(),
                    icon: Icons.cameraswitch_rounded,
                    active: false,
                    enabled: state.cameraEnabled,
                    onPressed: notifier.switchCamera,
                  ),
                ],
                if (isGroup) ...[
                  const SizedBox(width: 10),
                  CallInviteMembersButton(state: state),
                ],
                const SizedBox(width: 10),
                _CallControlButton(
                  tooltip: 'call_hangup_tooltip'.tr(),
                  icon: Icons.call_end_rounded,
                  backgroundColor: const Color(0xFFE53945),
                  foregroundColor: Colors.white,
                  onPressed: () => _hangUp(ref, notifier),
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _hangUp(WidgetRef ref, RoomController notifier) async {
    try {
      await Pip().dispose();
    } catch (_) {}
    await ref
        .read(callInvitationControllerProvider.notifier)
        .endRoom(roomId, title: title);
    ref.read(mobileCallSessionControllerProvider.notifier).end();
    await notifier.leave();
  }
}

class _CallControlButton extends StatelessWidget {
  const _CallControlButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.active = false,
    this.enabled = true,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String tooltip;
  final IconData icon;
  final Future<void> Function() onPressed;
  final bool active;
  final bool enabled;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final resolvedBackground =
        backgroundColor ??
        (active ? Colors.white : Colors.white.withValues(alpha: 0.12));
    final resolvedForeground =
        foregroundColor ?? (active ? const Color(0xFF15171D) : Colors.white);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: enabled ? resolvedBackground : Colors.white10,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? () => onPressed() : null,
            child: SizedBox.square(
              dimension: 52,
              child: Icon(
                icon,
                color: enabled ? resolvedForeground : Colors.white30,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
