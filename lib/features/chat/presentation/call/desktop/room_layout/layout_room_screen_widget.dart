import 'package:anoxia/features/chat/presentation/call/component/participant_tile.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

/// 通话房间屏幕共享布局组件
///
/// 只要有屏幕共享就统一使用此布局（1v1 与多人一致）：
/// - 左侧共享视频区：外层主题卡片（圆角 12 + 内边距 8 + 阴影），
///   内层黑视频（圆角 8），contain 信箱边与视频黑底融合，左侧无白边
/// - 布局底色跟随主题（浅色浅底 / 深色深底）
/// - 右侧边栏动态显示其余参与者（随进出实时增减）
/// - 当可用宽度过小时，自动隐藏右侧列表为底部横滑条，宽度恢复后自动显示
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
    // 布局底色跟随主题；黑只压在共享主画面磁贴内部，
    // contain 信箱边落在磁贴黑底上，与视频黑底融合，左侧无白边。
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar =
            otherParticipants.isNotEmpty &&
            constraints.maxWidth >= _sidebarBreakpoint;

        // 共享主画面：外层主题卡片（内边距 8），内层黑视频磁贴（圆角 8）。
        final cs = Theme.of(context).colorScheme;
        final main = Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(RadiusToken.lg),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ParticipantTile(
            participant: screenParticipant,
            handRaised: handRaiseMap[screenParticipant.identity] == true,
            onMute: onMute,
            onKick: onKick,
            onTap: () => onParticipantTap?.call(screenParticipant),
            fit: VideoViewFit.contain,
            backgroundColor: Colors.black,
            borderRadius: RadiusToken.md,
            removePadding: true,
            key: ValueKey('${screenParticipant.sid}-screen'),
          ),
        );
        Widget thumbnail(Participant p) => ParticipantTile(
          participant: p,
          handRaised: handRaiseMap[p.identity] == true,
          onMute: onMute,
          onKick: onKick,
          onTap: () => onParticipantTap?.call(p),
          key: ValueKey(p.sid),
        );
        // 共享主画面固定 16:9：宽度决定高度，宽 1600 时高强制为 900，
        // 禁止卡片无限拉伸宽度，避免 contain 信箱产生大面积黑边。
        Widget mainBox() => Center(
          child: AspectRatio(aspectRatio: 16 / 9, child: main),
        );
        if (!showSidebar) {
          return Column(
            children: [
              Expanded(child: mainBox()),
              if (otherParticipants.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SizedBox(
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
                ),
            ],
          );
        }
        final sidebarWidth = (constraints.maxWidth * 0.2).clamp(180.0, 260.0);
        return Row(
          children: [
            Expanded(child: mainBox()),

            if (showSidebar) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: sidebarWidth,
                  child: ListView.separated(
                    itemCount: otherParticipants.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final p = otherParticipants[index];
                      return AspectRatio(aspectRatio: 1.0, child: thumbnail(p));
                    },
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
