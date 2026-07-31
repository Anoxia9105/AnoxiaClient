/// 扫码组件 Web 实现。
///
/// 浏览器端没有 mobile_scanner，这里使用 getUserMedia 打开摄像头，并通过
/// 标准 Shape Detection API（BarcodeDetector）逐帧识别二维码。视频预览通过
/// [HtmlElementView] 嵌入，识别结果经 [QrScannerController.onDetect] 回调。
///
/// 注意：BarcodeDetector 仅在部分浏览器（如 Chrome/Edge）可用，不支持时
/// [QrScannerController.error] 会被置为提示文案，由上层展示降级 UI。
///
/// 本文件使用 dart:js_interop + package:web 做 JS 互操作（而非已废弃的
/// dart:js / dart:js_util），可与未来的 Wasm 编译兼容。互操作类型采用
/// `extension type ... implements JSObject` 写法，以兼容当前 SDK 的 js_interop。
import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
// package:web 导出了 DOM 的 Text 类型，与 Flutter 的 Text 组件冲突，这里 hide 之。
import 'package:web/web.dart' hide Text;

const String _qrVideoViewType = 'anoxia-qr-video';

/// 全局 BarcodeDetector 构造器；浏览器不支持时该全局不存在，返回 null。
@JS('BarcodeDetector')
external JSFunction? get _barcodeDetectorCtor;

@JS()
extension type _DetectedBarcode._(JSObject _) implements JSObject {
  external String? get rawValue;
}

@JS('BarcodeDetector')
extension type _BarcodeDetector._(JSObject _) implements JSObject {
  external factory _BarcodeDetector();
}

extension _BarcodeDetectorExtension on _BarcodeDetector {
  // detect() 返回 JavaScript Promise，用 js_interop 的 toDart 转为 Dart Future；
  // 结果再经 JSArray.toDart 转为 List。
  external JSPromise<JSArray<_DetectedBarcode>> detect(JSAny source);
}

/// 摄像头约束中的 video 部分：{ facingMode: 'environment' }。
@JS()
extension type _VideoConstraints._(JSObject _) implements JSObject {
  external factory _VideoConstraints({JSAny? facingMode});
}

class QrScannerController {
  QrScannerController({required this.onDetect});

  /// 识别到二维码原始内容时的回调。
  final ValueChanged<String> onDetect;

  HTMLVideoElement? _video;
  MediaStream? _stream;
  Timer? _timer;
  bool _started = false;
  bool _active = false;

  /// 错误信息（不支持的浏览器 / 摄像头权限被拒），非空时上层应展示降级 UI。
  String? error;

  /// 状态变化回调，用于在 error 变化时触发上层重建。
  VoidCallback? onStateChanged;

  void attachVideoElement(HTMLVideoElement video) => _video = video;

  Future<void> start() async {
    if (_video == null) return;
    if (_started) {
      _active = true;
      _scheduleDetection();
      return;
    }
    _started = true;

    if (!_isBarcodeDetectorSupported()) {
      _setError('chat_scan_web_unsupported'.tr());
      return;
    }

    try {
      final constraints = MediaStreamConstraints(
        video: _VideoConstraints(facingMode: 'environment'.toJS),
      );
      _stream = await window.navigator.mediaDevices!
          .getUserMedia(constraints)
          .toDart;
    } catch (_) {
      _setError('chat_scan_camera_permission_denied'.tr());
      return;
    }

    _video!.srcObject = _stream;
    await _video!.play().toDart.catchError((_) {});
    _active = true;
    _scheduleDetection();
  }

  bool _isBarcodeDetectorSupported() => _barcodeDetectorCtor != null;

  void _scheduleDetection() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _detectOnce(),
    );
  }

  Future<void> _detectOnce() async {
    if (!_active || _video == null) return;
    if (_barcodeDetectorCtor == null) return;
    try {
      final detector = _BarcodeDetector();
      final detected = (await detector.detect(_video!).toDart).toDart;
      for (final barcode in detected) {
        final raw = barcode.rawValue;
        if (raw != null && raw.isNotEmpty) {
          onDetect(raw);
          break;
        }
      }
    } catch (_) {
      // 单帧识别失败忽略，等待下一帧。
    }
  }

  Future<void> stop() async {
    _active = false;
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _active = false;
    _timer?.cancel();
    _timer = null;
    _stream?.getTracks().toDart.forEach((track) => track.stop());
    _video?.srcObject = null;
    _video = null;
    _started = false;
  }

  void _setError(String message) {
    error = message;
    onStateChanged?.call();
  }
}

class QrScannerWidget extends StatefulWidget {
  const QrScannerWidget({super.key, required this.controller});

  final QrScannerController controller;

  @override
  State<QrScannerWidget> createState() => _QrScannerWidgetState();
}

class _QrScannerWidgetState extends State<QrScannerWidget> {
  static bool _factoryRegistered = false;
  static HTMLVideoElement? _sharedVideo;

  @override
  void initState() {
    super.initState();
    if (!_factoryRegistered) {
      _sharedVideo = document.createElement('video') as HTMLVideoElement
        ..setAttribute('playsinline', 'true')
        ..style.setProperty('width', '100%')
        ..style.setProperty('height', '100%')
        ..style.setProperty('object-fit', 'cover');
      ui_web.platformViewRegistry.registerViewFactory(
        _qrVideoViewType,
        (_) => _sharedVideo!,
      );
      _factoryRegistered = true;
    }
    widget.controller.attachVideoElement(_sharedVideo!);
    widget.controller.onStateChanged = () => setState(() {});
    widget.controller.start();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            widget.controller.error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return const HtmlElementView(viewType: _qrVideoViewType);
  }
}
