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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF252A38), Color(0xFF11131A)],
        ),
      ),
      child: Center(
        child: AvatarWidget(
          url: avatar,
          name: name,
          size: compact ? 42 : 72,
          borderRadius: compact ? 21 : 36,
        ),
      ),
    );
  }
}