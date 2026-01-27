import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

enum AvatarStatus { none, online, offline, busy }

class AvatarWidget extends StatelessWidget {
  final String? url;
  final String? name;
  final double size;
  final double borderRadius;

  /// 状态（右下角）
  final AvatarStatus status;

  final bool showBadge; // 是否显示红点/角标
  final String? badgeText; // 角标显示的文字（如未读数）

  /// 自定义状态 Widget（优先级高于 status）
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
        /// 头像主体
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: hasUrl
              ? CachedNetworkImage(
                  filterQuality: FilterQuality.high,
                  imageUrl: url!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,

                  /// 加载中显示默认图标
                  placeholder: (context, url) {
                    return _buildPlaceholder(context);
                  },

                  /// 加载失败显示兜底图标或首字母
                  errorWidget: (context, url, error) =>
                      _buildNameOrPlaceholder(context),
                )
              : _buildNameOrPlaceholder(context),
        ),

        /// 右下角状态角标
        if (status != AvatarStatus.none || statusWidget != null)
          Positioned(
            right: -2,
            bottom: -2,
            child: _buildStatusIndicator(context),
          ),

        /// 右上角：小红点/未读数
        if (showBadge)
          Positioned(
            right: -size * 0.1,
            top: -size * 0.1,
            child: _buildRedBadge(context),
          ),
      ],
    );
  }

  /// 构建右上角红点
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

  /// 状态角标
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
