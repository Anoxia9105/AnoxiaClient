import 'package:flutter/material.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 基础结构组件：圆角卡片包裹器
class RoomCard extends StatelessWidget {
  final Widget? child;
  final List<Widget>? children;

  const RoomCard({super.key, this.child, this.children}) : assert(child != null || children != null);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RadiusToken.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusToken.xl),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: children != null
            ? Column(mainAxisSize: MainAxisSize.min, children: children!)
            : child,
      ),
    );
  }
}