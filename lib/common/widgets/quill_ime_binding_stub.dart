import 'package:flutter/painting.dart';

/// 原生端继续使用 Quill 自带的输入法定位。
class QuillImeBinding {
  QuillImeBinding({
    required Rect? Function() readCaret,
    required String Function() readText,
    required Size Function() readViewSize,
  });

  void start() {}
  void stop() {}
  void dispose() {}
}
