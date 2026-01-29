import 'dart:convert';

import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/pages/call_window/component/CommandBar.dart';
import 'package:anoxia/pages/call_window/component/ParticipantTile.dart';
import 'package:anoxia/pages/call_window/room_layout/LayoutRoomScreenWidget.dart';
import 'package:anoxia/pages/call_window/room_layout/LayoutRoomWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../framework/provider/kit/room_controller.dart';

class CallRoomPage extends ConsumerWidget {
  final String token;

  const CallRoomPage({super.key, required this.token});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomControllerProvider(token));

    return Scaffold(
      body: roomAsync.when(
        loading: () => _buildLoadingState(),
        error: (err, stack) => _buildErrorState(err.toString(), ref),
        data: (roomState) {
          // 收集所有参与者
          final participants = <Participant>[
            if (roomState.room.localParticipant != null)
              roomState.room.localParticipant!,
            ...roomState.remoteParticipants,
          ];

          final screenSharer = participants
              .where(
                (p) => p.videoTrackPublications.any((pub) => pub.isScreenShare),
              )
              .firstOrNull;

          return Column(
            children: [
              // 顶部工具栏
              CommandBar(state: roomState),

              // 核心布局
              Expanded(
                child: participants.isEmpty
                    ? const Center(child: Text("等待加入..."))
                    : screenSharer == null
                    ? LayoutRoomWidget(participants: participants)
                    : LayoutRoomScreenWidget(
                        screenParticipant: screenSharer,
                        otherParticipants: participants
                            .where((p) => p.sid != screenSharer.sid)
                            .toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 加载状态
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 3),
          SizedBox(height: 24.h),
          Text("正在连接通话房间...", style: TextStyle(fontSize: 16)),
          SizedBox(height: 8.h),
          Text("请稍候", style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  /// 错误状态
  Widget _buildErrorState(String error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red.shade600,
                  size: 48,
                ),
              ),
              SizedBox(height: 24.h),
              Text("连接失败", style: TextStyle(fontSize: 20)),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),

                child: Text(
                  error,
                  style: TextStyle(fontSize: 14, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      ref.invalidate(roomControllerProvider(token)),

                  child: Text(
                    "重新尝试",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
