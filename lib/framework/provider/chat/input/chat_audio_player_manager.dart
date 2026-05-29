import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// 聊天语音播放器管理器
///
/// 负责管理语音消息的播放，确保全局只有一个音频播放器实例，
/// 实现语音消息的播放、暂停、停止和状态监听。
///
/// 核心特性：
/// - 单例模式，全局共享播放器实例
/// - 支持点击当前播放语音切换暂停/播放
/// - 播放新语音时自动停止当前播放
/// - 播放完成自动重置状态
class ChatAudioPlayerManager extends ChangeNotifier {
  /// 单例实例
  static final ChatAudioPlayerManager instance = ChatAudioPlayerManager._();

  /// 工厂构造函数，返回单例实例
  factory ChatAudioPlayerManager() => instance;

  /// 私有构造函数
  ChatAudioPlayerManager._() {
    // 监听播放器状态，播放完成时自动停止并重置状态
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        stop();
      }
    });
  }

  /// 音频播放器实例
  final AudioPlayer _player = AudioPlayer();

  /// 当前正在播放的消息ID
  String? _playingMessageId;

  /// 获取当前正在播放的消息ID
  String? get playingMessageId => _playingMessageId;

  /// 是否正在播放
  bool get isPlaying => _player.playing;

  /// 当前播放进度
  Duration get position => _player.position;

  /// 播放进度流
  Stream<Duration> get positionStream => _player.positionStream;

  /// 播放语音消息
  ///
  /// [messageId] 消息唯一标识，用于判断是否为当前播放消息
  /// [url] 语音文件的远程或本地路径
  ///
  /// 点击当前播放中的语音会暂停，播放新语音会先停止当前播放
  Future<void> play({
    required String messageId,
    required String url,
  }) async {
    // 点击当前播放中的语音 -> 暂停
    if (_playingMessageId == messageId && _player.playing) {
      await pause();
      return;
    }

    // 播放新语音 -> 先停止旧的
    if (_playingMessageId != messageId) {
      await _player.stop();
    }

    // 更新当前播放的消息ID
    _playingMessageId = messageId;

    // 通知监听器状态变化
    notifyListeners();

    // 设置播放源并开始播放
    await _player.setUrl(url);
    await _player.play();

    // 再次通知监听器状态变化
    notifyListeners();
  }

  /// 暂停播放
  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  /// 停止播放并重置状态
  Future<void> stop() async {
    await _player.stop();
    _playingMessageId = null;
    notifyListeners();
  }

  /// 释放播放器资源
  void disposePlayer() {
    _player.dispose();
  }
}