import 'package:anoxia/framework/domain/RoomState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:window_manager/window_manager.dart';

import '../../framework/provider/kit/room_controller.dart';

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
        style: TextButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        onPressed: () => notifier.reconnect(),
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text("重新连接"),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: const Offset(0, 1),
          )
        ],
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
                  icon: state.micEnabled ? HugeIcons.strokeRoundedMic01 : HugeIcons.strokeRoundedMicOff01,
                  label: state.micEnabled ? "静音" : "取消静音",
                  color: state.micEnabled ? null : Colors.red,
                ),
                SizedBox(width: 16),

                // 摄像头控制
                _buildActionButton(
                  onPressed: () => notifier.toggleCamera(),
                  icon: state.cameraEnabled ? HugeIcons.strokeRoundedVideo01 : HugeIcons.strokeRoundedVideoOff,
                  label: "摄像头",
                  color: state.cameraEnabled ? Colors.green : null,
                ),
                SizedBox(width: 16),

                // 扬声器控制
                _buildActionButton(
                  onPressed: () => notifier.toggleSpeaker(),
                  icon: state.speakerOn ? HugeIcons.strokeRoundedVolumeUp : HugeIcons.strokeRoundedVolumeOff,
                  label: state.speakerOn ? "扬声器" : "听筒",
                  color: state.speakerOn ? Colors.blue : null,
                ),
                SizedBox(width: 16),

                // 屏幕共享
                _buildActionButton(
                  onPressed: () => notifier.toggleScreenShare(context),
                  icon: state.screenSharing ? HugeIcons.strokeRoundedComputerRemove : HugeIcons.strokeRoundedComputerScreenShare,
                  label: "共享",
                  color: state.screenSharing ? Colors.purple : null,
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
  Widget _buildDeviceMenu(BuildContext context, WidgetRef ref, RoomController notifier) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.devices_rounded),
      tooltip: "设备选择",
      itemBuilder: (context) {
        return [
          // 麦克风选择
          if (state.audioInputs.isNotEmpty)
            PopupMenuItem(
              enabled: false,
              child: Text("麦克风", style: TextStyle(color: Theme.of(context).hintColor)),
            ),
          ...state.audioInputs.map((device) => PopupMenuItem(
            value: "mic_${device.deviceId}",
            child: Row(
              children: [
                if (state.currentAudioInput?.deviceId == device.deviceId)
                  const Icon(Icons.check, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(device.label, overflow: TextOverflow.ellipsis)),
              ],
            ),
            onTap: () => notifier.switchAudioInput(device),
          )),

          const PopupMenuDivider(),

          // 摄像头选择
          if (state.videoInputs.isNotEmpty)
            PopupMenuItem(
              enabled: false,
              child: Text("摄像头", style: TextStyle(color: Theme.of(context).hintColor)),
            ),
          ...state.videoInputs.map((device) => PopupMenuItem(
            value: "cam_${device.deviceId}",
            child: Row(
              children: [
                if (state.currentVideoInput?.deviceId == device.deviceId)
                  const Icon(Icons.check, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(device.label, overflow: TextOverflow.ellipsis)),
              ],
            ),
            onTap: () => notifier.switchVideoInput(device),
          )),

          const PopupMenuDivider(),

          // 扬声器选择
          if (state.audioOutputs.isNotEmpty)
            PopupMenuItem(
              enabled: false,
              child: Text("扬声器", style: TextStyle(color: Theme.of(context).hintColor)),
            ),
          ...state.audioOutputs.map((device) => PopupMenuItem(
            value: "speaker_${device.deviceId}",
            child: Row(
              children: [
                if (state.currentAudioOutput?.deviceId == device.deviceId)
                  const Icon(Icons.check, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(device.label, overflow: TextOverflow.ellipsis)),
              ],
            ),
            onTap: () => notifier.switchAudioOutput(device),
          )),
        ];
      },
    );
  }

  /// 构建功能按钮
  Widget _buildActionButton({
    required VoidCallback onPressed,
    required List<List<dynamic>> icon,
    required String label,
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: HugeIcon(
            icon: icon,
            size: 24,
            color: color ?? Colors.white,
          ),
          iconSize: 24,
          padding: EdgeInsets.all(8),
          constraints: BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color ?? Colors.white,
          ),
        ),
      ],
    );
  }

  /// 构建挂断按钮
  Widget _buildHangupButton(BuildContext context, RoomController notifier) {
    return SizedBox(
      height: 40,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () async {
          await notifier.leave();
          if (context.mounted) {
            await windowManager.close();
          }
        },
        icon: Icon(Icons.call_end, size: 18),
        label: Text("挂断", style: TextStyle(fontSize: 14)),
      ),
    );
  }
}