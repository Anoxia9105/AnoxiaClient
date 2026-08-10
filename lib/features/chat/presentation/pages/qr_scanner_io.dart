// 扫码组件原生实现（Android / iOS / 桌面）。
//
// 直接封装 mobile_scanner 的 [MobileScanner] 与 [MobileScannerController]，
// 识别到二维码时将原始内容通过 [QrScannerController.onDetect] 回调出去。
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerController {
  QrScannerController({required this.onDetect});

  /// 识别到二维码原始内容时的回调。
  final ValueChanged<String> onDetect;

  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  /// 开始/恢复扫描（原生端由 [MobileScanner] 自行驱动，这里仅代理底层控制器）。
  Future<void> start() async => controller.start();

  /// 暂停扫描。
  Future<void> stop() async => controller.stop();

  void dispose() => controller.dispose();
}

class QrScannerWidget extends StatelessWidget {
  const QrScannerWidget({super.key, required this.controller});

  final QrScannerController controller;

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: controller.controller,
      onDetect: (capture) {
        final raw = capture.barcodes.firstOrNull?.rawValue?.trim();
        if (raw != null && raw.isNotEmpty) controller.onDetect(raw);
      },
    );
  }
}
