import 'package:anoxia/framework/domain/RoomState.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../framework/provider/kit/room_controller.dart';

class CommandBar extends ConsumerWidget {
  final RoomState state;
  final VoidCallback? onToggleChat;
  final bool showChat;

  const CommandBar({
    super.key,
    required this.state,
    this.onToggleChat,
    this.showChat = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(roomControllerProvider(state.token).notifier);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 会议计时器：基于 RoomState.joinedAt 进行本地计时
          MeetingTimer(joinedAt: state.joinedAt),

          Spacer(),
          
          // 📹 录音状态指示
          if (state.isRecording)
            Tooltip(
              message: context.tr('call_recording_tooltip'),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.red,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 红色闪烁指示点
                      _buildRecordingDot(),
                      SizedBox(width: 8),
                      Text(
                        context.tr('call_recording_indicator'),
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 核心控制按钮组
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 麦克风控制
              _buildActionButton(
                onPressed: () => notifier.toggleMic(),
                icon: state.micEnabled
                    ? HugeIcons.strokeRoundedMic01
                    : HugeIcons.strokeRoundedMicOff01,
                label: state.micEnabled ? "call_mute".tr() : "call_unmute".tr(),
              ),
              SizedBox(width: 8),

              // 摄像头控制
              _buildActionButton(
                onPressed: () => notifier.toggleCamera(),
                icon: state.cameraEnabled
                    ? HugeIcons.strokeRoundedVideo01
                    : HugeIcons.strokeRoundedVideoOff,
                label: "call_camera".tr(),
              ),

              SizedBox(width: 8),
              // 扬声器控制
              _buildActionButton(
                onPressed: () => notifier.toggleSpeaker(),
                icon: state.speakerOn
                    ? HugeIcons.strokeRoundedVolumeUp
                    : HugeIcons.strokeRoundedVolumeOff,
                label: state.speakerOn ? "call_speaker".tr() : "call_earpiece".tr(),
              ),

              SizedBox(width: 8),
              // 屏幕共享
              _buildActionButton(
                onPressed: () => notifier.toggleScreenShare(context),
                icon: state.screenSharing
                    ? HugeIcons.strokeRoundedComputerRemove
                    : HugeIcons.strokeRoundedComputerScreenShare,
                label: "call_share".tr(),
              ),

              SizedBox(width: 8),
              // 聊天开关
              if (onToggleChat != null)
                _buildActionButton(
                  onPressed: onToggleChat!,
                  icon: showChat
                      ? HugeIcons.strokeRoundedCancel01
                      : HugeIcons.strokeRoundedChatting01,
                  label: "call_chat".tr(),
                  isActive: showChat,
                ),

              SizedBox(width: 8),
              // 设备选择菜单
              _buildDeviceMenu(context, ref, notifier),

              SizedBox(width: 8),
              // 挂断按钮
              _buildHangupButton(context, notifier),
            ],
          ),
        ],
      ),
    );
  }

  /// 设备选择下拉菜单
  Widget _buildDeviceMenu(
    BuildContext context,
    WidgetRef ref,
    RoomController notifier,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupMenuButton<String>(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedSettings04, size: 20),
          tooltip: "call_device_select".tr(),
          padding: EdgeInsets.all(8),
          iconSize: 24,
          constraints: BoxConstraints(minWidth: 40, minHeight: 40),
          itemBuilder: (context) {
            return [
              // 麦克风选择
              if (state.audioInputs.isNotEmpty)
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    "call_microphone".tr(),
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                ),
              ...state.audioInputs.map(
                (device) => PopupMenuItem(
                  value: "mic_${device.deviceId}",
                  child: Row(
                    children: [
                      if (state.currentAudioInput?.deviceId == device.deviceId)
                        const Icon(Icons.check, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          device.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => notifier.switchAudioInput(device),
                ),
              ),

              const PopupMenuDivider(),

              // 摄像头选择
              if (state.videoInputs.isNotEmpty)
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    "call_camera".tr(),
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                ),
              ...state.videoInputs.map(
                (device) => PopupMenuItem(
                  value: "cam_${device.deviceId}",
                  child: Row(
                    children: [
                      if (state.currentVideoInput?.deviceId == device.deviceId)
                        const Icon(Icons.check, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          device.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => notifier.switchVideoInput(device),
                ),
              ),

              const PopupMenuDivider(),

              // 扬声器选择
              if (state.audioOutputs.isNotEmpty)
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    "call_speaker".tr(),
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                ),
              ...state.audioOutputs.map(
                (device) => PopupMenuItem(
                  value: "speaker_${device.deviceId}",
                  child: Row(
                    children: [
                      if (state.currentAudioOutput?.deviceId == device.deviceId)
                        const Icon(Icons.check, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          device.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => notifier.switchAudioOutput(device),
                ),
              ),
            ];
          },
        ),
        Text("call_device_label".tr(), style: TextStyle(fontSize: 10)),
      ],
    );
  }

  /// 构建功能按钮
  Widget _buildActionButton({
    required VoidCallback onPressed,
    required List<List<dynamic>> icon,
    required String label,
    bool isActive = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Builder(
          builder: (btnContext) => IconButton(
            tooltip: label,
            onPressed: onPressed,
            icon: HugeIcon(
              icon: icon, 
              size: 20,
              color: isActive ? Theme.of(btnContext).colorScheme.primary : null,
            ),
            iconSize: 24,
            padding: EdgeInsets.all(8),
            constraints: BoxConstraints(minWidth: 40, minHeight: 40),
            style: isActive ? IconButton.styleFrom(
              backgroundColor: Theme.of(btnContext).colorScheme.primaryContainer,
            ) : null,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 10)),
      ],
    );
  }

  /// 构建挂断按钮
  Widget _buildHangupButton(BuildContext context, RoomController notifier) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: "call_hangup".tr(),
          onPressed: () async {
            await notifier.leave();
            if (context.mounted) {
              await windowManager.close();
            }
          },
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedCallRinging03,
            size: 24,
            color: Colors.redAccent,
            strokeWidth: 2,
          ),
          iconSize: 24,
        ),
        Text('call_window_hang_up'.tr(), style: TextStyle(fontSize: 10)),
      ],
    );
  }

  /// 构建闪烁的录音指示点
  Widget _buildRecordingDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 1000),
      onEnd: () {},
      builder: (context, value, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Color.lerp(Colors.red, Colors.red.withValues(alpha: 0.4), value)!,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

/// 显示会议已进行时长（本地计算）。
/// 使用 StatefulWidget 并在每秒刷新，显示格式为 mm:ss 或 hh:mm:ss。
class MeetingTimer extends StatefulWidget {
  final DateTime? joinedAt;
  const MeetingTimer({super.key, required this.joinedAt});

  @override
  State<MeetingTimer> createState() => _MeetingTimerState();
}

class _MeetingTimerState extends State<MeetingTimer> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.joinedAt != null) {
      _elapsed = DateTime.now().difference(widget.joinedAt!);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _elapsed = DateTime.now().difference(widget.joinedAt!);
        });
      });
    }
  }

  @override
  void didUpdateWidget(covariant MeetingTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.joinedAt != widget.joinedAt) {
      _timer?.cancel();
      if (widget.joinedAt != null) {
        _elapsed = DateTime.now().difference(widget.joinedAt!);
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() {
            _elapsed = DateTime.now().difference(widget.joinedAt!);
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // 即使 joinedAt 为空，也显示占位，便于在 UI 上直观看到计时器区域。
    if (widget.joinedAt == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '--:--',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text('call_elapsed'.tr(), style: const TextStyle(fontSize: 10)),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_fmt(_elapsed), style: const TextStyle(fontSize: 12)),
        Text('call_elapsed'.tr(), style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
