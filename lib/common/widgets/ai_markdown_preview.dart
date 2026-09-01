/// AI Markdown 预览（note / chat 共用）
///
/// 基于 flutter_markdown，支持 GFM（表格/任务列表等）、代码块、引用、
/// 分割线等；与 note 的 Quill 编辑器渲染保持一致的视觉风格。
/// 可选中，流式增量渲染友好。
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

class AiMarkdownPreview extends StatelessWidget {
  const AiMarkdownPreview({
    super.key,
    required this.data,
    this.selectable = true,
    this.shrinkWrap = true,
  });

  final String data;
  final bool selectable;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 空内容兜底由调用方处理，这里直接渲染
    return MarkdownBody(
      data: data,
      selectable: selectable,
      shrinkWrap: shrinkWrap,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      styleSheet: MarkdownStyleSheet(
        // 基础段落
        p: textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          height: 1.7,
          color: cs.onSurface,
        ),
        // 标题
        h1: textTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          height: 1.4,
          color: cs.onSurface,
        ),
        h2: textTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.4,
          color: cs.onSurface,
        ),
        h3: textTheme.titleSmall?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.4,
          color: cs.onSurface,
        ),
        h4: textTheme.titleSmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        // 列表
        listBullet: textTheme.bodyMedium?.copyWith(fontSize: 13, color: cs.onSurface),
        // 引用
        blockquote: textTheme.bodyMedium?.copyWith(
          fontSize: 12,
          height: 1.6,
          color: cs.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: .35),
          border: Border(left: BorderSide(color: cs.primary.withValues(alpha: .6), width: 3)),
          borderRadius: BorderRadius.circular(RadiusToken.sm),
        ),
        blockquotePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        // 行内代码
        code: textTheme.bodyMedium?.copyWith(
          fontSize: 12,
          fontFamily: 'monospace',
          backgroundColor: cs.surfaceContainerHighest.withValues(alpha: .7),
          color: cs.onSurface,
        ),
        // 代码块
        codeblockDecoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: .65),
          borderRadius: BorderRadius.circular(RadiusToken.md),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: .5)),
        ),
        codeblockPadding: const EdgeInsets.all(10),
        // 链接
        a: TextStyle(color: cs.primary, decoration: TextDecoration.underline),
        // 分割线
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: .7), width: 1)),
        ),
        // 表格
        tableHead: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
        tableBody: textTheme.bodySmall?.copyWith(color: cs.onSurface),
        tableBorder: TableBorder.all(color: cs.outlineVariant.withValues(alpha: .5), width: .5),
        tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        // 强调
        em: const TextStyle(fontStyle: FontStyle.italic),
        strong: const TextStyle(fontWeight: FontWeight.w700),
      ),
      onTapLink: (text, href, title) {
        if (href == null) return;
        final uri = Uri.tryParse(href);
        if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      builders: {
        'code': _CodeBlockBuilder(cs),
      },
    );
  }
}

/// 代码块自定义：保留 flutter_markdown 默认但加圆角背景（可选扩展）
class _CodeBlockBuilder extends MarkdownElementBuilder {
  final ColorScheme cs;
  _CodeBlockBuilder(this.cs);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // 让 MarkdownBody 的默认 codeblockDecoration 生效，这里不额外处理
    return null;
  }
}
