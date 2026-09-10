import 'package:anoxia/features/chat/presentation/call/component/participant_tile.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

/// 通话房间屏幕共享布局组件
///
/// 当有参与者共享屏幕时使用此布局：
/// - 共享主画面始终占满可用区域，黑底居中（contain 信箱黑边与视频黑底融为一体，
///   不再出现两侧白色留白），共享区即为视频区
/// - 其余参与者 ≤2 人（含 1v1）时不再挤占右侧边栏，改为右下角悬浮小窗叠加，
///   主画面独占整宽；≥3 人时才使用右侧边栏列表
/// - 当可用宽度过小时，自动隐藏右侧列表，宽度恢复后自动显示
class LayoutRoomScreenWidget extends StatelessWidget {
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
  final void Function(Participant participant)? onParticipantTap;

  /// 低于此宽度时自动隐藏右侧参与者列表
  static const double _sidebarBreakpoint = 480;

  const LayoutRoomScreenWidget({
    super.key,
    required this.screenParticipant,
    required this.otherParticipants,
    this.handRaiseMap = const {},
    this.onMute,
    this.onKick,
    this.onParticipantTap,
  });

  @override
  Widget build(BuildContext context) {
    // 黑底：contain 模式的信箱边与脚手架浅色底会形成白色留白，
    // 黑底可让共享画面恰好就是视频大小，黑边与视频黑底融为一体。
    return ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showSidebar =
              otherParticipants.length > 2 &&
              otherParticipants.isNotEmpty &&
              constraints.maxWidth >= _sidebarBreakpoint;

          final main = ParticipantTile(
            participant: screenParticipant,
            handRaised: handRaiseMap[screenParticipant.identity] == true,
            onMute: onMute,
            onKick: onKick,
            onTap: () => onParticipantTap?.call(screenParticipant),
            fit: VideoViewFit.contain,
            removePadding: true,
            key: ValueKey('${screenParticipant.sid}-screen'),
          );
          Widget thumbnail(Participant p) => ParticipantTile(
            participant: p,
            handRaised: handRaiseMap[p.identity] == true,
            onMute: onMute,
            onKick: onKick,
            onTap: () => onParticipantTap?.call(p),
            key: ValueKey(p.sid),
          );

          // 1v1 / 1v2 共享：主画面独占整宽，其余人悬浮小窗，不再用侧栏挤压主画面。
          if (!showSidebar && otherParticipants.length <= 2) {
            return _buildOverlayLayout(main, thumbnail);
          }

          if (!showSidebar) {
            return Column(
              children: [
                Expanded(child: main),
                if (otherParticipants.isNotEmpty)
                  SizedBox(
                    height: 112,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: otherParticipants.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (_, index) => SizedBox(
                        width: 160,
                        child: thumbnail(otherParticipants[index]),
                      ),
                    ),
                  ),
              ],
            );
          }
          final sidebarWidth = (constraints.maxWidth * 0.2).clamp(180.0, 260.0);
          return Row(
            children: [
              Expanded(child: main),

              if (showSidebar) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: sidebarWidth,
                  child: ListView.separated(
                    itemCount: otherParticipants.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final p = otherParticipants[index];
                      return AspectRatio(
                        aspectRatio: 1.0,
                        child: thumbnail(p),
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// 共享全屏 + 其余人右下角悬浮小窗（1v1 / 1v2 共享专用）。
  ///
  /// 主画面独占整宽整高，无侧栏、无中间间隔；小窗叠加不参与布局，
  /// 因此共享区恰好就是视频区，不会被挤压出白色留白。
  Widget _buildOverlayLayout(
    Widget main,
    Widget Function(Participant p) thumbnail,
  ) {
    if (otherParticipants.isEmpty) return main;
    return Stack(
      fit: StackFit.expand,
      children: [
        main,
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < otherParticipants.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                SizedBox(
                  width: 200,
                  height: 150,
                  child: thumbnail(otherParticipants[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
