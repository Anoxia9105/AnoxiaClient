import 'package:anoxia/pages/chat/call/component/CommandBar.dart';
import 'package:anoxia/pages/chat/call/component/TranscriptionWidget.dart';
import 'package:anoxia/pages/chat/call/component/ScreenShareStatusBar.dart';
import 'package:anoxia/pages/chat/call/room_layout/LayoutRoomScreenWidget.dart';
import 'package:anoxia/pages/chat/call/room_layout/LayoutRoomWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:window_manager/window_manager.dart';

import '../../../framework/provider/kit/room_controller.dart';

class CallRoomPage extends ConsumerStatefulWidget {
  final String token;

  const CallRoomPage({super.key, required this.token});

  @override
  ConsumerState<CallRoomPage> createState() => _CallRoomPageState();
}

class _CallRoomPageState extends ConsumerState<CallRoomPage> {
  bool _showChat = false;

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomControllerProvider(widget.token));

    return Scaffold(
      body: roomAsync.when(
        loading: () => _buildLoadingState(),
        error: (err, stack) => _buildErrorState(err.toString(), ref),
        data: (roomState) {
          // 检查是否需要显示重连遮罩或自动关闭
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // 如果重连失败（token 过期或多次重连耗尽），自动关闭窗口
            if (roomState.connectionError == 'token_expired' ||
                roomState.connectionError ==
                    'max_reconnect_attempts_exceeded') {
              windowManager.close();
            }
          });

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

          return Stack(
            children: [
              // 主布局
              Row(
                children: [
                  // 视频布局
                  Expanded(
                    child: Column(
                      children: [
                        // 顶部工具栏
                        CommandBar(
                          state: roomState,
                          onToggleChat: () =>
                              setState(() => _showChat = !_showChat),
                          showChat: _showChat,
                        ),

                        // 屏幕共享状态栏
                        ScreenShareStatusBar(
                          room: roomState.room,
                          onStopScreenShare: () async {
                            final screenPub = roomState
                                .room
                                .localParticipant
                                ?.videoTrackPublications
                                .where((p) => p.isScreenShare)
                                .firstOrNull;
                            if (screenPub != null) {
                              await roomState.room.localParticipant
                                  ?.removePublishedTrack(screenPub.sid);
                            }
                          },
                        ),

                        // 核心布局
                        Expanded(
                          child: participants.isEmpty
                              ? Center(child: Text('call_waiting_to_join'.tr()))
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
                    ),
                  ),

                  // 聊天侧边栏
                  if (_showChat && roomState.room.localParticipant != null)
                    SizedBox(
                      width: 350,
                      // child: LiveKitChatWidget(
                      //   localParticipant: roomState.room.localParticipant,
                      //   listener: null,
                      // ),
                      child: Text("CHAT"),
                    ),
                ],
              ),

              // 重连中遮罩（不遮挡 CommandBar）
              if (roomState.isReconnecting)
                Positioned(
                  top: kToolbarHeight + 8, // CommandBar 高度 + padding
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.white70),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 24),
                          Text(
                            'call_reconnecting'.tr(),
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '正在尝试恢复你的通话...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 转录组件 - 浮动字幕
              TranscriptionWidget(),
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
          Text('call_connecting_to_room'.tr(), style: TextStyle(fontSize: 16)),
          SizedBox(height: 8.h),
          Text('call_please_wait'.tr(), style: TextStyle(fontSize: 14)),
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
              Text(
                'call_connection_failed'.tr(),
                style: TextStyle(fontSize: 20),
              ),
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
                      ref.invalidate(roomControllerProvider(widget.token)),

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
