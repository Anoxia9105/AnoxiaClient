import 'package:anoxia/features/chat/presentation/call/component/participant_tile.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

/// 通话房间网格布局组件
///
/// 根据参与者数量自动调整布局：
/// - 1人：全屏显示
/// - 2人：左右并排显示
/// - 3-4人：2x2 网格显示
/// - 5人及以上：3列网格显示
class LayoutRoomWidget extends StatelessWidget {
  /// 参与者列表
  final List<Participant> participants;

  /// 举手状态映射表（参与者 identity -> 是否举手）
  final Map<String, bool> handRaiseMap;

  /// 静音回调，传入目标参与者 identity
  final void Function(String identity)? onMute;

  /// 踢出回调，传入目标参与者 identity
  final void Function(String identity)? onKick;
  final void Function(Participant participant)? onParticipantTap;

  const LayoutRoomWidget({
    super.key,
    required this.participants,
    this.handRaiseMap = const {},
    this.onMute,
    this.onKick,
    this.onParticipantTap,
  });

  /// 构建单个参与者磁贴
  Widget _tile(Participant p) => ParticipantTile(
    participant: p,
    handRaised: handRaiseMap[p.identity] == true,
    onMute: onMute,
    onKick: onKick,
    onTap: () => onParticipantTap?.call(p),
  );

  @override
  Widget build(BuildContext context) {
    final count = participants.length;

    if (count == 0) return const SizedBox.shrink();

    if (count == 1) {
      return _tile(participants[0]);
    }

    if (count == 2) {
      return Row(
        children: [
          Expanded(child: _tile(participants[0])),
          const SizedBox(width: 4),
          Expanded(child: _tile(participants[1])),
        ],
      );
    }

    if (count <= 4) {
      final row1 = participants.take(2).toList();
      final row2 = participants.skip(2).toList();
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _tile(row1[0])),
                const SizedBox(width: 4),
                Expanded(child: _tile(row1[1])),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _tile(row2[0])),
                const SizedBox(width: 4),
                Expanded(
                  child: row2.length > 1
                      ? _tile(row2[1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 680
            ? 3
            : 2;
        final tileWidth = constraints.maxWidth / columns;
        final rows = (count / columns).ceil();
        final tileHeight = constraints.maxHeight / rows;
        return GridView.builder(
          itemCount: count,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: tileWidth / tileHeight.clamp(1, double.infinity),
          ),
          itemBuilder: (context, index) => _tile(participants[index]),
        );
      },
    );
  }
}
