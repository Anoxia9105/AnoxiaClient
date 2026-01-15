import 'package:flutter/material.dart';
import 'package:anoxia/common/widgets/AcrylicContainer.dart';

class FocusOverlayManager {
  static OverlayEntry? _entry;

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

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}
