import 'package:anoxia/framework/domain/RoomState.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:window_manager/window_manager.dart';

import '../../framework/provider/kit/room_controller.dart';

class CommandBar extends ConsumerWidget {
  final RoomState state;

  const CommandBar({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(roomControllerProvider(state.token).notifier);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.8),
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 均匀分布
        children: [
          // 麦克风控制
          _buildActionButton(
            onPressed: () => notifier.toggleMic(),
            icon: state.micEnabled
                ? HugeIcons.strokeRoundedMic01
                : HugeIcons.strokeRoundedMicOff01,
            label: state.micEnabled ? "静音" : "取消静音",
            color: state.micEnabled ? null : Colors.red,
          ),

          // 摄像头控制
          _buildActionButton(
            onPressed: () => notifier.toggleCamera(),
            icon: state.cameraEnabled
                ? HugeIcons.strokeRoundedVideo01
                : HugeIcons.strokeRoundedVideoOff,
            label: "摄像头",
            color: state.cameraEnabled ? Colors.green : null,
          ),

          // 屏幕共享
          _buildActionButton(
            onPressed: () => notifier.toggleScreenShare(context),
            icon: state.screenSharing
                ? HugeIcons.strokeRoundedComputerRemove
                : HugeIcons.strokeRoundedComputerScreenShare,
            label: "共享",
          ),

          const Spacer(), // 拉开距离
          // 挂断按钮
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () async {
              await notifier.leave(); // 调用清理逻辑
              await windowManager.close();
            },
            icon: const Icon(Icons.call_end, size: 18),
            label: const Text("挂断"),
          ),
        ],
      ),
    );
  }

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
          icon: HugeIcon(icon: icon, size: 22, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
