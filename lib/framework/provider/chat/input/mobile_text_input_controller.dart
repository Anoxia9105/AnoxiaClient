import 'package:flutter/material.dart';

/// 移动端文本输入控制器
///
/// 专为移动端设计的文本输入控制器，提供以下功能：
/// - 管理输入框文本内容
/// - 支持 @提及用户功能
/// - 追踪输入状态（是否为空）
/// - 构建发送数据（包含文本和提及用户ID列表）
///
/// 使用 Record 类型返回发送数据，避免定义额外的数据类
class MobileTextInputController extends ChangeNotifier {
  /// 文本编辑控制器
  final TextEditingController textController = TextEditingController();

  /// @提及用户映射表：用户名 -> 用户ID
  final Map<String, int> _mentionMap = {};

  /// 上一次输入的文本（用于检测 @ 输入）
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
    // 检测空状态变化
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
  /// 将 @昵称 插入到当前光标位置，并记录到提及映射表
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

    // 如果找到 @ 符号，替换它及其后面的内容
    if (atIndex >= 0 && atIndex <= cursor) {
      newText = '${text.substring(0, atIndex)}@$name ${text.substring(cursor)}';
      newOffset = atIndex + name.length + 2; // +2 包含 @ 和空格
    } else {
      // 否则在光标位置插入
      newText = '${text.substring(0, cursor)}@$name ${text.substring(cursor)}';
      newOffset = cursor + name.length + 2;
    }

    // 更新文本控制器
    textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );

    // 记录提及用户
    _mentionMap[name] = id;
    _lastText = newText;

    // 更新空状态
    if (isEmpty) {
      isEmpty = false;
      notifyListeners();
    }
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

    _lastText = newText;

    // 更新空状态
    if (isEmpty) {
      isEmpty = false;
      notifyListeners();
    }
  }

  /// 构建发送数据
  ///
  /// 返回包含文本和提及用户ID列表的 Record，文本为空时返回 null
  ///
  /// 使用 Record 类型：(text: 文本内容, mentionIds: 提及用户ID列表)
  ({String text, List<int> mentionIds})? buildSendData() {
    final text = textController.text.trim();
    if (text.isEmpty) return null;

    // 收集所有被提及的用户ID
    final mentionIds = <int>{};
    for (final entry in _mentionMap.entries) {
      if (text.contains('@${entry.key}')) {
        mentionIds.add(entry.value);
      }
    }

    return (text: text, mentionIds: mentionIds.toList());
  }

  /// 清空输入框
  ///
  /// 重置文本、提及映射和状态
  void clear() {
    textController.clear();
    _mentionMap.clear();
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