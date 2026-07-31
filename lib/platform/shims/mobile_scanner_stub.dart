// Web 端 mobile_scanner 桩：二维码扫描在 Web 暂不支持，渲染占位提示。
import 'package:flutter/widgets.dart';

enum DetectionSpeed { normal, noDuplicates, unordered }

class Barcode {
  final String? rawValue;
  final dynamic type;
  const Barcode({this.rawValue, this.type});
}

class BarcodeCapture {
  final List<Barcode> barcodes;
  const BarcodeCapture({this.barcodes = const []});
}

class MobileScannerController {
  final DetectionSpeed? detectionSpeed;
  MobileScannerController({this.detectionSpeed});
  Future<void> dispose() async {}
  Future<void> stop() async {}
  Future<void> start() async {}
}

class MobileScanner extends StatelessWidget {
  final MobileScannerController? controller;
  final void Function(BarcodeCapture) onDetect;
  final Color? overlayColor;
  const MobileScanner({
    super.key,
    this.controller,
    required this.onDetect,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('二维码扫描功能暂不支持 Web 端'),
    );
  }
}
