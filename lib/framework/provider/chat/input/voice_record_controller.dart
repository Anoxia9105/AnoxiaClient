import 'dart:async';
import 'dart:io';

import 'package:anoxia/features/chat/presentation/widgets/chatinput/mobile/chat_voice_overlay.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class VoiceResult {
  final String filePath;
  final int duration;
  const VoiceResult({required this.filePath, required this.duration});
}

class VoiceRecordController extends ChangeNotifier {
  static const double _cancelThreshold = 60.0;
  static const int _maxDurationSeconds = 60;
  final RecorderController waveController = RecorderController();

  bool _disposed = false;

  OverlayEntry? _overlayEntry;
  Timer? _maxDurationTimer;
  bool isRecording = false;
  bool willCancel = false;
  double _startY = 0.0;
  String? _filePath;
  DateTime? _startTime;

  Future<void> requestPermission() async {
    if (!waveController.hasPermission) {
      await waveController.checkPermission();
      // 请求后再检查一次
      if (!waveController.hasPermission) {
        log.warning('用户拒绝了麦克风权限');
      }
    }
  }

  VoidCallback? onMaxDurationReached;
  void showOverlay(BuildContext context) {
    if (_overlayEntry != null) return;
    _overlayEntry = OverlayEntry(
      builder: (_) => ChatVoiceOverlay(controller: this),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> onStart(LongPressStartDetails d) async {
    // 先请求权限
    if (!waveController.hasPermission) {
      return;
    }

    final dir = await getTemporaryDirectory();
    _filePath =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _startTime = DateTime.now();

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

    isRecording = true;
    willCancel = false;
    _startY = d.globalPosition.dy;

    _maxDurationTimer = Timer(const Duration(seconds: _maxDurationSeconds), () {
      log.info('录音达到最长 $_maxDurationSeconds 秒，自动发送');
      onMaxDurationReached?.call();
    });

    if (!_disposed) {
      notifyListeners();
    }
  }

  void onUpdate(LongPressMoveUpdateDetails d) {
    if (!isRecording) return;
    final drag = _startY - d.globalPosition.dy;
    final should = drag > _cancelThreshold;
    if (willCancel != should) {
      willCancel = should;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  Future<VoiceResult?> onEnd(LongPressEndDetails d) async {
    _maxDurationTimer?.cancel(); // ← 取消定时器
    _maxDurationTimer = null;
    if (!isRecording) return null;
    final cancelled = willCancel;
    isRecording = false;
    willCancel = false;
    if (!_disposed) {
      notifyListeners();
    }

    final path = await waveController.stop();

    if (cancelled || path == null) {
      log.info('语音录制已取消');
      if (path != null) {
        try {
          File(path).deleteSync();
        } catch (_) {}
      }
      return null;
    }

    final duration = DateTime.now().difference(_startTime!).inSeconds;
    if (duration < 1) {
      log.info('录音时间太短，丢弃');
      try {
        File(path).deleteSync();
      } catch (_) {}
      return null;
    }

    log.info('语音录制完成: $path, 时长: ${duration}s');
    return VoiceResult(filePath: path, duration: duration);
  }

  /// 强制结束录音（用于超时自动发送）
  Future<VoiceResult?> forceEnd() async {
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;

    if (!isRecording) return null;
    isRecording = false;
    willCancel = false;
    if (!_disposed) {
      notifyListeners();
    }

    final path = await waveController.stop();
    if (path == null) return null;

    final duration = DateTime.now().difference(_startTime!).inSeconds;
    log.info('语音强制结束: $path, 时长: ${duration}s');
    return VoiceResult(filePath: path, duration: duration);
  }

  @override
  void dispose() {
    _disposed = true;
    _maxDurationTimer?.cancel(); // ← 取消定时器
    hideOverlay();
    waveController.dispose();
    super.dispose();
  }
}
