/// 斜杠命令定义与过滤辅助。
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'note_quill_actions.dart';

/// 斜杠命令项。
class SlashCommand {
  final String labelKey;
  final List<String> keywords;
  final IconData icon;
  final Future<void> Function(
    BuildContext context,
    WidgetRef ref,
    QuillController controller,
    FocusNode focusNode,
  ) action;

  const SlashCommand(
    this.labelKey,
    this.keywords,
    this.icon,
    this.action,
  );
}

/// 保留拆分前的关键词前缀和本地化标签匹配行为。
bool slashCommandMatches(SlashCommand command, String query) {
  if (query.isEmpty) return true;
  final lowerQuery = query.toLowerCase();
  if (command.keywords.any(
    (keyword) => keyword.toLowerCase().startsWith(lowerQuery),
  )) {
    return true;
  }
  return command.labelKey.tr().toLowerCase().contains(lowerQuery);
}

/// 构建编辑器支持的全部斜杠命令。
List<SlashCommand> buildNoteSlashCommands() {
  return [
    SlashCommand(
      'toolbar_bold',
      const ['b', 'bold', '加粗'],
      Icons.format_bold,
      (context, ref, controller, focusNode) {
        noteToggleInline(controller, Attribute.bold);
        return Future.value();
      },
    ),
    SlashCommand(
      'toolbar_italic',
      const ['i', 'italic', '斜体'],
      Icons.format_italic,
      (context, ref, controller, focusNode) {
        noteToggleInline(controller, Attribute.italic);
        return Future.value();
      },
    ),
    SlashCommand(
      'toolbar_underline',
      const ['u', 'underline', '下划线'],
      Icons.format_underlined,
      (context, ref, controller, focusNode) {
        noteToggleInline(controller, Attribute.underline);
        return Future.value();
      },
    ),
    SlashCommand(
      'toolbar_strikethrough',
      const ['s', 'strike', '删除线'],
      Icons.format_strikethrough,
      (context, ref, controller, focusNode) {
        noteToggleInline(controller, Attribute.strikeThrough);
        return Future.value();
      },
    ),
    SlashCommand(
      'toolbar_inline_code',
      const ['code', 'inline', '行内代码'],
      Icons.code,
      (context, ref, controller, focusNode) {
        noteToggleInline(controller, Attribute.inlineCode);
        return Future.value();
      },
    ),
    SlashCommand(
      'toolbar_clear_format',
      const ['clear', '清除'],
      Icons.format_clear,
      (context, ref, controller, focusNode) {
        noteClearFormat(controller);
        return Future.value();
      },
    ),
    SlashCommand(
      'note_header_h1',
      const ['h1', '标题1', '#'],
      Icons.title,
      (context, ref, controller, focusNode) {
        controller.formatSelection(Attribute.h1);
        return Future.value();
      },
    ),
    SlashCommand(
      'note_header_h2',
      const ['h2', '标题2', '##'],
      Icons.title,
      (context, ref, controller, focusNode) {
        controller.formatSelection(Attribute.h2);
        return Future.value();
      },
    ),
    SlashCommand(
      'note_header_h3',
      const ['h3', '标题3', '###'],
      Icons.title,
      (context, ref, controller, focusNode) {
        controller.formatSelection(Attribute.h3);
        return Future.value();
      },
    ),
    SlashCommand(
      'note_header_normal',
      const ['p', 'normal', '正文'],
      Icons.text_fields,
      (context, ref, controller, focusNode) {
        controller.formatSelection(Attribute.clone(Attribute.header, null));
        return Future.value();
      },
    ),
    SlashCommand(
      'note_header_code',
      const ['codeblock', '代码块'],
      Icons.data_object,
      (context, ref, controller, focusNode) {
        controller.formatSelection(Attribute.codeBlock);
        return Future.value();
      },
    ),
    SlashCommand(
      'note_bullet_list',
      const ['ul', 'bullet', '无序'],
      Icons.format_list_bulleted,
      (context, ref, controller, focusNode) {
        controller.formatSelection(Attribute.ul);
        return Future.value();
      },
    ),
    SlashCommand(
      'note_ordered_list',
      const ['ol', 'ordered', '有序'],
      Icons.format_list_numbered,
      (context, ref, controller, focusNode) {
        controller.formatSelection(Attribute.ol);
        return Future.value();
      },
    ),
    SlashCommand(
      'note_task_list',
      const ['task', 'todo', '任务'],
      Icons.checklist,
      (context, ref, controller, focusNode) {
        controller.formatSelection(Attribute.checked);
        return Future.value();
      },
    ),
    SlashCommand(
      'toolbar_quote',
      const ['quote', '引用'],
      Icons.format_quote,
      (context, ref, controller, focusNode) {
        controller.formatSelection(Attribute.blockQuote);
        return Future.value();
      },
    ),
    SlashCommand(
      'note_link',
      const ['link', '链接'],
      Icons.link,
      (context, ref, controller, focusNode) =>
          noteSetLink(context, controller, focusNode),
    ),
    SlashCommand(
      'note_image',
      const ['img', 'image', '图片'],
      Icons.image,
      (context, ref, controller, focusNode) =>
          noteInsertImage(context, ref, controller, focusNode),
    ),
    SlashCommand(
      'note_horizontal_rule',
      const ['hr', 'divider', '分割线'],
      Icons.horizontal_rule,
      (context, ref, controller, focusNode) {
        noteInsertHorizontalRule(controller, focusNode);
        return Future.value();
      },
    ),
    SlashCommand(
      'note_align_left',
      const ['left', '左'],
      Icons.format_align_left,
      (context, ref, controller, focusNode) {
        controller.formatSelection(Attribute.leftAlignment);
        return Future.value();
      },
    ),
    SlashCommand(
      'note_align_center',
      const ['center', '居中'],
      Icons.format_align_center,
      (context, ref, controller, focusNode) {
        controller.formatSelection(Attribute.centerAlignment);
        return Future.value();
      },
    ),
    SlashCommand(
      'note_align_right',
      const ['right', '右'],
      Icons.format_align_right,
      (context, ref, controller, focusNode) {
        controller.formatSelection(Attribute.rightAlignment);
        return Future.value();
      },
    ),
    SlashCommand(
      'note_align_justify',
      const ['justify', '两端'],
      Icons.format_align_justify,
      (context, ref, controller, focusNode) {
        controller.formatSelection(Attribute.justifyAlignment);
        return Future.value();
      },
    ),
    SlashCommand(
      'toolbar_text_color',
      const ['color', '颜色'],
      Icons.palette,
      (context, ref, controller, focusNode) =>
          notePickColor(context, controller, focusNode, background: false),
    ),
    SlashCommand(
      'toolbar_bg_color',
      const ['bg', 'background', '背景'],
      Icons.format_color_fill,
      (context, ref, controller, focusNode) =>
          notePickColor(context, controller, focusNode, background: true),
    ),
  ];
}
