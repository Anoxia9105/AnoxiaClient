import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../../../framework/domain/ChatMessage.dart';
import 'base/message_render_strategy.dart';

class AudioMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    final url = message.attachments.firstOrNull?.url ?? '';
    final duration = message.payload?.audioDuration ?? 0;
    return _AudioBubble(url: url, duration: duration, textColor: textColor);
  }
}

class _AudioBubble extends StatefulWidget {
  final String url;
  final int duration;
  final Color textColor;

  const _AudioBubble({
    required this.url,
    required this.duration,
    required this.textColor,
  });

  @override
  State<_AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<_AudioBubble> {
  final AudioPlayer _player = AudioPlayer();
  final PlayerController _waveController = PlayerController();

  bool _isPlaying = false;
  bool _isLoading = false;
  int _currentSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initWave();

    // 播放进度监听
    _player.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _currentSeconds = pos.inSeconds);
    });

    // 播放结束监听
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
          _currentSeconds = 0;
        });
        _waveController.stopPlayer();
      }
    });
  }

  Future<void> _initWave() async {
    try {
      await _waveController.preparePlayer(
        path: widget.url,
        shouldExtractWaveform: true,
        noOfSamples: 40,
        volume: 1.0,
      );
    } catch (_) {}
  }

  Future<void> _togglePlay() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      if (_isPlaying) {
        await _player.pause();
        await _waveController.pausePlayer();
        setState(() => _isPlaying = false);
      } else {
        await _player.setUrl(widget.url);
        await _player.play();
        await _waveController.startPlayer();
        setState(() => _isPlaying = true);
      }
    } catch (e) {
      debugPrint('播放失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _player.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displaySeconds = _isPlaying ? _currentSeconds : widget.duration;

    return GestureDetector(
      onTap: _togglePlay,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 播放/暂停按钮
          SizedBox(
            width: 32,
            height: 32,
            child: _isLoading
                ? Padding(
                    padding: const EdgeInsets.all(6),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.textColor,
                    ),
                  )
                : Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: widget.textColor,
                    size: 28,
                  ),
          ),
          const SizedBox(width: 6),

          // 波形
          AudioFileWaveforms(
            playerController: _waveController,
            size: const Size(120, 32),
            waveformType: WaveformType.fitWidth,
            playerWaveStyle: PlayerWaveStyle(
              fixedWaveColor: widget.textColor.withValues(alpha: 0.4),
              liveWaveColor: widget.textColor,
              spacing: 4,
              waveThickness: 2.5,
            ),
          ),
          const SizedBox(width: 6),

          // 时长
          Text(
            _formatDuration(displaySeconds),
            style: TextStyle(fontSize: 12, color: widget.textColor),
          ),
        ],
      ),
    );
  }
}
