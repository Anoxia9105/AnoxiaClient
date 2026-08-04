import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 右上角气泡菜单公共构建工具
///
/// 聊天列表、联系人详情等页面右上角气泡菜单复用本工具，
/// 保证菜单项样式与气泡宽度计算完全一致。
class BubbleMenu {
  /// 菜单项图标宽度
  static const double iconWidth = 16;

  /// 图标与文案之间的间距
  static const double iconGap = 8;

  /// 菜单项水平内边距
  static const double itemHPadding = 8;

  /// 气泡内容容器水平内边距
  static const double containerHPadding = 3;

  /// 气泡宽度额外余量，避免气泡过窄
  static const double widthExtra = 12;

  /// 除文案外菜单项占用的固定宽度（图标 + 间距 + 各项水平内边距）
  static const double fixedContentWidth =
      iconWidth + iconGap + itemHPadding * 2 + containerHPadding * 2;

  /// 测量菜单气泡宽度：取所有文案中的最大宽度，加上图标、内边距
  /// 与额外余量，并以 [maxWidth] 为上限。
  static double measureWidth(
    BuildContext context, {
    required List<String> titles,
    required double maxWidth,
  }) {
    // 与 buildMenuItem 中 Text 的样式保持一致
    const style = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400);
    final textScaler = MediaQuery.textScalerOf(context);
    var maxTextWidth = 0.0;
    for (final title in titles) {
      final painter = TextPainter(
        text: TextSpan(text: title, style: style),
        textDirection: Directionality.of(context),
        textScaler: textScaler,
      )..layout();
      if (painter.width > maxTextWidth) maxTextWidth = painter.width;
    }
    return min(maxWidth, maxTextWidth + fixedContentWidth + widthExtra);
  }

  /// 构建菜单项：图标 + 固定宽度文案区域，所有菜单项等宽、内容居中
  static Widget buildMenuItem({
    required BuildContext context,
    required List<List<dynamic>> icon,
    required String title,
    required double textMaxWidth,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Colors.red
        : Theme.of(context).colorScheme.onSurface;
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: itemHPadding,
          vertical: 7,
        ),
        child: Row(
          // 固定每项文案区域宽度为 textMaxWidth，所有项等宽布局，文案居中显示
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: icon,
              size: iconWidth,
              color: color.withValues(alpha: 0.85),
            ),
            const SizedBox(width: iconGap),
            // 固定宽度而非 maxWidth：所有菜单项文案区域完全一致，防止长文溢出
            SizedBox(
              width: textMaxWidth,
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
