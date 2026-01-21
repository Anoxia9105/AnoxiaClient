import 'dart:convert';

import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/pages/sub_window/component/CommandBar.dart';
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
            error: (err, stack) => _buildErrorState(err.toString(), ref),
            data: (roomState) => _buildRoomContent(roomState),
          ),

          // 重连状态浮层
          if (roomAsync.value?.isReconnecting ?? false)
            Positioned(
              top: 80.h,
              left: 24.w,
              right: 24.w,
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "连接已断开",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            "正在自动重连...",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            "正在连接通话房间...",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "请稍候",
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// 错误状态
  Widget _buildErrorState(String error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Container(
          padding: EdgeInsets.all(32.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red.shade600,
                  size: 48.sp,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                "连接失败",
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  error,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(roomControllerProvider(token)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "重新尝试",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.video_call_outlined,
                size: 64.sp,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              "暂无通话参与者",
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "等待其他人加入...",
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[400]),
            ),
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
        itemBuilder: (context, index) =>
            _buildParticipantItem(context, participants[index]),
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

    // 判断音频状态（是否静音）
    final isMuted = participant is LocalParticipant
        ? !participant.isMicrophoneEnabled()
        : participant.audioTrackPublications.isEmpty ||
              participant.audioTrackPublications.first.track == null ||
              !participant.audioTrackPublications.first.subscribed;

    // 获取视频轨道（优先屏幕共享轨道）
    VideoTrack? videoTrack;
    if (participant.videoTrackPublications.length > 1) {
      // 本地参与者有多个视频轨道时，优先显示屏幕共享
      final screenTrack =
          participant.videoTrackPublications
                  .where((t) => t.track?.source == TrackSource.screenShareVideo)
                  .firstOrNull
                  ?.track
              as VideoTrack?;
      // 检查屏幕共享轨道是否有效且未被静音
      if (screenTrack != null && !screenTrack.muted) {
        videoTrack = screenTrack;
      }
    }

    // 没有屏幕共享轨道则用普通视频轨道
    if (videoTrack == null) {
      final cameraTrack =
          participant.videoTrackPublications
                  .where(
                    (track) =>
                        track.track != null &&
                        track.subscribed &&
                        track.track!.source != TrackSource.screenShareVideo,
                  )
                  .firstOrNull
                  ?.track
              as VideoTrack?;
      // 检查摄像头轨道是否有效且未被静音
      if (cameraTrack != null && !cameraTrack.muted) {
        videoTrack = cameraTrack;
      }
    }

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.r)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              width: 1,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 视频渲染/占位图
              _buildVideoContent(videoTrack, avatarUrl, nickName),

              // 参与者信息栏
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isMuted) ...[
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedMicOff01,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                      ],
                      if (!isMuted) ...[
                        HugeIcon(icon: HugeIcons.strokeRoundedMic01, size: 16),
                        SizedBox(width: 4),
                      ],
                      Text(
                        nickName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 视频内容/占位图
  Widget _buildVideoContent(
    VideoTrack? videoTrack,
    String avatarUrl,
    String nickName,
  ) {
    if (videoTrack != null) {
      return VideoTrackRenderer(videoTrack, fit: VideoViewFit.cover);
    } else {
      return Center(
        child: AvatarWidget(size: 48.w, url: avatarUrl, name: nickName),
      );
    }
  }
}
