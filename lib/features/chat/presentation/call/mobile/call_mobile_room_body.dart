import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/features/chat/presentation/call/component/command_bar.dart';
import 'package:anoxia/features/chat/presentation/call/desktop/room_layout/layout_room_carousel_widget.dart';
import 'package:anoxia/features/chat/presentation/call/desktop/room_layout/layout_room_screen_widget.dart';
import 'package:anoxia/features/chat/presentation/call/desktop/room_layout/layout_room_widget.dart';
import 'package:anoxia/framework/provider/chat/call/LayoutMode.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:anoxia/framework/domain/RoomState.dart';
import 'package:easy_localization/easy_localization.dart';

class CallMobileRoomBody extends ConsumerStatefulWidget {
  final RoomState roomState;
  final String token;

  const CallMobileRoomBody({
    super.key,
    required this.roomState,
    required this.token,
  });

  @override
  ConsumerState<CallMobileRoomBody> createState() => _CallMobileRoomBodyState();
}

class _CallMobileRoomBodyState extends ConsumerState<CallMobileRoomBody> {
  @override
  Widget build(BuildContext context) {
    // 1. 动态订阅布局模式
    final layoutMode = ref.watch(layoutModeProvider(widget.roomState));

    // 2. 组装房间成员数据
    final participants = <Participant>[
      if (widget.roomState.room.localParticipant != null)
        widget.roomState.room.localParticipant!,
      ...widget.roomState.remoteParticipants,
    ];

    // 3. 检测是否有屏幕共享者
    final screenSharer = participants
        .where((p) => p.videoTrackPublications.any((pub) => pub.isScreenShare))
        .firstOrNull;

    // 4. 获取控制器方法引用
    final notifier = ref.read(roomControllerProvider(widget.token).notifier);
    void onMute(String identity) => notifier.sendMuteCommand(identity, true);
    void onKick(String identity) => notifier.kickParticipant(identity);

    // 订阅会话状态，安全获取 isInPipMode
    final session = ref.watch(mobileCallSessionControllerProvider);
    final isInPipMode = session?.isInPipMode ?? false;

    // ─── 🎬 状况 A：画中画模式 ───
    // 如果处于画中画，直接返回纯视频流
    if (isInPipMode) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: participants.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : LayoutRoomWidget(
                participants: participants,
                handRaiseMap: const {},
              ),
      );
    }

    // ─── 📱 状况 B：正常全屏状态 ───
    return Scaffold(
      backgroundColor: DeviceUtil.isRealDesktop()
          ? Colors.transparent
          : Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 中间核心区域：视频排版
            Expanded(
              child: participants.isEmpty
                  ? Center(child: Text('call_waiting_to_join'.tr()))
                  : _buildLayout(
                      mode: layoutMode,
                      participants: participants,
                      screenSharer: screenSharer,
                      handRaiseMap: widget.roomState.handRaiseMap ?? {},
                      onMute: onMute,
                      onKick: onKick,
                    ),
            ),

            // 💡 底部控制条
            CommandBar(state: widget.roomState),
          ],
        ),
      ),
    );
  }

  /// 根据布局模式构建对应的布局组件
  Widget _buildLayout({
    required LayoutMode mode,
    required List<Participant> participants,
    required Participant? screenSharer,
    required Map<String, bool> handRaiseMap,
    void Function(String identity)? onMute,
    void Function(String identity)? onKick,
  }) {
    return switch (mode) {
      LayoutMode.grid => LayoutRoomWidget(
        participants: participants,
        handRaiseMap: handRaiseMap,
        onMute: onMute,
        onKick: onKick,
      ),
      LayoutMode.focus => LayoutRoomScreenWidget(
        screenParticipant: screenSharer!,
        otherParticipants: participants
            .where((p) => p.sid != screenSharer.sid)
            .toList(),
        handRaiseMap: handRaiseMap,
        onMute: onMute,
        onKick: onKick,
      ),
      LayoutMode.carousel => LayoutRoomCarouselWidget(
        participants: participants,
        handRaiseMap: handRaiseMap,
        onMute: onMute,
        onKick: onKick,
      ),
    };
  }
}
