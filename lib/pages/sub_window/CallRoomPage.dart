import 'dart:convert';

import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/pages/sub_window/CommandBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
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
      body: Stack(
        children: [
          // 主内容
          roomAsync.when(
            loading: () => _buildLoadingState(),
            error: (err, stack) => _buildErrorState(err.toString(),ref),
            data: (roomState) => _buildRoomContent(roomState),
          ),

          // 重连状态浮层
          if (roomAsync.value?.isReconnecting ?? false)
            Positioned(
              top: 100.h,
              left: 0,
              right: 0,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 24.w),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(strokeWidth: 2),
                    SizedBox(width: 8.w),
                    Text(
                      "连接已断开，正在重连...",
                      style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 加载状态
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("正在连接通话房间...", style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  /// 错误状态
  Widget _buildErrorState(String error,WidgetRef ref) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16.h),
            Text(
              "连接失败",
              style: TextStyle(fontSize: 18.sp, color: Colors.red),
            ),
            SizedBox(height: 8.h),
            Text(
              "错误信息: $error",
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () =>  ref.invalidate(roomControllerProvider(token)),
              child: const Text("重新尝试"),
            ),
          ],
        ),
      ),
    );
  }

  /// 房间内容
  Widget _buildRoomContent(RoomState state) {
    return Column(
      children: [
        CommandBar(state: state),
        Expanded(child: _buildVideoGrid(state)),
      ],
    );
  }

  /// 视频网格
  Widget _buildVideoGrid(RoomState state) {
    // 包含本地和远程参与者
    final participants = <Participant>[
      if (state.room.localParticipant != null) state.room.localParticipant!,
      ...state.remoteParticipants.whereType<Participant>(),
    ];

    // 空状态
    if (participants.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_call_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("暂无通话参与者", style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    // 智能计算列数
    int calculateCrossAxisCount(int count) {
      if (count == 1) return 1;
      if (count == 2) return 2;
      if (count <= 4) return 2;
      return 3;
    }

    final crossAxisCount = calculateCrossAxisCount(participants.length);

    return Padding(
      padding: EdgeInsets.all(12.w),
      child: GridView.builder(
        physics: const ClampingScrollPhysics(),
        itemCount: participants.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8.w,
          mainAxisSpacing: 8.h,
          childAspectRatio: 16 / 9,
        ),
        itemBuilder: (context, index) => _buildParticipantItem(context, participants[index]),
      ),
    );
  }

  /// 单个参与者视图
  Widget _buildParticipantItem(BuildContext context, Participant participant) {
    // 解析用户元数据
    Map<String, dynamic> userData = {};
    try {
      if (participant.metadata != null && participant.metadata!.isNotEmpty) {
        userData = jsonDecode(participant.metadata!);
      }
    } catch (e) {
      log.error("解析用户元数据失败: $e");
    }

    final avatarUrl = userData['avatar'] ?? "";
    final nickName = userData['nickName'] ?? participant.identity;
    final isLocal = participant is LocalParticipant;

    // 判断音频状态（是否静音）
    final isMuted = participant is LocalParticipant
        ? !participant.isMicrophoneEnabled()
        : participant.audioTrackPublications.isEmpty ||
        participant.audioTrackPublications.first.track == null ||
        !participant.audioTrackPublications.first.subscribed;

    // 获取视频轨道（优先屏幕共享轨道）
    VideoTrack? videoTrack;
    if (participant is LocalParticipant && participant.videoTrackPublications.length > 1) {
      // 本地参与者有多个视频轨道时，优先显示屏幕共享
      videoTrack = participant.videoTrackPublications
          .where((t) => t.track?.source == TrackSource.screenShareVideo)
          .firstOrNull?.track as VideoTrack?;
    }

    // 没有屏幕共享轨道则用普通视频轨道
    videoTrack ??= participant.videoTrackPublications
        .where((track) => track.track != null && track.subscribed)
        .firstOrNull?.track as VideoTrack?;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 1.w, color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8.r),
          color: Colors.grey[100],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 视频渲染/占位图
            _buildVideoContent(videoTrack, avatarUrl, nickName),

            // 参与者信息栏
            Positioned(
              bottom: 8.h,
              left: 8.w,
              right: 8.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Row(
                  children: [
                    // 本地/远程标识
                    if (isLocal)
                      Container(
                        margin: EdgeInsets.only(right: 4.w),
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                        child: Text(
                          "我",
                          style: TextStyle(fontSize: 8.sp, color: Colors.white),
                        ),
                      ),

                    // 昵称
                    Expanded(
                      child: Text(
                        nickName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // 静音状态
                    if (isMuted)
                      Icon(Icons.mic_off, size: 14.sp, color: Colors.red),
                  ],
                ),
              ),
            ),

            // 视频状态提示
            if (videoTrack == null)
              Positioned(
                top: 8.h,
                right: 8.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    "视频关闭",
                    style: TextStyle(fontSize: 10.sp, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 视频内容/占位图
  Widget _buildVideoContent(VideoTrack? videoTrack, String avatarUrl, String nickName) {
    if (videoTrack != null) {
      return VideoTrackRenderer(
        videoTrack,
        fit: VideoViewFit.cover,
      );
    } else {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: AvatarWidget(
            size: 64.w,
            url: avatarUrl,
            name: nickName,
          ),
        ),
      );
    }
  }
}