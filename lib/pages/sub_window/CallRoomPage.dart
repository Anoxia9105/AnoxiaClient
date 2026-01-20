import 'dart:convert';

import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/pages/sub_window/CommandBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../framework/domain/RoomState.dart';
import '../../framework/provider/kit/room_controller.dart';

class CallRoomPage extends ConsumerWidget {
  final String token;

  const CallRoomPage({super.key, required this.token});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomControllerProvider(token));
    return Scaffold(
      body: roomAsync.when(
        // 1. 请求中状态
        loading: () => const Center(child: CircularProgressIndicator()),
        // 2. 错误状态
        error: (err, stack) => Center(
          child: Text("连接失败: $err", style: const TextStyle(color: Colors.red)),
        ),
        // 3. 成功状态：渲染真正的通话 UI
        data: (roomState) => Column(
          children: [
            CommandBar(state: roomState),
            Expanded(child: _buildVideoGrid(roomState)),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoGrid(RoomState state) {
    // 包含本地和远程参与者
    final participants = [
      state.room.localParticipant!,
      ...state.remoteParticipants,
    ].whereType<Participant>().toList();

    return GridView.builder(
      itemCount: participants.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemBuilder: (context, index) {
        final participant = participants[index]; // 这是一个 Participant 对象

        Map<String, dynamic> userData = {};
        try {
          if (participant.metadata != null &&
              participant.metadata!.isNotEmpty) {
            userData = jsonDecode(participant.metadata!);
          }
        } catch (e) {
          log.error("解析用户元数据失败: $e");
        }

        final avatarUrl = userData['avatar'] ?? ""; // 获取头像地址
        final nickName =
            userData['nickName'] ?? participant.identity; // 获取昵称，没有就用 identity
        // 或者更简单地使用 videoTracks
        final trackPub = participant.videoTrackPublications.isNotEmpty
            ? participant.videoTrackPublications.first
            : null;

        final user = jsonEncode(participant.metadata);
        return Container(
          color: Colors.black,
          child: Stack(
            children: [
              // 只有当轨道存在且没有被禁用的情况下才渲染
              if (trackPub != null && trackPub.track != null)
                VideoTrackRenderer(trackPub.track as VideoTrack)
              else
                Center(
                  child: AvatarWidget(url: avatarUrl, name: nickName),
                ),

              Positioned(
                bottom: 5,
                left: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(nickName, style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
