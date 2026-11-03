import 'package:flutter/material.dart';
import 'radius_token.dart';

/// 聊天输入框和同类编辑面板共用的浅描边。
abstract final class ComposerFrame {
  static const radius = BorderRadius.all(Radius.circular(RadiusToken.lg));

  static BorderSide side(ColorScheme colors) =>
      BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6));

  static OutlineInputBorder input(ColorScheme colors, {bool focused = false}) =>
      OutlineInputBorder(
        borderRadius: radius,
        borderSide: focused ? BorderSide(color: colors.primary) : side(colors),
      );
}
