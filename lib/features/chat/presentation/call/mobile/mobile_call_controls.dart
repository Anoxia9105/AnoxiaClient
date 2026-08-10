// 移动端通话控制栏组件，提供通话中的麦克风、扬声器、摄像头、挂断等控制按钮。
//
// 支持音频通话和视频通话两种模式，群组通话中额外显示邀请成员按钮。
import 'package:anoxia/framework/domain/room_state.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anoxia/platform/shims/pip_shim.dart';

import 'mobile_call_timer.dart';
import '../component/call_invite_members_button.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';

/// 移动端通话控制栏
///
/// 包含通话计时器、麦克风开关、扬声器切换、摄像头开关、前后摄像头切换、
/// 邀请成员以及挂断按钮。支持画中画模式下处理挂断逻辑。
class MobileCallControls extends ConsumerWidget {
  const MobileCallControls({
    super.key,
    required this.state,
    required this.roomId,
    required this.title,
    required this.isVideoCall,
  });

  /// 当前房间状态
  final RoomState state;

  /// 房间 ID
  final String roomId;

  /// 通话标题
  final String title;

  /// 是否为视频通话
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
                  tooltip: state.micEnabled ? 'call_mic_mute'.tr() : 'call_mic_unmute'.tr(),
                  icon: state.micEnabled ? Icons.mic : Icons.mic_off,
                  active: state.micEnabled,
                  onPressed: notifier.toggleMic,
                ),
                const SizedBox(width: 10),
                _CallControlButton(
                  tooltip: state.speakerOn ? 'call_switch_to_earpiece'.tr() : 'call_switch_to_speaker'.tr(),
                  icon: state.speakerOn
                      ? Icons.volume_up_rounded
                      : Icons.hearing_rounded,
                  active: state.speakerOn,
                  onPressed: notifier.toggleSpeaker,
                ),
                if (isVideoCall) ...[
                  const SizedBox(width: 10),
                  _CallControlButton(
                    tooltip: state.cameraEnabled ? 'call_camera_off'.tr() : 'call_camera_on'.tr(),
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

/// 通话控制按钮
///
/// 圆形按钮，支持激活/非激活状态样式切换，带 Tooltip 和语义标签。
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

  /// 按钮提示文本
  final String tooltip;

  /// 按钮图标
  final IconData icon;

  /// 点击回调
  final Future<void> Function() onPressed;

  /// 是否处于激活状态
  final bool active;

  /// 是否可用
  final bool enabled;

  /// 背景颜色
  final Color? backgroundColor;

  /// 前景颜色
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
