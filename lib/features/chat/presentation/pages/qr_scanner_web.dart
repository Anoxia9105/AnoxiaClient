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
  _BarcodeDetector? _detector;
  bool _detecting = false;
  bool _started = false;
  bool _active = false;
  bool _disposed = false;
  int _startGeneration = 0;

  /// 错误信息（不支持的浏览器 / 摄像头权限被拒），非空时上层应展示降级 UI。
  String? error;

  /// 状态变化回调，用于在 error 变化时触发上层重建。
  VoidCallback? onStateChanged;

  void attachVideoElement(HTMLVideoElement video) {
    if (_disposed) return;
    _video = video;
  }

  Future<void> start() async {
    if (_disposed || _video == null) return;
    if (_started) {
      _active = true;
      _scheduleDetection();
      return;
    }
    _started = true;
    final generation = ++_startGeneration;

    if (!_isBarcodeDetectorSupported()) {
      _setError('chat_scan_web_unsupported'.tr());
      return;
    }

    MediaStream acquiredStream;
    try {
      final constraints = MediaStreamConstraints(
        video: _VideoConstraints(facingMode: 'environment'.toJS),
      );
      acquiredStream = await window.navigator.mediaDevices
          .getUserMedia(constraints)
          .toDart;
    } catch (_) {
      if (!_isCurrentStart(generation)) return;
      _started = false;
      _setError('chat_scan_camera_permission_denied'.tr());
      return;
    }

    if (!_isCurrentStart(generation)) {
      _stopStream(acquiredStream);
      return;
    }

    _stream = acquiredStream;
    final video = _video;
    if (video == null) {
      _releaseStream();
      return;
    }
    video.srcObject = acquiredStream;
    try {
      // play() 返回 JS Promise，浏览器拒绝自动播放（无用户手势/策略限制）时会被
      // reject。这里用普通 try/catch 显式捕获并进入“播放失败”状态，而不是用空
      // catchError——后者的 onError 返回 void，既不满足 JSAny? 类型又会吞掉异常，
      // 在自动播放被拒时可能再次抛出类型错误。
      await video.play().toDart;
    } catch (_) {
      if (!_isCurrentStart(generation)) return;
      // 播放失败：getUserMedia 已成功、摄像头已开启。必须主动停止 tracks 并清空
      // srcObject，否则浏览器摄像头指示灯会一直亮到页面销毁；同时把 _started 复位，
      // 允许用户在“播放失败”提示下重新进入扫码页重试。
      _releaseStream();
      _started = false;
      _setError('chat_scan_play_failed'.tr());
      return;
    }
    if (!_isCurrentStart(generation)) {
      _releaseStream();
      return;
    }
    _active = true;
    _scheduleDetection();
  }

  bool _isCurrentStart(int generation) =>
      !_disposed && generation == _startGeneration;

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
    // 布尔锁：保证同一时间只有一次检测在跑。若单次 detect() 超过 250ms 仍未结束，
    // 本帧直接跳过，避免并发创建多个 Detector / Promise 堆积导致高 CPU、重复结果
    // 或浏览器卡顿。
    if (_detecting) return;
    _detecting = true;
    try {
      // 复用同一个 Detector 实例，避免每帧新建对象。
      _detector ??= _BarcodeDetector();
      final detected = (await _detector!.detect(_video!).toDart).toDart;
      // 检测可能在 await 期间用户已退出扫码页；再次确认仍活跃，避免把过期结果
      // 通过 onDetect 回调出去（此处 return 仍会执行 finally 复位 _detecting）。
      if (!_active) return;
      for (final barcode in detected) {
        final raw = barcode.rawValue;
        if (raw != null && raw.isNotEmpty) {
          onDetect(raw);
          break;
        }
      }
    } catch (_) {
      // 单帧识别失败忽略，等待下一帧。
    } finally {
      _detecting = false;
    }
  }

  Future<void> stop() async {
    _active = false;
    _timer?.cancel();
    _timer = null;
  }

  /// 停止摄像头轨道并清空视频源引用。getUserMedia 成功后必须显式调用，否则浏览器
  /// 摄像头指示灯会一直亮到页面销毁。
  void _releaseStream() {
    _stopStream(_stream);
    _video?.srcObject = null;
    _stream = null;
  }

  void _stopStream(MediaStream? stream) {
    stream?.getTracks().toDart.forEach((track) => track.stop());
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _startGeneration++;
    _active = false;
    _timer?.cancel();
    _timer = null;
    _releaseStream();
    _video = null;
    _started = false;
    onStateChanged = null;
  }

  void _setError(String message) {
    if (_disposed) return;
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
    widget.controller.onStateChanged = _handleStateChanged;
    unawaited(widget.controller.start());
  }

  void _handleStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.onStateChanged = null;
    super.dispose();
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
