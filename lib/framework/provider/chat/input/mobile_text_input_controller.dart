import 'dart:convert';

import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 单个 @提及在输入框文本中的区间
class MentionSpan {
  final int start;
  final int end;
  final String name;
  final int id;

  const MentionSpan({
    required this.start,
    required this.end,
    required this.name,
    required this.id,
  });

  MentionSpan shifted(int delta) =>
      MentionSpan(start: start + delta, end: end + delta, name: name, id: id);
}

/// 带 @提及高亮渲染的文本编辑控制器
///
/// 重写 [TextEditingController.buildTextSpan]，把 @提及区间渲染成与桌面端
/// Quill mention embed 一致的样式（红色加粗 + 淡红底色），而底层文本仍是
/// 纯文本，不影响发送逻辑。
class MentionHighlightTextEditingController extends TextEditingController {
  /// 当前有效的 @提及区间（按 start 升序，互不重叠）
  List<MentionSpan> mentions = const [];

  static TextStyle _mentionStyle(TextStyle? base) {
    return (base ?? const TextStyle()).copyWith(
      color: Colors.red,
      fontWeight: FontWeight.bold,
      backgroundColor: Colors.red.withValues(alpha: 0.1),
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final currentValue = value;
    final text = currentValue.text;
    final hasComposing =
        withComposing &&
        currentValue.composing.isValid &&
        !currentValue.composing.isCollapsed;

    if (mentions.isEmpty && !hasComposing) {
      return TextSpan(style: style, text: text);
    }

    // 以提及区间边界与 IME 组合区间边界切分文本，避免高亮与组合下划线互相覆盖。
    final points = <int>{0, text.length};
    if (hasComposing) {
      final start = currentValue.composing.start;
      final end = currentValue.composing.end;
      if (start > 0 && start < text.length) points.add(start);
      if (end > 0 && end < text.length) points.add(end);
    }
    for (final span in mentions) {
      if (span.start > 0 && span.start < text.length) points.add(span.start);
      if (span.end > 0 && span.end < text.length) points.add(span.end);
    }
    final sorted = points.where((p) => p >= 0 && p <= text.length).toList()
      ..sort();

    final children = <TextSpan>[];
    for (var i = 0; i + 1 < sorted.length; i++) {
      final start = sorted[i];
      final end = sorted[i + 1];
      if (end <= start) continue;

      var segStyle = style;
      if (_mentionAt(start, end) != null) {
        segStyle = _mentionStyle(style);
      }
      if (hasComposing &&
          start >= currentValue.composing.start &&
          end <= currentValue.composing.end) {
        segStyle = (segStyle ?? const TextStyle()).copyWith(
          decoration: TextDecoration.underline,
        );
      }
      children.add(TextSpan(style: segStyle, text: text.substring(start, end)));
    }
    return TextSpan(style: style, children: children);
  }

  MentionSpan? _mentionAt(int start, int end) {
    for (final span in mentions) {
      if (span.start <= start && end <= span.end) return span;
    }
    return null;
  }
}

/// 移动端文本输入控制器
///
/// 专为移动端设计的文本输入控制器，提供以下功能：
/// - 管理输入框文本内容
/// - 支持 @提及用户功能（插入即高亮，样式与桌面端 Quill 保持一致）
/// - 追踪输入状态（是否为空）
/// - 构建发送数据（包含文本和提及用户ID列表）
///
/// 使用 Record 类型返回发送数据，避免定义额外的数据类
class MobileTextInputController extends ChangeNotifier {
  /// 文本编辑控制器（自带 @提及高亮渲染）
  final MentionHighlightTextEditingController textController =
      MentionHighlightTextEditingController();

  /// 上一次输入的文本（用于检测 @ 输入与同步提及区间）
  String _lastText = '';

  /// 输入框是否为空
  bool isEmpty = true;

  /// 获取当前输入的文本
  String get text => textController.text;

  /// 处理文本变化
  ///
  /// [value] 当前输入的文本内容
  ///
  /// 当输入状态（空/非空）变化时通知监听器
  void handleTextChanged(String value) {
    // 用户输入会改动提及区间的位置，先按编辑区位移同步区间。
    _syncMentionSpans(_lastText, value);
    if (isEmpty != value.isEmpty) {
      isEmpty = value.isEmpty;
      notifyListeners();
    }
    // 记录上次文本用于 @ 检测
    _lastText = value;
  }

