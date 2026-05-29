import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class ChatAudioPlayerManager extends ChangeNotifier {
  static final ChatAudioPlayerManager instance =
      ChatAudioPlayerManager._();

  factory ChatAudioPlayerManager() => instance;

  ChatAudioPlayerManager._() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        stop();
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();

  String? _playingMessageId;

  String? get playingMessageId => _playingMessageId;

  bool get isPlaying => _player.playing;

  Duration get position => _player.position;

  Stream<Duration> get positionStream => _player.positionStream;

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

    _playingMessageId = messageId;

    notifyListeners();

    await _player.setUrl(url);
    await _player.play();

    notifyListeners();
  }

  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();

    _playingMessageId = null;

    notifyListeners();
  }

  void disposePlayer() {
    _player.dispose();
  }
}