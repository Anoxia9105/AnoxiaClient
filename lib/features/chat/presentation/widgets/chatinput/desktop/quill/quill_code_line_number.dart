import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Builds a clearly visible leading number for every code-block line.
abstract final class QuillCodeLineNumber {
  static Widget? build(Node node, LeadingConfig config) {
    if (config.attribute.key != Attribute.codeBlock.key) {
      return null;
    }

    final lineNumber = config.getIndexNumberByIndent ?? '${config.index ?? 1}';
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          alignment: AlignmentDirectional.topEnd,
          width: (config.width ?? 32).clamp(32.0, double.infinity).toDouble(),
          padding: const EdgeInsetsDirectional.only(end: 10),
          child: Text(
            lineNumber,
            textAlign: TextAlign.end,
            style: (config.style ?? const TextStyle()).copyWith(
              color: colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
              fontSize: 12,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        );
      },
    );
  }
}
