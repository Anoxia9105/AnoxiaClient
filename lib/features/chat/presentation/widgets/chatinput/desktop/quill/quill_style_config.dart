import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class QuillStyleConfig {
  static DefaultStyles get(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String? fontFamily = theme.textTheme.bodyLarge?.fontFamily;

    final baseTextStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      color: color ?? colorScheme.onSurface,
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
      link: baseTextStyle.copyWith(
        color: Colors.blue,
        decoration: TextDecoration.underline,
      ),
      code: DefaultListBlockStyle(
        baseTextStyle.copyWith(color: Colors.white60, fontSize: 14),
        const HorizontalSpacing(4, 4),
        const VerticalSpacing(4, 4),
        const VerticalSpacing(4, 4),
        BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(4),
        ),
        null,
      ),
    );
  }
}
