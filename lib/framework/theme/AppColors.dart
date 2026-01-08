import 'package:flutter/material.dart';

/// 主题扩展类
///
/// 作者: anoxia
///
/// 版本: 1.0.0
///
/// 创建时间: 2025-09-16  18:03
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Gradient? scaffoldGradient;

  const AppColors({this.scaffoldGradient});

  @override
  AppColors copyWith({Gradient? scaffoldGradient}) {
    return AppColors(
      scaffoldGradient: scaffoldGradient ?? this.scaffoldGradient,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      scaffoldGradient: Gradient.lerp(scaffoldGradient, other.scaffoldGradient, t) ?? scaffoldGradient, // 兜底防止返回空
    );
  }
}