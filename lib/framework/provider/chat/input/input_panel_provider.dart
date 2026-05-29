import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'input_panel_provider.g.dart';

/// 输入面板类型枚举
///
/// 定义聊天输入区域的扩展面板类型
enum InputPanel {
  /// 无面板展开
  none,

  /// 更多功能面板（图片、文件等）
  more,

  /// 表情选择面板
  emoji,
}

/// 输入面板状态控制器
///
/// 管理聊天输入区域的面板显示状态，协调面板切换与焦点管理
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
