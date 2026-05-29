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
  final RecorderController waveController = RecorderController();

  OverlayEntry? _overlayEntry;
  bool isRecording = false;
  bool willCancel = false;
  double _startY = 0.0;
  String? _filePath;
  DateTime? _startTime;

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
      await waveController.checkPermission();
      // 请求后再检查一次
      if (!waveController.hasPermission) {
        log.warning('用户拒绝了麦克风权限');
        return;
      }
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
    notifyListeners();
  }

  void onUpdate(LongPressMoveUpdateDetails d) {
    if (!isRecording) return;
    final drag = _startY - d.globalPosition.dy;
    final should = drag > _cancelThreshold;
    if (willCancel != should) {
      willCancel = should;
      notifyListeners();
    }
  }

  Future<VoiceResult?> onEnd(LongPressEndDetails d) async {
    if (!isRecording) return null;
    final cancelled = willCancel;
    isRecording = false;
    willCancel = false;
    notifyListeners();

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

  @override
  void dispose() {
    hideOverlay();
    waveController.dispose();
    super.dispose();
  }
}
