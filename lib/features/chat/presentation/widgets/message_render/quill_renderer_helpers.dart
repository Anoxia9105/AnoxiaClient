import 'dart:ui' as ui;

import 'package:anoxia/features/chat/presentation/widgets/mention_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// 解析 Quill 行内 attributes，合并到 [baseStyle] 上产出最终 [TextStyle]。
///
/// 支持 color/background/bold/italic/underline/strike/code/link/size/font。
/// `code` 行内代码使用 `surfaceContainerHighest` 作为底色与 monospace 字体；
/// `link` 未单独指定颜色时回退到 `Colors.blueAccent`。
TextStyle quillInlineStyle(
  BuildContext context,
  TextStyle baseStyle,
  dynamic attributes,
) {
  if (attributes is! Map) return baseStyle;

  final link = attributes['link']?.toString();
  final isInlineCode = attributes['code'] == true;
  final foreground = quillColor(attributes['color']);
  final background = quillColor(attributes['background']);
  final decorations = <TextDecoration>[
    if (attributes['underline'] == true || link?.isNotEmpty == true)
      TextDecoration.underline,
    if (attributes['strike'] == true) TextDecoration.lineThrough,
  ];

  return baseStyle.copyWith(
    color:
        foreground ??
        (link?.isNotEmpty == true ? Colors.blueAccent : baseStyle.color),
    backgroundColor:
        background ??
        (isInlineCode
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : null),
    fontWeight: attributes['bold'] == true ? FontWeight.bold : null,
    fontStyle: attributes['italic'] == true ? FontStyle.italic : null,
    fontSize: quillFontSize(attributes['size']),
    fontFamily: isInlineCode
        ? 'monospace'
        : quillFontFamily(attributes['font']),
    decoration: decorations.isEmpty
        ? null
        : TextDecoration.combine(decorations),
  );
}

/// 将 Quill 的 size 取值归一化为字号。
///
/// - 数字直接返回；
/// - `small` / `large` / `huge` 对应编辑器预设；
/// - 其它字符串尝试解析为数字。
double? quillFontSize(dynamic value) {
  if (value is num && value > 0) return value.toDouble();
  switch (value?.toString()) {
    case 'small':
      return 10;
    case 'large':
      return 18;
    case 'huge':
      return 32;
  }
  return double.tryParse(value?.toString() ?? '');
}

/// 将 Quill 的 font 取值规整为字体族名，空值返回 null 以保留继承。
String? quillFontFamily(dynamic value) {
  final font = value?.toString().trim();
  return font == null || font.isEmpty ? null : font;
}

/// 解析 Quill 颜色取值（int / #rgb / #rrggbb / rgb / rrggbb / aarrggbb）。
Color? quillColor(dynamic value) {
  if (value is int) return Color(value);
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) return null;

  var hex = raw.startsWith('#') ? raw.substring(1) : raw;
  if (hex.length == 3) {
    hex = hex.split('').map((char) => '$char$char').join();
  }
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;

  final parsed = int.tryParse(hex, radix: 16);
  return parsed == null ? null : Color(parsed);
}

/// 取 mention embed 的展示文本，缺失时回退到 `@--`。
String quillMentionText(dynamic rawData) {
  final userName = MentionUser.displayName(rawData);
  if (userName != null && userName.isNotEmpty) return '@$userName';
  return '@--';
}

/// mention 胶囊的裸样式（不含气泡 DefaultTextStyle 继承）。
TextStyle quillMentionStyle(BuildContext context) {
  return TextStyle(
    fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
    color: Colors.red,
    fontWeight: FontWeight.bold,
    fontSize: 14,
    height: 1,
  );
}

/// 测量 mention 胶囊的完整尺寸（含 margin：水平 2+2、垂直 0）。
///
/// mention 的 Text 位于 WidgetSpan 内，会继承气泡的 DefaultTextStyle
/// （例如 letterSpacing 0.25），实际渲染宽度大于裸样式。测量必须使用
/// 同一份合并样式，否则胶囊与气泡宽度都会小于真实文字宽度，导致
/// 最后一个字被挤换行/溢出（仅 WASM 手动渲染路径存在该问题）。
Size quillMentionSize(
  BuildContext context,
  dynamic rawData,
  TextScaler textScaler,
) {
  final style = DefaultTextStyle.of(
    context,
  ).style.merge(quillMentionStyle(context));
  final painter = TextPainter(
    text: TextSpan(text: quillMentionText(rawData), style: style),
    textDirection: ui.TextDirection.ltr,
    textScaler: textScaler,
    maxLines: 1,
  );
  painter.layout();

  // 组件完整尺寸（含 margin：水平 2+2、垂直 0）：
  // 宽 = 文本宽 + 水平 padding(4+4) + 水平 margin(2+2)
  // 高 = 文本高 + 垂直 padding(2+2)
  //
  // 注意：SizedBox.fromSize 会给 Container 施加紧约束，margin 会从
  // 尺寸内部扣除，因此 margin 必须计入尺寸，否则内容区比文本窄 4px。
  return Size(painter.width + 12, painter.height + 4);
}

/// Quill 文档总会以一个终止换行结尾。编辑器把它作为文档边界而非空白行，
/// 手动构造 TextSpan 时也必须去掉，否则消息气泡底部会多出一行高度。
///
/// 同时去除最后一个 op 的行尾空格：`computeLineMetrics` 不会计入行尾空白，
/// 但渲染时会保留，导致末尾多出不可见的换行。
String quillDisplayText(List<dynamic> ops, int index, String text) {
  if (index == ops.length - 1) {
    return text.trimRight();
  }
  return text;
}

/// 从原始 Delta ops 提取纯文本，绕过 flutter_quill Document。
String quillPlainTextFromOps(List<dynamic>? opsJson) {
  if (opsJson is! List) return '';
  final buffer = StringBuffer();
  for (final op in opsJson) {
    if (op is! Map) continue;
    final insert = op['insert'];
    if (insert is String) {
      buffer.write(insert);
    }
  }
  return buffer.toString();
}

/// 拼接用于链接预览的源文本：纯文本 + 各 op 的 link 属性。
String quillLinkPreviewSource(List<dynamic>? opsJson) {
  final buffer = StringBuffer(quillPlainTextFromOps(opsJson));
  if (opsJson is! List) return buffer.toString();

  for (final op in opsJson) {
    if (op is! Map) continue;
    final attributes = op['attributes'];
    if (attributes is! Map) continue;
    final link = attributes['link']?.toString();
    if (link == null || link.isEmpty) continue;
    buffer
      ..write(' ')
      ..write(link);
  }
  return buffer.toString();
}

/// 判断 Delta 是否需要占据整行宽度（代码块或非 mention embed）。
bool quillRequiresFullWidth(List<dynamic>? opsJson) {
  if (opsJson is! List) return false;

  for (final op in opsJson) {
    if (op is! Map) continue;
    final insert = op['insert'];
    final attributes = op['attributes'];
    if (attributes is Map) {
      if (attributes.containsKey(Attribute.codeBlock.key)) {
        return true;
      }
    }
    if (insert is Map && !insert.containsKey('mention')) return true;
  }
  return false;
}
