// Quill 编辑器语法高亮渲染器。
//
// 为 Quill 内联代码构建带有语法着色属性的文本跨度，
// 保留 Quill 标准的 code 属性以保持可编辑性。
//
// 代码块不再在 Quill 编辑器中渲染，而是通过自定义对话框发送。
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:highlight/highlight.dart' as syntax;

import 'code_language.dart';
import 'quill_style_config.dart';

abstract final class QuillSyntaxHighlighter {
  /// 构建语法高亮文本跨度（仅处理内联代码）。
  static InlineSpan buildSpan(
    BuildContext context,
    Node node,
    int nodeOffset,
    String text,
    TextStyle? style,
    GestureRecognizer? recognizer,
  ) {
    final isInlineCode = node.style.containsKey(Attribute.inlineCode.key);
    if (!isInlineCode) {
      return TextSpan(
        text: text,
        style: style,
        recognizer: recognizer,
        mouseCursor: recognizer == null ? null : SystemMouseCursors.click,
      );
    }

    final codeStyle = (style ?? const TextStyle()).merge(
      QuillStyleConfig.codeTextStyle(context),
    );
    final language = CodeLanguageDetector.detect(text);

    if (language.id == CodeLanguageDetector.plainText.id ||
        text.trim().isEmpty ||
        !_hasHighlightableContent(text)) {
      return _plainSpan(text, codeStyle, recognizer);
    }

    return _highlightedSpan(context, text, language.id, codeStyle, recognizer);
  }

  /// 为一段完整代码文本构建语法高亮跨度（不依赖 Quill 节点）。
  ///
  /// 供代码消息渲染等非编辑器场景复用；不识别时原样返回纯文本，
  /// 高亮失败也不影响文本显示。
  static InlineSpan buildCodeSpan(
    BuildContext context,
    String code,
    String languageId,
    TextStyle? style,
  ) {
    final trimmedText = code.trim();
    if (languageId == CodeLanguageDetector.plainText.id ||
        trimmedText.isEmpty ||
        !_hasHighlightableContent(trimmedText)) {
      return _plainSpan(code, style, null);
    }
    return _highlightedSpan(context, code, languageId, style, null);
  }

  static InlineSpan _highlightedSpan(
    BuildContext context,
    String text,
    String languageId,
    TextStyle? style,
    GestureRecognizer? recognizer,
  ) {
    try {
      final result = syntax.highlight.parse(text, language: languageId);
      final nodes = result.nodes;
      if (nodes == null) {
        return _plainSpan(text, style, recognizer);
      }
      final theme = Theme.of(context).brightness == Brightness.dark
          ? monokaiSublimeTheme
          : githubTheme;
      return TextSpan(
        style: style,
        recognizer: recognizer,
        mouseCursor: recognizer == null ? null : SystemMouseCursors.click,
        children: _convertNodes(nodes, style, theme),
      );
    } catch (_) {
      return _plainSpan(text, style, recognizer);
    }
  }

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
    final spans = <TextSpan>[];
    for (final node in nodes) {
      final tokenStyle = node.className == null
          ? null
          : theme[node.className];
      final effectiveBase = baseStyle?.merge(tokenStyle) ?? tokenStyle;
      final value = node.value;
      final children = node.children;
      if (value == null && children == null) continue;
      if (children == null) {
        spans.add(TextSpan(text: value, style: effectiveBase));
      } else {
        spans.add(TextSpan(
          style: effectiveBase,
          children: _convertNodes(children, effectiveBase, theme),
        ));
      }
    }
    return spans;
  }
}
