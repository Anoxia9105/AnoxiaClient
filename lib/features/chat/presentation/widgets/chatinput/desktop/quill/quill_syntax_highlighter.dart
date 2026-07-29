import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:highlight/highlight.dart' as syntax;

/// Builds Quill text spans with syntax colors while preserving Quill's
/// standard `code-block` and `code` attributes (and therefore editability).
abstract final class QuillSyntaxHighlighter {
  static InlineSpan buildSpan(
    BuildContext context,
    Node node,
    int nodeOffset,
    String text,
    TextStyle? style,
    GestureRecognizer? recognizer,
  ) {
    final isCodeBlock =
        node.parent?.style.containsKey(Attribute.codeBlock.key) ?? false;
    final isInlineCode = node.style.containsKey(Attribute.inlineCode.key);

    final trimmedText = text.trim();
    if ((!isCodeBlock && !isInlineCode) ||
        trimmedText.isEmpty ||
        !_hasHighlightableContent(trimmedText)) {
      return _plainSpan(text, style, recognizer);
    }

    try {
      // Auto detection invokes every registered language parser. Some of them
      // print FormatExceptions for valid, incomplete editor input (for example
      // "^" and "="). A fixed C-style grammar keeps highlighting deterministic
      // while the user is typing.
      final result = syntax.highlight.parse(text, language: 'dart');
      final theme = Theme.of(context).brightness == Brightness.dark
          ? monokaiSublimeTheme
          : githubTheme;
      return TextSpan(
        style: style,
        recognizer: recognizer,
        mouseCursor: recognizer == null ? null : SystemMouseCursors.click,
        children: _convertNodes(result.nodes ?? const [], style, theme),
      );
    } catch (_) {
      // Highlighting is presentation-only; malformed or unknown code must
      // never prevent Quill from rendering/editing the original text.
      return _plainSpan(text, style, recognizer);
    }
  }

  /// Auto detection runs language-specific number parsers. Incomplete input
  /// such as "^" or "=" is not useful to highlight and can make those parsers
  /// throw a [FormatException] while the user is still typing.
  static bool _hasHighlightableContent(String text) {
    return text.runes.any((rune) {
      return (rune >= 0x30 && rune <= 0x39) ||
          (rune >= 0x41 && rune <= 0x5A) ||
          (rune >= 0x61 && rune <= 0x7A) ||
          rune > 0x7F;
    });
  }

  static TextSpan _plainSpan(
    String text,
    TextStyle? style,
    GestureRecognizer? recognizer,
  ) {
    return TextSpan(
      text: text,
      style: style,
      recognizer: recognizer,
      mouseCursor: recognizer == null ? null : SystemMouseCursors.click,
    );
  }

  static List<TextSpan> _convertNodes(
    List<syntax.Node> nodes,
    TextStyle? baseStyle,
    Map<String, TextStyle> theme,
  ) {
    return nodes
        .map((node) {
          final tokenStyle = node.className == null
              ? null
              : theme[node.className];
          return TextSpan(
            text: node.value,
            style: baseStyle?.merge(tokenStyle) ?? tokenStyle,
            children: node.children == null
                ? null
                : _convertNodes(node.children!, baseStyle, theme),
          );
        })
        .toList(growable: false);
  }
}
