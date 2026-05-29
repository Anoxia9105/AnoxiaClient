import 'dart:async';
import 'dart:io';

import 'package:anoxia/features/chat/presentation/widgets/chatinput/mobile/chat_voice_overlay.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
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

  /// 最大时长定时器
  Timer? _maxDurationTimer;

  /// 是否正在录制
  bool isRecording = false;

  /// 是否将要取消（用户滑动超出阈值）
  bool willCancel = false;

  /// 录制开始时的 Y 坐标（用于计算滑动距离）
  double _startY = 0.0;

  /// 当前录制文件路径
  String? _filePath;

  /// 录制开始时间
  DateTime? _startTime;

  /// 最大时长到达回调
  VoidCallback? onMaxDurationReached;

  /// 请求麦克风权限
  ///
  /// 在录制前应先调用此方法确保有权限
  Future<void> requestPermission() async {
    if (!waveController.hasPermission) {
      await waveController.checkPermission();
      // 请求后再检查一次
      if (!waveController.hasPermission) {
        log.warning('用户拒绝了麦克风权限');
      }
    }
  }

  /// 显示录制覆盖层
  ///
  /// 在录制开始时调用，显示录制状态 UI
  void showOverlay(BuildContext context) {
    if (_overlayEntry != null) return;
    _overlayEntry = OverlayEntry(
      builder: (_) => ChatVoiceOverlay(controller: this),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  /// 隐藏录制覆盖层
  ///
  /// 在录制结束（无论成功或取消）时调用
  void hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 开始录制（长按开始）
  ///
  /// [d] 长按开始事件详情，包含触摸位置信息
  Future<void> onStart(LongPressStartDetails d) async {
    // 先检查权限
    if (!waveController.hasPermission) {
      return;
    }

    // 创建临时文件路径
    final dir = await getTemporaryDirectory();
    _filePath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
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

    // 更新状态
    isRecording = true;
    willCancel = false;
    _startY = d.globalPosition.dy;

    // 设置最大时长定时器
    _maxDurationTimer = Timer(const Duration(seconds: _maxDurationSeconds), () {
      log.info('录音达到最长 $_maxDurationSeconds 秒，自动发送');
      onMaxDurationReached?.call();
    });

    // 通知监听器
    if (!_disposed) {
      notifyListeners();
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
    // 取消定时器
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;

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
    final path = await waveController.stop();

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
    // 取消定时器
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;

    // 检查是否正在录制
    if (!isRecording) return null;

    // 重置状态
    isRecording = false;
    willCancel = false;
    if (!_disposed) {
      notifyListeners();
    }

    // 停止录制
    final path = await waveController.stop();
    if (path == null) return null;

    // 计算时长
    final duration = DateTime.now().difference(_startTime!).inSeconds;
    log.info('语音强制结束: $path, 时长: ${duration}s');
    return VoiceResult(filePath: path, duration: duration);
  }

  /// 释放资源
  @override
  void dispose() {
    _disposed = true;
    _maxDurationTimer?.cancel();
    hideOverlay();
    waveController.dispose();
    super.dispose();
  }
}