import 'package:flutter/material.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 基础结构组件：圆角卡片包裹器
class RoomCard extends StatelessWidget {
  final Widget? child;
  final List<Widget>? children;

  const RoomCard({super.key, this.child, this.children}) : assert(child != null || children != null);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        clipBehavior: Clip.antiAlias,
        child: children != null
            ? Column(mainAxisSize: MainAxisSize.min, children: children!)
            : child,
      ),
    );
  }
}