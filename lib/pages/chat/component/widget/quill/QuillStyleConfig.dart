import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class QuillStyleConfig {
  static DefaultStyles get(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String? fontFamily = theme.textTheme.bodyLarge?.fontFamily;

    final baseTextStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      color: colorScheme.onSurface,
    );

    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        baseTextStyle,
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
      placeHolder: DefaultTextBlockStyle(
        baseTextStyle.copyWith(color: colorScheme.onSurfaceVariant),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
      link: baseTextStyle.copyWith(color: Colors.blue, decoration: TextDecoration.underline),
    );
  }
}