  /// 检测是否触发 @提及
  ///
  /// [value] 当前输入的文本内容
  ///
  /// 返回 true 表示用户刚输入了 @，调用方决定是否弹出提及面板
  bool checkMentionTrigger(String value) {
    // 获取光标位置
    final cursor = textController.selection.baseOffset;
    // 判断是否为追加输入
    final isAppend = value.length > _lastText.length;
    // 检查是否在光标位置输入了 @
    return isAppend &&
        cursor > 0 &&
        cursor <= value.length &&
        value[cursor - 1] == '@';
  }

  /// 插入 @提及用户
  ///
  /// [id] 被提及用户的ID
  /// [name] 被提及用户的昵称
  ///
  /// 将 @昵称 插入到当前光标位置，并记录为高亮提及区间
  void insertMention(int id, String name) {
    final text = textController.text;
    // 获取光标位置，处理负数情况
    final cursor = textController.selection.baseOffset < 0
        ? text.length
        : textController.selection.baseOffset;

    // 查找光标前最近的 @ 符号位置
    final atIndex = text.lastIndexOf('@', cursor - 1 >= 0 ? cursor - 1 : 0);

    String newText;
    int newOffset;
    int mentionStart;

    // 如果找到 @ 符号，替换它及其后面的内容
    if (atIndex >= 0 && atIndex <= cursor) {
      newText = '${text.substring(0, atIndex)}@$name ${text.substring(cursor)}';
      newOffset = atIndex + name.length + 2; // +2 包含 @ 和空格
      mentionStart = atIndex;
    } else {
      // 否则在光标位置插入
      newText = '${text.substring(0, cursor)}@$name ${text.substring(cursor)}';
      newOffset = cursor + name.length + 2;
      mentionStart = cursor;
    }

    final oldText = textController.text;
    // 更新文本控制器
    textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );

    // 同步既有区间位移，再登记新插入的提及区间（@name 不含结尾空格）。
    _syncMentionSpans(oldText, newText);
    final next = [
      ...textController.mentions,
      MentionSpan(
        start: mentionStart,
        end: mentionStart + name.length + 1,
        name: name,
        id: id,
      ),
    ]..sort((a, b) => a.start.compareTo(b.start));
    textController.mentions = next;

    _lastText = newText;

    // 更新空状态
    if (isEmpty) {
      isEmpty = false;
      notifyListeners();
    }
  }

  /// 插入「@所有人」（仅群聊展示）。
  ///
  /// 占位用户 ID 使用 [kMentionAllUserId]，发送时从 mentionIds 中排除，
  /// 通过 [buildSendData] 的 mentionAll 标记单独透传。
  void insertMentionAll() {
    insertMention(kMentionAllUserId, 'mention_all'.tr());
  }

