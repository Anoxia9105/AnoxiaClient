import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 头像状态枚举
///
/// 用于显示头像右下角的在线状态指示器
enum AvatarStatus { none, online, offline, busy }

/// 头像组件
///
/// 展示用户头像，支持网络图片、占位图标和首字母展示。
/// 提供在线状态指示器、红点/未读数角标等功能。
class AvatarWidget extends StatelessWidget {
  /// 头像图片 URL
  final String? url;

  /// 备用显示名称（无图片时显示首字母）
  final String? name;

  /// 头像尺寸
  final double size;

  /// 头像圆角
  final double borderRadius;

  /// 在线状态指示器
  final AvatarStatus status;

  /// 是否显示右上角红点
  final bool showBadge;

  /// 红点显示的文字（如未读数）
  final String? badgeText;

  /// 自定义状态 Widget（优先级高于 [status]）
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

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 头像主体
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: hasUrl
              ? CachedNetworkImage(
                  filterQuality: FilterQuality.high,
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

        // 右下角状态角标
        if (status != AvatarStatus.none || statusWidget != null)
          Positioned(
            right: -2,
            bottom: -2,
            child: _buildStatusIndicator(context),
          ),

        // 右上角：小红点/未读数
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size * 0.1),
      constraints: BoxConstraints(
        minWidth: size * 0.35,
        minHeight: size * 0.35,
      ),
      decoration: BoxDecoration(
        color: Colors.red,
        shape: badgeText == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: badgeText == null
            ? null
            : BorderRadius.circular(size * 0.2),
        border: Border.all(color: Colors.white, width: size * 0.05),
      ),
      child: badgeText != null
          ? Center(
              child: Text(
                badgeText!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.25,
                  fontWeight: FontWeight.bold,
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

  /// 构建默认占位图标
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
