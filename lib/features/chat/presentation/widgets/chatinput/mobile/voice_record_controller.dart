import 'dart:async';
import 'dart:io';

import 'package:anoxia/features/chat/presentation/widgets/chatinput/mobile/chat_voice_overlay.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// 语音录制结果
///
/// 封装录制完成后的语音文件路径和时长
class VoiceResult {
  /// 录制文件的本地路径
  final String filePath;

  /// 录制时长（秒）
  final int duration;

  /// 创建语音录制结果
  const VoiceResult({required this.filePath, required this.duration});
}

/// 语音录制控制器
///
/// 负责管理语音录制的完整流程，包括：
/// - 麦克风权限请求
/// - 长按开始录制、滑动取消
/// - 录音时长限制（最大60秒）
/// - 录制结果处理
/// - 录制过程中的 UI 覆盖层显示
///
/// 核心特性：
/// - 支持长按滑动取消（超过60像素触发取消）
/// - 自动检测录音时长过短（小于1秒丢弃）
/// - 达到最大时长自动结束并发送
/// - 支持强制结束录音
class VoiceRecordController extends ChangeNotifier {
  /// 取消录制的滑动阈值（像素）
  static const double _cancelThreshold = 60.0;

  /// 最大录音时长（秒）
  static const int _maxDurationSeconds = 60;

  /// 波形录制控制器
  final RecorderController waveController = RecorderController();

  /// 是否已销毁
  bool _disposed = false;

  /// 录制覆盖层入口
  OverlayEntry? _overlayEntry;

  /// 覆盖层显示状态（复用 OverlayEntry，避免反复创建/销毁）
  bool _overlayVisible = false;

  /// 最大时长定时器
  Timer? _maxDurationTimer;

  /// 是否正在录制
  bool isRecording = false;

  /// 是否将要取消（用户滑动超出阈值）
  bool willCancel = false;

  /// 当前录制覆盖层是否可见
  bool get overlayVisible => _overlayVisible;

  /// 录制开始时的 Y 坐标（用于计算滑动距离）
  double _startY = 0.0;

  /// 当前录制文件路径
  String? _filePath;

  /// 临时目录路径缓存，减少每次录音前的 I/O 延迟
  String? _tempDirPath;

  /// 录制开始时间
  DateTime? _startTime;

  /// 底层 stop 正在执行中的任务，避免并发重复 stop 破坏录音器状态。
  Future<String?>? _stopInFlight;

  /// 手势会话序号：用于解决 onStart/onCancel/onEnd 的异步竞态。
  int _gestureSession = 0;

  /// 当前有效手势会话。
  int _activeGestureSession = 0;

  /// 最大时长到达回调
  VoidCallback? onMaxDurationReached;

  /// 请求麦克风权限
  ///
  /// 在录制前应先调用此方法确保有权限
  Future<void> requestPermission() async {
    // Web 端 audio_waveforms 无实现，直接视为无权限。
    if (kIsWeb) return;
    if (!waveController.hasPermission) {
      await waveController.checkPermission();
      // 请求后再检查一次
      if (!waveController.hasPermission) {
        log.warning('用户拒绝了麦克风权限');
      }
    }
  }

  /// 预热录音依赖（仅临时目录），用于降低首次长按时延。
  ///
  /// 注意：不要在进入聊天页时主动申请麦克风权限，
  /// 仅在用户明确触发语音录制时再申请。
  Future<void> warmUp() async {
    await _ensureTempDirPath();
  }

  Future<String> _ensureTempDirPath() async {
    if (_tempDirPath != null && _tempDirPath!.isNotEmpty) {
      return _tempDirPath!;
    }
    final dir = await getTemporaryDirectory();
    _tempDirPath = dir.path;
    return _tempDirPath!;
  }

  /// 显示录制覆盖层
  ///
  /// 在录制开始时调用，显示录制状态 UI
  void showOverlay(BuildContext context) {
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(
        builder: (_) => ChatVoiceOverlay(controller: this),
      );
      Overlay.of(context).insert(_overlayEntry!);
    }
    _overlayVisible = true;
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// 隐藏录制覆盖层
  ///
  /// 在录制结束（无论成功或取消）时调用
  void hideOverlay() {
    final hadVisible = _overlayVisible;
    final hadEntry = _overlayEntry != null;
    _overlayVisible = false;
    // 直接移除 OverlayEntry，避免残留透明层拦截触摸。
    _removeOverlayEntry();
    if (!_disposed && (hadVisible || hadEntry)) {
      notifyListeners();
    }
  }

