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

  /// 语义色：成功（上传成功、在线、已送达等）
  final Color success;

  /// 语义色：警告
  final Color warning;

  /// 语义色：危险/错误（与 colorScheme.error 保持同源，但作为扩展令牌可被业务统一引用）
  final Color danger;

  /// 语义色：信息/中性提示
  final Color info;

  /// 渐变/深色 hero 背景上的前景色（标题、按钮文字等）
  final Color onGradient;

  const AppColors({
    this.scaffoldGradient,
    this.success = const Color(0xFF2E7D32),
    this.warning = const Color(0xFF8A5A00),
    this.danger = const Color(0xFFB3261E),
    this.info = const Color(0xFF455A64),
    this.onGradient = Colors.white,
  });

  @override
  AppColors copyWith({
    Gradient? scaffoldGradient,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? onGradient,
  }) {
    return AppColors(
      scaffoldGradient: scaffoldGradient ?? this.scaffoldGradient,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      onGradient: onGradient ?? this.onGradient,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      scaffoldGradient: Gradient.lerp(scaffoldGradient, other.scaffoldGradient, t) ?? scaffoldGradient, // 兜底防止返回空
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      info: Color.lerp(info, other.info, t) ?? info,
      onGradient: Color.lerp(onGradient, other.onGradient, t) ?? onGradient,
    );
  }
}
