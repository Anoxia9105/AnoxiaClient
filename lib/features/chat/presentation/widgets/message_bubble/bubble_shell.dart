/// 带箭头的气泡外壳组件
///
/// 职责：为消息内容提供带方向箭头的背景容器，支持自定义颜色、圆角、边框。
/// 内部使用 [BubbleWidget] 实现，封装了主题适配。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anoxia/framework/provider/setting/chat_bubble_settings_provider.dart';
import 'package:anoxia/common/widgets/bubble_dialog.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 带箭头的气泡外壳
///
/// [isCurrentUser] 决定箭头方向（右箭头表示自己，左箭头表示对方）
/// [backgroundColor] 气泡背景色
/// [child] 内部内容
class BubbleShell extends ConsumerWidget {
  final bool isCurrentUser;
  final bool? placeOnLeft;
  final Color backgroundColor;
  final Widget child;

  const BubbleShell({
    super.key,
    required this.isCurrentUser,
    this.placeOnLeft,
    required this.backgroundColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(chatBubbleTailEnabledProvider)) {
      return BubbleWidget(
        arrowDirection: (placeOnLeft ?? !isCurrentUser)
            ? AxisDirection.left
            : AxisDirection.right,
        // 尖角固定靠上，保留足够高度避免与圆角相交。
        arrowOffset: 18,
        arrowLength: 6,
        arrowRadius: 2,
        arrowWidth: 8,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        backgroundColor: backgroundColor,
        contentBuilder: (_) => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 24),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            alignment: Alignment.centerLeft,
            child: child,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).toInt()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
