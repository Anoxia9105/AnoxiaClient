import 'package:anoxia/framework/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// 在线状态绿点（静态）
///
/// 原实现为无限透明度呼吸动画：Web 渲染下任何动画帧都会驱动整块 canvas
/// 重绘与合成（群聊 AppBar 常驻该组件），是 Safari 掉帧的来源之一，改为静态。
class BreathingDot extends StatelessWidget {
  const BreathingDot({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).extension<AppColors>()?.success ?? cs.primary,
      ),
    );
  }
}
