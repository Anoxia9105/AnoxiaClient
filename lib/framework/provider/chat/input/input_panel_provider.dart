import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'input_panel_provider.g.dart';

enum InputPanel { none, more, emoji }

@riverpod
class InputPanelNotifier extends _$InputPanelNotifier {
  @override
  InputPanel build() => InputPanel.none;

  Future<void> toggle(InputPanel panel, FocusNode focusNode) async {
    if (state == panel) {
      state = InputPanel.none;
      await Future.delayed(const Duration(milliseconds: 50));
      focusNode.requestFocus();
      return;
    }
    if (focusNode.hasFocus) {
      focusNode.unfocus();
      await Future.delayed(const Duration(milliseconds: 250));
    }
    state = panel;
  }

  void closePanel() {
    // 只关面板，不动焦点——用于"获得焦点时收起面板"
    state = InputPanel.none;
  }

  void closeAll(FocusNode focusNode) {
    // 关面板 + 收键盘——用于发送、语音模式切换等主动关闭场景
    state = InputPanel.none;
    focusNode.unfocus();
  }
}