  void _removeOverlayEntry() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 开始录制（长按开始）
  ///
  /// [d] 长按开始事件详情，包含触摸位置信息
  Future<void> onStart(LongPressStartDetails d) async {
    final session = ++_gestureSession;
    _activeGestureSession = session;

    // 记录手势起点，便于后续立刻响应上滑取消。
    _startY = d.globalPosition.dy;

    // 先检查权限，若尚未授权则尝试快速拉起授权（首次录音场景）。
    if (_stopInFlight != null) {
      await _stopInFlight;
      if (session != _activeGestureSession) return;
    }

    if (kIsWeb) return;
    if (!waveController.hasPermission) {
      await requestPermission();
      if (session != _activeGestureSession) return;
      if (!waveController.hasPermission) {
        log.warning('未授予麦克风权限，无法开始录音');
        hideOverlay();
        return;
      }
    }

    try {
      // 创建临时文件路径（使用缓存目录以减少卡顿）。
      final tempPath = await _ensureTempDirPath();
      if (session != _activeGestureSession) return;
      _filePath =
          '$tempPath/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _startTime = DateTime.now();

      // 开始录制
      await waveController.record(
        path: _filePath,
        recorderSettings: const RecorderSettings(
          androidEncoderSettings: AndroidEncoderSettings(
            androidEncoder: AndroidEncoder.aacLc,
          ),
          iosEncoderSettings: IosEncoderSetting(
            iosEncoder: IosEncoder.kAudioFormatMPEG4AAC,
          ),
          sampleRate: 44100,
          bitRate: 128000,
        ),
      );

      // 如果手势在异步启动期间已被取消/结束，及时回收本次录音。
      if (session != _activeGestureSession) {
        try {
          final stalePath = await _stopRecorderSafely();
          if (stalePath != null) {
            try {
              File(stalePath).deleteSync();
            } catch (_) {}
          }
        } catch (_) {}
        return;
      }

      // 更新状态
      isRecording = true;
      willCancel = false;

      // 设置最大时长定时器
      _maxDurationTimer = Timer(
        const Duration(seconds: _maxDurationSeconds),
        () {
          log.info('录音达到最长 $_maxDurationSeconds 秒，自动发送');
          onMaxDurationReached?.call();
        },
      );

      // 通知监听器
      if (!_disposed) {
        notifyListeners();
      }
    } catch (e, stack) {
      log.error('开始录音失败', e, stack);
      isRecording = false;
      willCancel = false;
      _maxDurationTimer?.cancel();
      _maxDurationTimer = null;
      if (session == _activeGestureSession) {
        hideOverlay();
      }
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  /// 更新录制状态（滑动过程）
  ///
  /// [d] 滑动更新事件详情，用于判断是否超出取消阈值
  void onUpdate(LongPressMoveUpdateDetails d) {
    if (!isRecording) return;

    // 计算滑动距离
    final drag = _startY - d.globalPosition.dy;
    final shouldCancel = drag > _cancelThreshold;

    // 状态变化时更新并通知
    if (willCancel != shouldCancel) {
      willCancel = shouldCancel;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  /// 结束录制（长按结束）
  ///
  /// [d] 长按结束事件详情
  ///
  /// 返回录制结果，如果取消或时长过短则返回 null
  Future<VoiceResult?> onEnd(LongPressEndDetails d) async {
    // 结束当前手势，会使并发中的 onStart 自动失效。
    _activeGestureSession = ++_gestureSession;

    // 取消定时器
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;

    // 无论是否处于录音中，都强制清理一次遮罩，避免残留透明层。
    hideOverlay();

    // 检查是否正在录制
    if (!isRecording) return null;

    // 记录是否取消
    final cancelled = willCancel;

    // 重置状态
    isRecording = false;
    willCancel = false;
    if (!_disposed) {
      notifyListeners();
    }

    // 停止录制
    final path = await _stopRecorderSafely();

    // 处理取消或失败情况
    if (cancelled || path == null) {
      log.info('语音录制已取消');
      // 清理临时文件
      if (path != null) {
        try {
          File(path).deleteSync();
        } catch (_) {}
      }
      return null;
    }

    // 检查录音时长
    final duration = DateTime.now().difference(_startTime!).inSeconds;
    if (duration < 1) {
      log.info('录音时间太短，丢弃');
      try {
        File(path).deleteSync();
      } catch (_) {}
      return null;
    }

    // 返回录制结果
    log.info('语音录制完成: $path, 时长: ${duration}s');
    return VoiceResult(filePath: path, duration: duration);
  }

  /// 强制结束录音（用于超时自动发送）
  ///
  /// 在达到最大时长时由定时器触发
  Future<VoiceResult?> forceEnd() async {
    // 结束当前手势，会使并发中的 onStart 自动失效。
    _activeGestureSession = ++_gestureSession;

    // 取消定时器
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;

    // 超时收尾时也确保遮罩已清理。
    hideOverlay();

    // 检查是否正在录制
    if (!isRecording) return null;

    // 重置状态
    isRecording = false;
    willCancel = false;
    if (!_disposed) {
      notifyListeners();
    }

    // 停止录制
    final path = await _stopRecorderSafely();
    if (path == null) return null;

    // 计算时长
    final duration = DateTime.now().difference(_startTime!).inSeconds;
    log.info('语音强制结束: $path, 时长: ${duration}s');
    return VoiceResult(filePath: path, duration: duration);
  }

  /// 取消当前录音并清理临时文件（用于手势被系统打断或 onLongPressCancel）。
  Future<void> cancelCurrentRecording() async {
    // 取消当前手势，会使并发中的 onStart 自动失效。
    _activeGestureSession = ++_gestureSession;

    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;

    // 手势取消时优先清理遮罩，避免偶发残留。
    hideOverlay();

    if (!isRecording) {
      willCancel = false;
      if (!_disposed) {
        notifyListeners();
      }
      return;
    }

    isRecording = false;
    willCancel = false;
    if (!_disposed) {
      notifyListeners();
    }

    try {
      final path = await _stopRecorderSafely();
      if (path != null) {
        try {
          File(path).deleteSync();
        } catch (_) {}
      }
      log.info('语音录制已取消并重置');
    } catch (e, stack) {
      log.error('取消录音失败', e, stack);
    }
  }

  Future<String?> _stopRecorderSafely() {
    final inFlight = _stopInFlight;
    if (inFlight != null) return inFlight;

    final future = () async {
      try {
        return await waveController.stop();
      } catch (e, stack) {
        log.error('停止录音失败', e, stack);
        return null;
      } finally {
        _stopInFlight = null;
      }
    }();

    _stopInFlight = future;
    return future;
  }

  /// 释放资源
  @override
  void dispose() {
    _disposed = true;
    _maxDurationTimer?.cancel();
    _overlayVisible = false;
    _removeOverlayEntry();
    waveController.dispose();
    super.dispose();
  }
}