  /// 在光标位置插入文本
  ///
  /// [insertText] 要插入的文本内容
  void insertTextAtCursor(String insertText) {
    final text = textController.text;
    final cursor = textController.selection.baseOffset < 0
        ? text.length
        : textController.selection.baseOffset;

    // 在光标位置插入文本
    final newText =
        '${text.substring(0, cursor)}$insertText${text.substring(cursor)}';

    // 更新文本控制器
    textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + insertText.length),
    );

    // 光标之后的提及区间整体后移。
    _syncMentionSpans(text, newText);
    _lastText = newText;

    // 更新空状态
    if (isEmpty) {
      isEmpty = false;
      notifyListeners();
    }
  }

  /// 构建发送数据
  ///
  /// 返回包含文本、提及用户ID列表、是否@所有人及可选 quillDelta 的 Record，
  /// 文本为空时返回 null。
  /// 当存在有效 @提及时，[quillDelta] 为 Quill Delta JSON 字符串（与桌面端格式
  /// 一致），调用方应使用富文本消息类型发送；否则 [quillDelta] 为 null。
  ({String text, List<int> mentionIds, bool mentionAll, String? quillDelta})?
  buildSendData() {
    final full = textController.text;
    final text = full.trim();
    if (text.isEmpty) return null;

    // 只收集文本仍与 @昵称 相符的提及区间，避免用户手动改写后误发提醒。
    final validMentions = <MentionSpan>[];
    for (final span in textController.mentions) {
      if (span.start >= 0 &&
          span.end <= full.length &&
          full.substring(span.start, span.end) == '@${span.name}') {
        validMentions.add(span);
      }
    }
    validMentions.sort((a, b) => a.start.compareTo(b.start));

    // @所有人 占位 ID 不参与真实用户提醒
    final mentionAll = validMentions.any((s) => s.id == kMentionAllUserId);
    final mentionIds = validMentions
        .where((s) => s.id != kMentionAllUserId)
        .map((s) => s.id)
        .toSet()
        .toList();
    final quillDelta = validMentions.isNotEmpty
        ? _buildQuillDelta(full, validMentions)
        : null;

    return (
      text: text,
      mentionIds: mentionIds,
      mentionAll: mentionAll,
      quillDelta: quillDelta,
    );
  }

  /// 将纯文本 + @提及区间转换为与桌面端格式一致的 Quill Delta JSON 字符串。
  String _buildQuillDelta(String full, List<MentionSpan> mentions) {
    final ops = <Map<String, dynamic>>[];
    final content = full.trimRight();
    var cursor = 0;

    for (final span in mentions) {
      if (span.start >= content.length) break;
      final end = span.end.clamp(0, content.length);
      if (span.start > cursor) {
        ops.add({'insert': content.substring(cursor, span.start)});
      }
      ops.add({
        'insert': {
          'mention': jsonEncode({'userId': span.id, 'userName': span.name}),
        },
      });
      cursor = end;
    }
    // 剩余文本与终止换行合并为最后一个 op（Quill Delta 要求以 \n 结尾）。
    ops.add({'insert': '${content.substring(cursor)}\n'});

    return jsonEncode(ops);
  }

  /// 同步提及区间
  ///
  /// 通过公共前缀/后缀定位编辑区：完全位于编辑区之前的区间保持不变，
  /// 完全位于其后的区间整体位移 [delta]，与编辑区重叠（被改写）的区间丢弃。
  void _syncMentionSpans(String oldText, String newText) {
    if (oldText == newText) return;
    final spans = textController.mentions;
    if (spans.isEmpty) return;

    var prefix = 0;
    final minLen = oldText.length < newText.length
        ? oldText.length
        : newText.length;
    while (prefix < minLen && oldText[prefix] == newText[prefix]) {
      prefix++;
    }

    var oldSuffix = oldText.length;
    var newSuffix = newText.length;
    while (oldSuffix > prefix &&
        newSuffix > prefix &&
        oldText[oldSuffix - 1] == newText[newSuffix - 1]) {
      oldSuffix--;
      newSuffix--;
    }
    final delta = newText.length - oldText.length;

    final result = <MentionSpan>[];
    for (final span in spans) {
      if (span.end <= prefix) {
        result.add(span);
      } else if (span.start >= oldSuffix) {
        result.add(span.shifted(delta));
      }
      // 与编辑区重叠的提及被破坏，丢弃高亮，保留纯文本。
    }
    textController.mentions = result;
  }

  /// 程序化整体替换输入内容（AI 结果回填等场景）
  ///
  /// 直接给 `textController.value` 赋值不会触发 TextField 的 `onChanged`，
  /// 会导致空态（发送按钮显隐）与 @提及区间漂移；此方法补齐同步逻辑。
  ///
  /// [cursorOffset] 落点，缺省置于文末。
  void replaceAllText(String newText, {int? cursorOffset}) {
    final oldText = textController.text;
    final offset = (cursorOffset ?? newText.length).clamp(0, newText.length);
    textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: offset),
    );
    _syncMentionSpans(oldText, newText);
    _lastText = newText;

    final empty = newText.isEmpty;
    if (isEmpty != empty) {
      isEmpty = empty;
      notifyListeners();
    }
  }

  /// 原样还原一次 [replaceAllText] 之前的快照（供 AI 结果撤销使用）
  ///
  /// 与 [replaceAllText] 不同，这里不重算提及区间，直接恢复快照，
  /// 避免「回退」被当作一次新编辑而丢掉原有的 @提及高亮。
  void restoreText(
    String text,
    TextSelection selection,
    List<MentionSpan> mentions,
  ) {
    textController.value = TextEditingValue(text: text, selection: selection);
    textController.mentions = List<MentionSpan>.of(mentions);
    _lastText = text;

    final empty = text.isEmpty;
    if (isEmpty != empty) {
      isEmpty = empty;
      notifyListeners();
    }
  }

  /// 清空输入框
  ///
  /// 重置文本、提及区间和状态
  void clear() {
    textController.clear();
    textController.mentions = const [];
    _lastText = '';
    isEmpty = true;
    notifyListeners();
  }

  /// 释放资源
  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
