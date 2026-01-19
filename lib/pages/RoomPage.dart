import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';

import '../framework/domain/RoomState.dart';
import '../framework/provider/kit/room_controller.dart';

class RoomPage extends ConsumerWidget {
  final Room room;

  const RoomPage({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听状态和控制器
    final state = ref.watch(roomControllerProvider(room));
    final controller = ref.read(roomControllerProvider(room).notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(context, state, controller),
      body: Column(
        children: [
          // ================= 视频区域 =================
          Expanded(child: _buildVideoArea(state)),

          // ================= 控制栏 =================
          _buildControlBar(context, state, controller),
        ],
      ),
    );
  }

  // ================= AppBar =================

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    RoomState state,
    RoomController controller,
  ) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('会议进行中', style: TextStyle(fontSize: 16)),
          Text(
            '状态: ${state.connectionState.name.toUpperCase()}',
            style: TextStyle(
              fontSize: 10,
              color: state.connectionState == ConnectionState.connected
                  ? Colors.green
                  : Colors.orange,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: '成员列表',
          icon: const Icon(Icons.group_outlined),
          onPressed: () => _showParticipants(context, state),
        ),
        IconButton(
          tooltip: '离开房间',
          icon: const Icon(Icons.call_end, color: Colors.redAccent),
          onPressed: () async {
            await controller.leave();
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  // ================= 视频区 (含本地预览) =================

  Widget _buildVideoArea(RoomState state) {
    // 1. 如果还在连接中，显示加载提示
    if (state.connectionState == ConnectionState.connecting ||
        state.connectionState == ConnectionState.reconnecting) {
      return _buildCenterHint(
        icon: Icons.sync,
        text: '正在努力连接中…',
        isSpinning: true,
      );
    }

    // 2. 准备参与者列表 (本地自己 + 远端用户)
    final allParticipants = [
      room.localParticipant, // 把自己放第一个
      ...state.remoteParticipants,
    ].whereType<Participant>().toList();

    // 3. 构建显示列表：每个参与者的每个视频轨道都应该占用一个格子
    final List<Widget> tiles = [];

    for (var p in allParticipants) {
      // A. 如果没有任何视频，显示一个占位头像
      if (p.videoTrackPublications.isEmpty) {
        tiles.add(_ParticipantTile(participant: p, videoTrack: null));
        continue;
      }

      // B. 遍历该用户的所有视频轨道 (摄像头 + 屏幕共享)
      for (var pub in p.videoTrackPublications) {
        // 过滤掉没订阅或被禁用的轨道 (可选)
        if (!pub.subscribed && pub is RemoteTrackPublication) continue;

        // 只有没被 Mute 的才显示，或者你想显示黑屏也可以
        // if (pub.muted) continue;

        tiles.add(
          _ParticipantTile(
            participant: p,
            videoTrack: pub.track as VideoTrack?,
          ),
        );
      }
    }

    // 🔥 修复点：直接使用 tiles 列表渲染
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2列布局
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0, // 正方形格子
      ),
      itemCount: tiles.length, // 使用 tiles 的长度
      itemBuilder: (_, index) {
        return tiles[index]; // 直接返回算好的 Widget
      },
    );
  }

  Widget _buildCenterHint({
    required IconData icon,
    required String text,
    bool isSpinning = false,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          isSpinning
              ? const CircularProgressIndicator(color: Colors.blue)
              : Icon(icon, size: 48, color: Colors.white24),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  // ================= 控制栏 =================

  Widget _buildControlBar(
    BuildContext context,
    RoomState state,
    RoomController controller,
  ) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ControlButton(
              icon: state.micEnabled ? Icons.mic : Icons.mic_off,
              active: state.micEnabled,
              label: '静音',
              onTap: controller.toggleMic,
            ),
            _ControlButton(
              icon: state.cameraEnabled ? Icons.videocam : Icons.videocam_off,
              active: state.cameraEnabled,
              label: '视频',
              onTap: controller.toggleCamera,
            ),
            _ControlButton(
              icon: state.screenSharing
                  ? Icons.stop_screen_share
                  : Icons.screen_share,
              active: state.screenSharing,
              label: '共享',
              onTap: () => controller.toggleScreenShare(context),
            ),
            _ControlButton(
              icon: state.speakerOn ? Icons.volume_up : Icons.volume_down,
              active: state.speakerOn,
              label: '扬声器',
              onTap: controller.toggleSpeaker, // 👉 修复了这里
            ),
          ],
        ),
      ),
    );
  }

  void _showParticipants(BuildContext context, RoomState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '房间成员 (${state.remoteParticipants.length + 1})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: Colors.white12, height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildMemberItem(
                    room.localParticipant?.identity ?? '我',
                    isLocal: true,
                  ),
                  ...state.remoteParticipants.map(
                    (p) => _buildMemberItem(p.identity),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberItem(String identity, {bool isLocal = false}) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(identity.characters.firstOrNull ?? '?'),
      ),
      title: Text(
        identity + (isLocal ? ' (我)' : ''),
        style: const TextStyle(color: Colors.white),
      ),
      trailing: const Icon(Icons.more_vert, color: Colors.white54),
    );
  }
}

// ================= 单个参与者视频组件 =================

class _ParticipantTile extends StatelessWidget {
  final Participant participant;
  final VideoTrack? videoTrack;

  const _ParticipantTile({super.key, required this.participant, required this.videoTrack});

  @override
  Widget build(BuildContext context) {


    return ListenableBuilder(
      listenable: participant,
      builder: (BuildContext context, Widget? child) {

        final isSpeaking = participant.isSpeaking;

        final isScreenShare = videoTrack?.source == TrackSource.screenShareVideo;
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
            // 🔥 如果正在说话，显示绿色边框
            border: isSpeaking
                ? Border.all(color: Colors.greenAccent, width: 4)
                : null,
          ),
          child: Stack(
            children: [
              // 1. 视频渲染
              if (videoTrack != null)
                VideoTrackRenderer(
                  videoTrack!,
                  fit: isScreenShare
                      ? VideoViewFit.contain
                      : VideoViewFit.cover,
                )
              else
                Center(
                  child: Icon(
                    Icons.person,
                    size: 40,
                    // 🔥 如果正在说话，图标也可以变色
                    color: isSpeaking ? Colors.greenAccent : Colors.white10,
                  ),
                ),

              // ... 其他 UI (图标, 名字等) ...

              // 底部名字栏
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: Colors.black45,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${participant.identity}${isSpeaking ? " 🔊" : ""}', // 文字提示
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                      // ...
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

      },
    );
  }
}

// ================= 控制按钮组件 =================

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final String label;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.active,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: active
                    ? Colors.blueAccent
                    : Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
