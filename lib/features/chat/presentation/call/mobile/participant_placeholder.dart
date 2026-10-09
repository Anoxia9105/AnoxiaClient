import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:flutter/material.dart';

/// 参与者占位组件（无视频时显示头像）
class ParticipantPlaceholder extends StatelessWidget {
  const ParticipantPlaceholder({
    super.key,
    required this.name,
    required this.avatar,
    required this.compact,
  });

  final String name;
  final String? avatar;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // 背景透明，主题卡片底由外层 MobileParticipantSurface 统一绘制，
    // 这里只负责居中的大头像 + 昵称。
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarWidget(
            url: avatar,
            name: name,
            size: compact ? 48 : 84,
            borderRadius: compact ? 24 : 42,
          ),
          if (!compact) ...[
            const SizedBox(height: 10),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
