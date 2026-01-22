import 'package:anoxia/framework/domain/RoomState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:window_manager/window_manager.dart';

import '../../../framework/provider/kit/room_controller.dart';

class CommandBar extends ConsumerWidget {
  final RoomState state;

  const CommandBar({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(roomControllerProvider(state.token).notifier);

    // 重连按钮（仅在重连状态显示）
    Widget reconnectButton = const SizedBox.shrink();
    if (state.isReconnecting) {
      reconnectButton = TextButton.icon(
        onPressed: () => notifier.reconnect(),
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text("重新连接"),
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
          // 设备选择菜单
          _buildDeviceMenu(context, ref, notifier),
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
              ],
            ),
          ),

          const SizedBox(width: 16),

          // 重连按钮 + 挂断按钮
          Row(
            children: [
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
        Text("挂断", style: TextStyle(fontSize: 10)),
      ],
    );
  }
}
