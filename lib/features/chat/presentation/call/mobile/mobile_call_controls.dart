// 移动端通话控制栏组件，提供通话中的麦克风、扬声器、摄像头、挂断等控制按钮。
//
// 支持音频通话和视频通话两种模式，群组通话中额外显示邀请成员按钮。
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/domain/room_state.dart';
import 'package:anoxia/framework/theme/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
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
import 'package:anoxia/framework/theme/radius_token.dart';

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
    this.compact = false,
  });

  /// 当前房间状态
  final RoomState state;

  /// 房间 ID
  final String roomId;

  /// 通话标题
  final String title;

  /// 是否为视频通话
  final bool isVideoCall;

  /// 是否使用紧凑布局（手机 Web 横屏等矮屏场景）
  ///
  /// 紧凑模式下通话计时器并入按钮同一行，减少垂直占用，把高度让给画面。
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>();
    final notifier = ref.read(roomControllerProvider(state.token).notifier);
    final isGroup = ref.watch(callIsGroupProvider(roomId));
    final screenWidth = MediaQuery.sizeOf(context).width;

    final timerChip = _CallTimerChip(joinedAt: state.joinedAt);

    final actions = <Widget>[
      _CallControlButton(
        tooltip: state.micEnabled ? 'call_mic_mute'.tr() : 'call_mic_unmute'.tr(),
        icon: state.micEnabled ? HugeIcons.strokeRoundedMic01 : HugeIcons.strokeRoundedMicOff01,
        active: state.micEnabled,
        onPressed: notifier.toggleMic,
      ),
      // 听筒/扬声器切换仅真机有意义（Web/桌面由系统输出设备决定）
      if (DeviceUtil.isRealMobile()) ...[
        const SizedBox(width: 7),
        _CallControlButton(
          tooltip: state.speakerOn ? 'call_switch_to_earpiece'.tr() : 'call_switch_to_speaker'.tr(),
          icon: state.speakerOn
              ? HugeIcons.strokeRoundedVolumeUp
              : HugeIcons.strokeRoundedEar,
          active: state.speakerOn,
          onPressed: notifier.toggleSpeaker,
        ),
      ],
      if (isVideoCall) ...[
        const SizedBox(width: 7),
        _CallControlButton(
          tooltip: state.cameraEnabled ? 'call_camera_off'.tr() : 'call_camera_on'.tr(),
          icon: state.cameraEnabled
              ? HugeIcons.strokeRoundedVideo01
              : HugeIcons.strokeRoundedVideoOff,
          active: state.cameraEnabled,
          onPressed: notifier.toggleCamera,
        ),
        const SizedBox(width: 7),
        _CallControlButton(
          tooltip: 'call_switch_camera_tooltip'.tr(),
          icon: HugeIcons.strokeRoundedCameraRotated01,
          active: false,
          enabled: state.cameraEnabled,
          onPressed: notifier.switchCamera,
        ),
      ],
      if (isGroup) ...[
        const SizedBox(width: 7),
        CallInviteMembersButton(state: state),
      ],
      const SizedBox(width: 7),
      _CallControlButton(
        tooltip: 'call_hangup_tooltip'.tr(),
        icon: HugeIcons.strokeRoundedCallEnd01,
        backgroundColor: appColors?.danger ?? const Color(0xFFE53945),
        foregroundColor: Colors.white,
        onPressed: () => _hangUp(ref, notifier),
      ),
    ];

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[timerChip, const SizedBox(height: 11)],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(RadiusToken.xl),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.6),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 26,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (compact) ...[timerChip, const SizedBox(width: 8)],
                ConstrainedBox(
                  // 给横滑区一个有界宽度，否则 Row 内无法计算滚动范围
                  constraints: BoxConstraints(
                    maxWidth: (screenWidth - (compact ? 176 : 56)).clamp(
                      120.0,
                      screenWidth,
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: actions,
                    ),
                  ),
                ),
              ],
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

/// 通话计时器胶囊
///
/// 紧凑布局（手机 Web 横屏等矮屏）时与按钮同一行展示，节省垂直空间。
class _CallTimerChip extends StatelessWidget {
  const _CallTimerChip({required this.joinedAt});

  /// 加入房间的时间点
  final DateTime? joinedAt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(RadiusToken.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: MobileCallTimer(
          joinedAt: joinedAt,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
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
  final List<List<dynamic>> icon;

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
    final cs = Theme.of(context).colorScheme;
    final scale = (MediaQuery.sizeOf(context).width / 375)
        .clamp(0.9, 1.1)
        .toDouble();
    final dim = (44 * scale).clamp(40.0, 48.0).toDouble();
    final resolvedBackground =
        backgroundColor ??
        (active ? cs.primary : cs.surfaceContainerHighest);
    final resolvedForeground =
        foregroundColor ?? (active ? cs.onPrimary : cs.onSurfaceVariant);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: enabled
              ? resolvedBackground
              : cs.surfaceContainerHighest.withValues(alpha: 0.5),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? () => onPressed() : null,
            child: SizedBox.square(
              dimension: dim,
              child: Center(
                child: SizedBox(
                  width: dim * 0.38,
                  height: dim * 0.38,
                  child: HugeIcon(
                    icon: icon,
                    color: enabled
                        ? resolvedForeground
                        : cs.onSurface.withValues(alpha: 0.3),
                    size: dim * 0.38,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
