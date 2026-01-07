import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class AvatarWidget extends StatelessWidget {
  final String? url;
  final String? name;
  final double size;
  final double borderRadius;

  const AvatarWidget({
    super.key,
    this.url,
    this.name,
    this.size = 40,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: hasUrl
          ? Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,

        /// 加载中显示默认图标
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder(context);
        },

        /// 加载失败显示兜底图标或首字母
        errorBuilder: (_, __, ___) => _buildNameOrPlaceholder(context),
      )
          : _buildNameOrPlaceholder(context),
    );
  }

  /// 有名字 → 显示首字母
  /// 无名字 → 显示默认图标
  Widget _buildNameOrPlaceholder(BuildContext context) {
    if (name != null && name!.isNotEmpty) {
      final displayText = name!.characters.first.toUpperCase();
      return Container(
        width: size,
        height: size,
        color: Theme.of(context).colorScheme.primary,
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

    return _buildPlaceholder(context);
  }

  /// 默认占位图标（加载中 & 无头像）
  Widget _buildPlaceholder(BuildContext context) {
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
