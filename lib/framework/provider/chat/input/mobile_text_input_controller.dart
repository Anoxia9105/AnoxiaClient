// controllers/mobile_text_input_controller.dart

import 'package:flutter/material.dart';

class MobileTextInputController extends ChangeNotifier {
  final TextEditingController textController = TextEditingController();
  final Map<String, int> _mentionMap = {};
  String _lastText = '';
  bool isEmpty = true;

  String get text => textController.text;

  void handleTextChanged(String value) {
    if (isEmpty != value.isEmpty) {
      isEmpty = value.isEmpty;
      notifyListeners();
    }
    _lastText = value;
  }

  /// 返回 true 表示用户刚输入了 @，调用方决定是否弹出面板
  bool checkMentionTrigger(String value) {
    final cursor = textController.selection.baseOffset;
    final isAppend = value.length > _lastText.length;
    return isAppend &&
        cursor > 0 &&
        cursor <= value.length &&
        value[cursor - 1] == '@';
  }

  void insertMention(int id, String name) {
    final text = textController.text;
    final cursor = textController.selection.baseOffset < 0
        ? text.length
        : textController.selection.baseOffset;
    final atIndex = text.lastIndexOf('@', cursor - 1 >= 0 ? cursor - 1 : 0);

    final String newText;
    final int newOffset;

    if (atIndex >= 0 && atIndex <= cursor) {
      newText =
          '${text.substring(0, atIndex)}@$name ${text.substring(cursor)}';
      newOffset = atIndex + name.length + 2;
    } else {
      newText =
          '${text.substring(0, cursor)}@$name ${text.substring(cursor)}';
      newOffset = cursor + name.length + 2;
    }

    textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
    _mentionMap[name] = id;
    _lastText = newText;
    if (isEmpty) {
      isEmpty = false;
      notifyListeners();
    }
  }

  void insertTextAtCursor(String insertText) {
    final text = textController.text;
    final cursor = textController.selection.baseOffset < 0
        ? text.length
        : textController.selection.baseOffset;

    final newText =
        '${text.substring(0, cursor)}$insertText${text.substring(cursor)}';
    textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + insertText.length),
    );
    _lastText = newText;
    if (isEmpty) {
      isEmpty = false;
      notifyListeners();
    }
  }

  /// 返回发送所需数据，调用方负责实际发送
  ({String text, List<int> mentionIds})? buildSendData() {
    final text = textController.text.trim();
    if (text.isEmpty) return null;

    final mentionIds = <int>{};
    for (final entry in _mentionMap.entries) {
      if (text.contains('@${entry.key}')) mentionIds.add(entry.value);
    }
    return (text: text, mentionIds: mentionIds.toList());
  }

  void clear() {
    textController.clear();
    _mentionMap.clear();
    _lastText = '';
    isEmpty = true;
    notifyListeners();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}