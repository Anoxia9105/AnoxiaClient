import 'package:anoxia/features/chat/presentation/call/component/participant_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:livekit_client/livekit_client.dart';

/// 通话房间屏幕共享布局组件
///
/// 当有参与者共享屏幕时使用此布局：
/// - 左侧大区域显示共享内容
/// - 右侧小列表显示其他参与者
class LayoutRoomScreenWidget extends StatefulWidget {
  /// 正在共享屏幕的参与者
  final Participant screenParticipant;

  /// 其他参与者列表
  final List<Participant> otherParticipants;

  /// 举手状态映射表（参与者 identity -> 是否举手）
  final Map<String, bool> handRaiseMap;

  /// 静音回调，传入目标参与者 identity
  final void Function(String identity)? onMute;

  /// 踢出回调，传入目标参与者 identity
  final void Function(String identity)? onKick;

  const LayoutRoomScreenWidget({
    super.key,
    required this.screenParticipant,
    required this.otherParticipants,
    this.handRaiseMap = const {},
    this.onMute,
    this.onKick,
  });

  @override
  State<LayoutRoomScreenWidget> createState() => _LayoutRoomScreenWidgetState();
}

class _LayoutRoomScreenWidgetState extends State<LayoutRoomScreenWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ParticipantTile(
            participant: widget.screenParticipant,
            handRaised:
                widget.handRaiseMap[widget.screenParticipant.identity] == true,
            onMute: widget.onMute,
            onKick: widget.onKick,
            key: ValueKey('${widget.screenParticipant.sid}-screen'),
          ),
        ),

        const SizedBox(width: 8),

        if (widget.otherParticipants.isNotEmpty)
          SizedBox(
            width: 40.w,
            child: ListView.separated(
              itemCount: widget.otherParticipants.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final p = widget.otherParticipants[index];
                return AspectRatio(
                  aspectRatio: 1.0,
                  child: ParticipantTile(
                    participant: p,
                    handRaised: widget.handRaiseMap[p.identity] == true,
                    onMute: widget.onMute,
                    onKick: widget.onKick,
                    key: ValueKey(p.sid),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
