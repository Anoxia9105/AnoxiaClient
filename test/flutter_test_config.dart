// Flutter 测试全局配置
//
// 在所有测试运行前加载真实字体（JetBrainsMono + NotoSansSC），
// 使 golden / 预览截图中的文本以实际字体渲染（默认 Ahem 字体
// 无法体现真实排版）。资源字体为可变字体（variable font），
// 测试环境下按默认实例渲染即可覆盖常规用例。
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  await _loadFont('assets/fonts/JetBrainsMono[wght].ttf', 'JetBrainsMono');
  await _loadFont(
    'assets/fonts/JetBrainsMono-Italic[wght].ttf',
    'JetBrainsMono',
  );
  await _loadFont('assets/fonts/NotoSansSC[wght].ttf', 'NotoSansSC');

  await testMain();
}

/// 从仓库资产目录加载字体文件并注册到测试引擎。
Future<void> _loadFont(String path, String family) async {
  final file = File(path);
  if (!file.existsSync()) return;
  final bytes = file.readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}
