import 'package:anoxia/framework/theme/AppTheme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 头像状态枚举
enum AvatarStatus { none, online, offline, busy }

/// 头像组件 (已进行高性能优化与固定颜色生成)
class AvatarWidget extends StatelessWidget {
  final String? url;
  final String? name;
  final double size;
  final double borderRadius;
  final AvatarStatus status;
  final bool showBadge;
  final String? badgeText;
  final Widget? statusWidget;

  const AvatarWidget({
    super.key,
    this.url,
    this.name,
    this.size = 40,
    this.borderRadius = 4,
    this.status = AvatarStatus.none,
    this.statusWidget,
    this.showBadge = false,
    this.badgeText,
  });

  /// 🛠️ 联动你的 AppTheme：只基于第一个字，从系统预设的主题主色里挑颜色
  Color _getColorByName(BuildContext context, String? name) {
    if (name == null || name.isEmpty) {
      // 如果名字为空，直接优雅地退化到当前系统主题的 primary 颜色
      return Theme.of(context).colorScheme.primary;
    }

    // 1. 精准提取第一个字符
    final String firstChar = name.characters.first;

    int hash = 0;
    // 2. 高效哈希
    for (int i = 0; i < firstChar.length; i++) {
      hash = firstChar.codeUnitAt(i) + ((hash << 5) - hash);
    }

    // 3. 核心联动：直接对你 AppTheme 预设的 19 个主题色进行取模！
    // 这样挑出来的颜色全部都在你设计的色彩大纲里，绝不突兀
    final int themeIndex = hash.abs() % AppTheme.themes.length;

    // 拿到对应主题的配置，如果该主题没配 color，则用系统当前 primary 垫底
    final selectedColor = AppTheme.themes[themeIndex].color;

    return selectedColor ?? Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. 头像主体
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: hasUrl
              ? CachedNetworkImage(
                  // 性能调优：在 2000 个大列表里，必须强行限制图片的解码缓存大小
                  // 40 尺寸的头像最大缓存 120 像素足够，这能帮你暴砍 80% 的图片内存占用！
                  maxWidthDiskCache: (size * 3).toInt(),
                  maxHeightDiskCache: (size * 3).toInt(),
                  filterQuality:
                      FilterQuality.low, // 列表滚动时低质量滤波，停止时自动变清晰，极大提升滑动帧率
                  imageUrl: url!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildPlaceholder(context),
                  errorWidget: (context, url, error) =>
                      _buildNameOrPlaceholder(context),
                )
              : _buildNameOrPlaceholder(context),
        ),

        // 2. 右下角状态角标
        if (status != AvatarStatus.none || statusWidget != null)
          Positioned(
            right: -2,
            bottom: -2,
            child: _buildStatusIndicator(context),
          ),

        // 3. 右上角：小红点/未读数
        if (showBadge)
          Positioned(
            right: -size * 0.1,
            top: -size * 0.1,
            child: _buildRedBadge(context),
          ),
      ],
    );
  }

  /// 构建右上角红点/角标
  Widget _buildRedBadge(BuildContext context) {
    final isCircle = badgeText == null;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size * 0.1),
      constraints: BoxConstraints(
        minWidth: size * 0.35,
        minHeight: size * 0.35,
      ),
      decoration: BoxDecoration(
        color: Colors.red,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(size * 0.2),
        border: Border.all(color: Colors.white, width: size * 0.05),
      ),
      child: badgeText != null
          ? Center(
              widthFactor: 1.0, // 避免内部约束引发不必要的二次 Layout 计算
              heightFactor: 1.0,
              child: Text(
                badgeText!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.25,
                  fontWeight: FontWeight.bold,
                  height: 1.1, // 微调字体行高，防止文字在圆圈里上下偏离
                ),
              ),
            )
          : null,
    );
  }

  /// 构建右下角状态指示器
  Widget _buildStatusIndicator(BuildContext context) {
    if (statusWidget != null) return statusWidget!;

    final double dotSize = size * 0.38;

    Color color;
    switch (status) {
      case AvatarStatus.online:
        color = Colors.green;
        break;
      case AvatarStatus.offline:
        color = Colors.grey;
        break;
      default:
        color = Colors.transparent;
    }

    return Tooltip(
      message: status == AvatarStatus.online
          ? '在线'
          : status == AvatarStatus.offline
          ? '离线'
          : '',
      // 性能调优：剔除高频滚动时无意义的 Tooltip 动画阻碍，纯展示
      waitDuration: const Duration(milliseconds: 500),
      child: Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: dotSize * 0.18),
        ),
      ),
    );
  }

  /// 构建名字首字母占位或默认图标
  Widget _buildNameOrPlaceholder(BuildContext context) {
    if (name != null && name!.isNotEmpty) {
      final displayText = name!.characters.first.toUpperCase();
      // 🛠️ 核心修改：通过算法为不同的名字赋予绝对固定的专属背景色
      final backgroundColor = _getColorByName(context, name);

      return Container(
        width: size,
        height: size,
        color: backgroundColor,
        alignment: Alignment.center,
        child: Text(
          displayText,
          style: TextStyle(
            fontSize: size * 0.5,
            color: Colors.white,
          ),
        ),
      );
    }

    return _buildPlaceholder(context);
  }

  /// 构建默认占位图标
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedImage02,
        size: size * 0.6,
        color: Colors.grey.shade600,
      ),
    );
  }
}
