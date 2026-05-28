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

  void closeAll(FocusNode focusNode) {
    state = InputPanel.none;
    focusNode.unfocus();
  }
}