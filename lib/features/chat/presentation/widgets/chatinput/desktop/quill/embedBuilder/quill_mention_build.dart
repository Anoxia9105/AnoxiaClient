import 'package:anoxia/features/chat/presentation/widgets/mention_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// @提及的 Embed 构建器
/// 用于在富文本编辑器中显示@某人的特殊样式
class QuillMentionBuild implements EmbedBuilder {
  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    // 解析 mention 数据
    final data = embedContext.node.value.data;
    final String userName = MentionUser.displayName(data) ?? '--';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '@$userName',
        style: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  WidgetSpan buildWidgetSpan(Widget widget) {
    return WidgetSpan(child: widget, alignment: PlaceholderAlignment.middle);
  }

  @override
  String get key => 'mention';

  @override
  bool get expanded => false;

  @override
  String toPlainText(Embed node) {
    final userName = MentionUser.displayName(node.value.data) ?? '';
    return '@$userName';
  }
}
