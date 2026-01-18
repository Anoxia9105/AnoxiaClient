import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class RoomPage extends StatefulWidget {
  final Room room;

  const RoomPage({Key? key, required this.room}) : super(key: key);

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  List<Participant> participantList = [];
  EventsListener<RoomEvent>? _listener;

  @override
  void initState() {
    super.initState();
    // 1. 初始化参与者列表 (本地 + 远程)
    _updateParticipantList();

    // 2. 监听房间事件 (关键：没有这个，UI 不会随人员变动而更新)
    _listener = widget.room.createListener();
    _setUpListeners();
  }

  void _setUpListeners() {
    _listener!
      ..on<RoomEvent>((_) => _updateParticipantList()) // 任何房间变动都触发刷新
      ..on<ParticipantEvent>((_) => _updateParticipantList()); // 任何人的状态变动也刷新
  }

  void _updateParticipantList() {
    setState(() {
      // 将本地自己和远程所有人合并到一个列表中
      participantList = [
        widget.room.localParticipant!,
        ...widget.room.remoteParticipants.values,
      ];
    });
  }

  @override
  void dispose() {
    // 记得销毁监听器
    _listener?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('视频会议中')),
      body: Column(
        children: [
          Expanded(
            // 3. 使用 GridView 展示所有人的视频
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 一行显示两个
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3 / 4, // 视频比例
              ),
              itemCount: participantList.length,
              itemBuilder: (context, index) {
                return ParticipantTile(participant: participantList[index]);
              },
            ),
          ),
          // 底部控制栏
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await widget.room.disconnect();
                  Navigator.pop(context);
                },
                child: const Text('挂断离开'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 单个用户的视频组件 ---
class ParticipantTile extends StatelessWidget {
  final Participant participant;

  const ParticipantTile({Key? key, required this.participant}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- 修复开始 ---
    // 安全地查找摄像头视频轨道
    TrackPublication? videoPublication;

    // 遍历所有视频轨道，找到第一个是摄像头(非屏幕共享)的轨道
    for (var pub in participant.videoTrackPublications) {
      if (pub.kind == TrackType.VIDEO && !pub.isScreenShare) {
        videoPublication = pub;
        break; // 找到了就停止
      }
    }
    // --- 修复结束 ---

    // 检查是否有视频流 (轨道存在 && 未静音 && 轨道数据不为空)
    final isVideoEnabled = videoPublication != null &&
        !videoPublication.muted &&
        videoPublication.track != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // 1. 视频层
          if (isVideoEnabled)
            VideoTrackRenderer(
              videoPublication!.track! as VideoTrack,
              // fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          else
          // 没视频时显示的占位图
            Container(
              color: Colors.grey[900],
              child: const Center(
                child: Icon(Icons.videocam_off, color: Colors.grey, size: 48),
              ),
            ),

          // 2. 名字和状态层
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 名字
                  Flexible(
                    child: Text(
                      participant is LocalParticipant
                          ? "我"
                          : (participant.identity ?? "未知用户"),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 麦克风图标
                  Icon(
                    participant.isMicrophoneEnabled() ? Icons.mic : Icons.mic_off,
                    color: participant.isMicrophoneEnabled() ? Colors.greenAccent : Colors.redAccent,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}