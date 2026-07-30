import 'package:flutter/material.dart';
import 'package:anoxia/common/widgets/AcrylicContainer.dart';

/// 全屏焦点遮罩管理工具
///
/// 用于展示全屏模态内容，支持模糊背景，同时保证只有一个遮罩存在。
class FocusOverlayManager {
  static OverlayEntry? _entry;

  /// 显示全屏遮罩
  ///
  /// [context] 上下文
  /// [child] 要显示的内容组件
  static void show(BuildContext context, Widget child) {
    if (_entry != null) return; // 已经显示
    _entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: AcrylicContainer(
          background: Container(color: Colors.transparent),
          blurSigma: 10,
          borderRadius: BorderRadius.zero,
          padding: EdgeInsets.zero,
          child: Scaffold(
            body: child,
          ),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  /// 隐藏全屏遮罩
  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}
