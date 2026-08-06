/// Quill 编辑器语法高亮渲染器。
///
/// 为 Quill 代码块和内联代码构建带有语法着色属性的文本跨度，
/// 同时保留 Quill 标准的 code-block 和 code 属性以保持可编辑性。
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:highlight/highlight.dart' as syntax;

import 'code_language.dart';
import 'quill_style_config.dart';

/// Builds Quill text spans with syntax colors while preserving Quill's
/// standard `code-block` and `code` attributes (and therefore editability).
abstract final class QuillSyntaxHighlighter {
  /// 构建语法高亮文本跨度。
  ///
  /// [context] 当前构建上下文，用于获取主题。
  /// [node] 当前 Quill 节点。
  /// [nodeOffset] 节点偏移量。
  /// [text] 原始文本。
  /// [style] 基础文本样式。
  /// [recognizer] 手势识别器。
  static InlineSpan buildSpan(
    BuildContext context,
    Node node,
    int nodeOffset,
    String text,
    TextStyle? style,
    GestureRecognizer? recognizer,
  ) {
    // Line.style 不继承父 Block 的 code-block 属性，需要向上遍历祖先链
    // 才能检测到代码块。结构：QuillText → Line → Block。
    var isCodeBlock = false;
    var ancestor = node.parent;
    while (ancestor != null) {
      if (ancestor.style.containsKey(Attribute.codeBlock.key)) {
        isCodeBlock = true;
        break;
      }
      ancestor = ancestor.parent;
    }
    final isInlineCode = node.style.containsKey(Attribute.inlineCode.key);
    final codeStyle = (isCodeBlock || isInlineCode)
        ? (style ?? const TextStyle()).merge(
            QuillStyleConfig.codeTextStyle(context),
          )
        : style;
    final language = isCodeBlock
        ? CodeLanguageDetector.resolveForLine(node.parent!)
        : CodeLanguageDetector.detect(text);

    final trimmedText = text.trim();
    if ((!isCodeBlock && !isInlineCode) ||
        language.id == CodeLanguageDetector.plainText.id ||
        trimmedText.isEmpty ||
        !_hasHighlightableContent(trimmedText)) {
      return _plainSpan(text, codeStyle, recognizer);
    }

    return _highlightedSpan(
      context,
      text,
      language.id,
      codeStyle,
      recognizer,
    );
  }

  /// 为一段完整代码文本构建语法高亮跨度（不依赖 Quill 节点）。
  ///
  /// 供 WASM 消息渲染等非编辑器场景复用；不识别时原样返回纯文本，
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
          // highlight 语法树中，实际文本在子节点（className=null），
          // 而 className 在父节点上（value 为空），需要向下传递才能生效。
          final effectiveBase = baseStyle?.merge(tokenStyle) ?? tokenStyle;
          return TextSpan(
            text: node.value,
            style: effectiveBase,
            children: node.children == null
                ? null
                : _convertNodes(node.children!, effectiveBase, theme),
          );
        })
        .toList(growable: false);
  }
}
