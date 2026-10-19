// UploadValidator（上传校验）单元测试。
//
// 锁定数量/大小边界：
// - 总附件数 ≤ 10；
// - 总大小 ≤ 100MB（恰在阈值允许，超出即拒绝）；
// - 单文件 ≤ 50MB。
//
// 说明：校验失败文案走 easy_localization `.tr()`；测试环境未加载语言包时
// `.tr()` 安全回退为原始 key（见 easy_localization `_resolve`），因此这里
// 只断言「弹了哪种类型的提示」，不断言具体文案。
import 'package:file_picker/file_picker.dart';
import 'package:anoxia/framework/core/toast_service.dart';
import 'package:anoxia/framework/provider/chat/input/upload_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingToast extends ToastService {
  final List<ToastType> shown = [];

  @override
  void showNotificationNow(
    String message, {
    Color? color,
    String? typeMessage,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    shown.add(type);
  }

  @override
  void showToast(
    String message, {
    ToastType type = ToastType.info,
    Alignment align = Alignment.bottomCenter,
    Duration duration = const Duration(seconds: 3),
  }) {
    shown.add(type);
  }

  @override
  Function showWidgetOffset({
    required Offset target,
    dynamic preferDirection,
    required Widget child,
    VoidCallback? onClose,
  }) {
    throw UnimplementedError('测试不需要');
  }
}

PlatformFile fileOf(int megabytes, {String name = 'file.bin'}) =>
    PlatformFile(name: name, size: megabytes * 1024 * 1024);

void main() {
  late QuillController controller;
  late _RecordingToast toast;

  setUp(() {
    controller = QuillController.basic();
    toast = _RecordingToast();
  });

  group('validate（总数量/总大小）', () {
    test('空编辑器 + 空列表 允许', () {
      expect(UploadValidator.validate(toast, controller, const []), isTrue);
      expect(toast.shown, isEmpty);
    });

    test('恰好在最大数量 10 个时允许', () {
      final files = List.generate(10, (i) => PlatformFile(name: 'f$i', size: 1));
      expect(UploadValidator.validate(toast, controller, files), isTrue);
    });

    test('超过最大数量（11 个）拒绝并弹警告', () {
      final files = List.generate(11, (i) => PlatformFile(name: 'f$i', size: 1));
      expect(UploadValidator.validate(toast, controller, files), isFalse);
      expect(toast.shown, [ToastType.warning]);
    });

    test('总大小恰好在 100MB 阈值上允许', () {
      expect(
        UploadValidator.validate(toast, controller, [fileOf(99), fileOf(1)]),
        isTrue,
      );
    });

    test('总大小超过 100MB（100MB+1B）拒绝并弹警告', () {
      final files = [
        fileOf(10),
        PlatformFile(name: 'big.bin', size: UploadValidator.maxTotalSize - 10 * 1024 * 1024 + 1),
      ];
      expect(UploadValidator.validate(toast, controller, files), isFalse);
      expect(toast.shown, [ToastType.warning]);
    });
  });

  group('validateSingleFile', () {
    test('恰好在 50MB 阈值上允许', () {
      expect(
        UploadValidator.validateSingleFile(toast, fileOf(UploadValidator.maxSingleFileSize ~/ (1024 * 1024))),
        isTrue,
      );
      expect(toast.shown, isEmpty);
    });

    test('超过 50MB 拒绝并弹警告', () {
      final tooLarge = PlatformFile(
        name: 'huge.bin',
        size: UploadValidator.maxSingleFileSize + 1,
      );
      expect(UploadValidator.validateSingleFile(toast, tooLarge), isFalse);
      expect(toast.shown, [ToastType.warning]);
    });
  });
}
