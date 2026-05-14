import 'dart:ui';

import 'package:flutter/material.dart';

/// 模糊背景组件
///
/// 使用 BackdropFilter 实现毛玻璃模糊效果。
class BlurBackground extends StatelessWidget {
  /// 子组件
  final Widget child;

  /// 模糊强度
  final double sigma;

  const BlurBackground({
    super.key,
    required this.child,
    this.sigma = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      ),
    );
  }
}
