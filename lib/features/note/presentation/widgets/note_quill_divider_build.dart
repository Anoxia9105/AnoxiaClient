import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// 记事本-水平分隔线嵌入构建器
///
/// 渲染笔记内的水平分隔线（横向实线）。embed 类型 `divider` 与
/// flutter_quill markdown 包内置的 [horizontalRule] 一致，
/// 保证 Markdown 导出（`---`）往返兼容。
class NoteQuillDividerBuild implements EmbedBuilder {
  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        thickness: 1,
        color: colorScheme.outline.withValues(alpha: .8),
      ),
    );
  }

  @override
  WidgetSpan buildWidgetSpan(Widget widget) => WidgetSpan(child: widget);

  @override
  String get key => 'divider';

  @override
  bool get expanded => true;

  @override
  String toPlainText(Embed node) => '';
}
