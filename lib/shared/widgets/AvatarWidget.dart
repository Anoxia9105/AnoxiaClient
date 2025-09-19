import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class AvatarWidget extends StatelessWidget {
  final String? url;
  final String? name;
  final double size;

  const AvatarWidget({
    super.key,
    this.url,
    this.name,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: url != null && url!.isNotEmpty
          ? Image.network(
              url!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildNameOrPlaceholder(),
            )
          : _buildNameOrPlaceholder(),
    );
  }

  /// 构建名字头像或者兜底图标
  Widget _buildNameOrPlaceholder() {
    if (name != null && name!.isNotEmpty) {
      // 显示名字的首字
      final displayText = name!.characters.first.toUpperCase();
      return Container(
        width: size,
        height: size,
        color: Colors.blueGrey, // 你可以改成随机颜色或者主题色
        alignment: Alignment.center,
        child: Text(
          displayText,
          style: TextStyle(
            fontSize: size * 0.5,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // 没有名字时兜底显示图标
    return Container(
      width: size,
      height: size,
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedImageNotFound01,
        size: size * 0.6,
        color: Colors.grey.shade600,
      ),
    );
  }
}
