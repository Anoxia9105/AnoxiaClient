import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../framework/provider/kit/room_controller.dart';
import '../component/ParticipantTile.dart';

/// LiveKit 参与者网格布局组件
class LiveKitGridLayout extends StatelessWidget {
  const LiveKitGridLayout({
    super.key,
    required this.token,
    this.spacing = 8,
  });

  final String token;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final roomState = roomControllerProvider(token);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final participants = _getParticipants(roomState);
        final columns = _calculateColumns(context, constraints.maxWidth);
        
        return GridView.builder(
          padding: EdgeInsets.all(spacing),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 16 / 9,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: participants.length,
          itemBuilder: (context, index) {
            final participant = participants[index];
            return ParticipantTile(
              participant: participant,
              token: token,
            );
          },
        );
      },
    );
  }

  List<Participant> _getParticipants(AsyncValue<RoomState> roomState) {
    final state = roomState.value;
    if (state == null) return [];

    final participants = <Participant>[];
    
    // 先添加本地参与者
    if (state.room.localParticipant != null) {
      participants.add(state.room.localParticipant!);
    }
    
    // 添加远程参与者
    participants.addAll(state.remoteParticipants);
    
    return participants;
  }

  int _calculateColumns(BuildContext context, double width) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    
    if (isMobile) {
      return 2;
    } else if (isTablet) {
      return 3;
    } else {
      // 桌面端根据宽度动态计算
      if (width < 800) return 2;
      if (width < 1200) return 3;
      if (width < 1600) return 4;
      return 5;
    }
  }
}

/// LiveKit 布局选项
class LiveKitLayoutOptions {
  final LayoutMode mode;
  final int? focusParticipantIndex;
  final bool showLocalParticipant;

  const LiveKitLayoutOptions({
    this.mode = LayoutMode.grid,
    this.focusParticipantIndex,
    this.showLocalParticipant = true,
  });

  LiveKitLayoutOptions copyWith({
    LayoutMode? mode,
    int? focusParticipantIndex,
    bool? showLocalParticipant,
  }) {
    return LiveKitLayoutOptions(
      mode: mode ?? this.mode,
      focusParticipantIndex: focusParticipantIndex ?? this.focusParticipantIndex,
      showLocalParticipant: showLocalParticipant ?? this.showLocalParticipant,
    );
  }
}

/// 布局模式
enum LayoutMode {
  grid,
  carousel,
  focused,
}
