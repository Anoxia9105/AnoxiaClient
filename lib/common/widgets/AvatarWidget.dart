import 'package:anoxia/common/widgets/cached_network_image_view.dart';
import 'package:anoxia/framework/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 头像状态枚举
enum AvatarStatus { none, online, offline, busy }

/// 头像组件 (已优化：文字与背景色完美融合)
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
    this.size = 36,
    this.borderRadius = 6,
    this.status = AvatarStatus.none,
    this.statusWidget,
    this.showBadge = false,
    this.badgeText,
  });

  /// 🛠️ 核心算法：只基于第一个字，从系统预设的主题主色里挑颜色
  Color _getColorByName(BuildContext context, String? name) {
    if (name == null || name.isEmpty) {
      return Theme.of(context).colorScheme.primary;
    }

    final String firstChar = name.characters.first;

    int hash = 0;
    for (int i = 0; i < firstChar.length; i++) {
      hash = firstChar.codeUnitAt(i) + ((hash << 5) - hash);
    }

    final int themeIndex = hash.abs() % AppTheme.themes.length;
    final selectedColor = AppTheme.themes[themeIndex].color;

    return selectedColor ?? Theme.of(context).colorScheme.primary;
  }

  /// 文字颜色100%融入背景，彻底告别死板纯白
  Color _getTextColor(Color backgroundColor) {
    // 1. 计算背景色相对亮度
    final double luminance = backgroundColor.computeLuminance();

    // 2. 将背景色转为 HSL 颜色空间，准备精准操控
    final hsl = HSLColor.fromColor(backgroundColor);

    // 情况 A：如果背景色是非常淡的浅色 (亮度 > 0.6)
    if (luminance > 0.6) {
      // 文字采用：同色系大幅加深（降亮度）
      return hsl
          .withLightness((hsl.lightness - 0.45).clamp(0.0, 1.0))
          .toColor();
    }

    // 情况 B：如果背景色是中等或深色 (亮度 <= 0.6)
    // 绝对不用纯白！而是将当前背景色提取后，强行变成“极淡、柔和的同色系字”
    return hsl
        .withSaturation((hsl.saturation * 0.3).clamp(0.0, 0.4)) // 降低饱和度，避免变成荧光字
        .withLightness(0.94) // 强行把亮度拉到 94% 的极亮状态（代替纯白）
        .toColor();
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
              ? CachedNetworkImageView(
                  maxWidthDiskCache: (size * 3).toInt(),
                  maxHeightDiskCache: (size * 3).toInt(),
                  filterQuality: FilterQuality.low,
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
              widthFactor: 1.0,
              heightFactor: 1.0,
              child: Text(
                badgeText!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.25,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
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
      final backgroundColor = _getColorByName(context, name);

      // 🛠️ 核心优化：动态获取融合后的文字颜色
      final textColor = _getTextColor(backgroundColor);

      return Container(
        width: size,
        height: size,
        color: backgroundColor,
        alignment: Alignment.center,
        child: Text(
          displayText,
          style: TextStyle(
            fontSize: size * 0.45,
            color: textColor,
            fontWeight: FontWeight.bold,
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
