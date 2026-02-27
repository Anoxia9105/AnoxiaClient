import 'package:anoxia/framework/domain/RoomState.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:window_manager/window_manager.dart';

import '../../../framework/provider/kit/room_controller.dart';

class CommandBar extends ConsumerWidget {
  final RoomState state;

  const CommandBar({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(roomControllerProvider(state.token).notifier);
    // 运行时不再打印大量 debug 输出，保留 UI 简洁输出。

    // 重连按钮（仅在重连状态显示）
    Widget reconnectButton = const SizedBox.shrink();
    if (state.isReconnecting) {
      // 当处于自动重连期间，显示一个可点击的重连按钮（手动触发）
      reconnectButton = TextButton.icon(
        onPressed: () => notifier.reconnect(),
        icon: const Icon(Icons.refresh, size: 16),
        label: Text('call_window_reconnect'.tr()),
      );
    }

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

          const SizedBox(width: 16),

          // 核心控制按钮组
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 麦克风控制
                _buildActionButton(
                  onPressed: () => notifier.toggleMic(),
                  icon: state.micEnabled
                      ? HugeIcons.strokeRoundedMic01
                      : HugeIcons.strokeRoundedMicOff01,
                  label: state.micEnabled ? "静音" : "取消静音",
                ),
                SizedBox(width: 16),

                // 摄像头控制
                _buildActionButton(
                  onPressed: () => notifier.toggleCamera(),
                  icon: state.cameraEnabled
                      ? HugeIcons.strokeRoundedVideo01
                      : HugeIcons.strokeRoundedVideoOff,
                  label: "摄像头",
                ),
                SizedBox(width: 16),

                // 扬声器控制
                _buildActionButton(
                  onPressed: () => notifier.toggleSpeaker(),
                  icon: state.speakerOn
                      ? HugeIcons.strokeRoundedVolumeUp
                      : HugeIcons.strokeRoundedVolumeOff,
                  label: state.speakerOn ? "扬声器" : "听筒",
                ),
                SizedBox(width: 16),

                // 屏幕共享
                _buildActionButton(
                  onPressed: () => notifier.toggleScreenShare(context),
                  icon: state.screenSharing
                      ? HugeIcons.strokeRoundedComputerRemove
                      : HugeIcons.strokeRoundedComputerScreenShare,
                  label: "共享",
                ),
                // 设备选择菜单
                _buildDeviceMenu(context, ref, notifier),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // 右侧区域：显示会议时长、网络状态，并包含重连/挂断按钮
          Row(
            children: [
              const SizedBox(width: 12),
              // 本地网络质量指示：读取 state.participantQuality/participantRttMs
              NetworkStatusIndicator(state: state),
              const SizedBox(width: 12),

              reconnectButton,
              if (state.isReconnecting) SizedBox(width: 8),

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
    return PopupMenuButton<String>(
      icon: HugeIcon(icon: HugeIcons.strokeRoundedBoundingBox),
      tooltip: "设备选择",
      itemBuilder: (context) {
        return [
          // 麦克风选择
          if (state.audioInputs.isNotEmpty)
            PopupMenuItem(
              enabled: false,
              child: Text(
                "麦克风",
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
                    child: Text(device.label, overflow: TextOverflow.ellipsis),
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
                "摄像头",
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
                    child: Text(device.label, overflow: TextOverflow.ellipsis),
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
                "扬声器",
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
                    child: Text(device.label, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              onTap: () => notifier.switchAudioOutput(device),
            ),
          ),
        ];
      },
    );
  }

  /// 构建功能按钮
  Widget _buildActionButton({
    required VoidCallback onPressed,
    required List<List<dynamic>> icon,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: label,
          onPressed: onPressed,
          icon: HugeIcon(icon: icon, size: 20),
          iconSize: 24,
          padding: EdgeInsets.all(8),
          constraints: BoxConstraints(minWidth: 40, minHeight: 40),
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
          tooltip: "挂断",
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
    if (h > 0)
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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

/// 网络质量指示器：从 RoomState 中读取本地 participant 对应的 quality 标签与 RTT（ms），显示一个小图标与数值。
class NetworkStatusIndicator extends StatelessWidget {
  final RoomState state;
  const NetworkStatusIndicator({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    // 找到本地 participant 的 sid（LocalParticipant）
    final localSid = state.room.localParticipant?.sid;
    final quality = (localSid != null && state.participantQuality != null)
        ? state.participantQuality![localSid]
        : null;

    final rtt = (localSid != null && state.participantRttMs != null)
        ? state.participantRttMs![localSid]
        : null;

    // 将网络状态以 3-bar 信号样式展示，和 ParticipantTile 保持一致
    Color color = Colors.white70;
    int level = 0; // 0..3

    if (quality != null) {
      switch (quality) {
        case 'good':
          color = Colors.lightGreenAccent;
          level = 3;
          break;
        case 'fair':
          color = Colors.orangeAccent;
          level = 2;
          break;
        case 'poor':
          color = Colors.redAccent;
          level = 1;
          break;
        default:
          color = Colors.white70;
          level = 3;
      }
    } else if (rtt != null) {
      final rr = int.tryParse(rtt.toString()) ?? 9999;
      if (rr < 100) {
        color = Colors.lightGreenAccent;
        level = 3;
      } else if (rr < 250) {
        color = Colors.orangeAccent;
        level = 2;
      } else {
        color = Colors.redAccent;
        level = 1;
      }
    } else {
      // unknown
      color = Colors.white70;
      level = 0;
    }

    Widget bar(int idx) {
      final active = level >= idx;
      final h = 6.0 + idx * 4.0; // heights: 10,14,18
      return Container(
        width: 4,
        height: h,
        margin: const EdgeInsets.symmetric(horizontal: 1.0),
        decoration: BoxDecoration(
          color: active ? color : Colors.white12,
          borderRadius: BorderRadius.circular(1),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            SizedBox(
              width: 22,
              height: 18,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    bar(1),
                    bar(2),
                    bar(3),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              rtt != null ? '${rtt}ms' : (quality ?? 'unknown'),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        Text('call_network'.tr(), style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
