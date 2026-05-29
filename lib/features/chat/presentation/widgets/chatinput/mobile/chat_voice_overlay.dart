import 'package:anoxia/framework/provider/chat/input/voice_record_controller.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

class ChatVoiceOverlay extends StatelessWidget {
  final VoiceRecordController controller;
  const ChatVoiceOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, __) => Material(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(child: _VoiceIndicator(controller: controller)),
      ),
    );
  }
}

class _VoiceIndicator extends StatelessWidget {
  final VoiceRecordController controller;
  const _VoiceIndicator({required this.controller});

  @override
  Widget build(BuildContext context) {
    final willCancel = controller.willCancel;

    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            willCancel ? Icons.undo_rounded : Icons.mic_rounded,
            size: 48,
            color: willCancel ? Theme.of(context).colorScheme.error : null,
          ),
          const SizedBox(height: 12),

          // 波形
          if (!willCancel)
            AudioWaveforms(
              recorderController: controller.waveController,
              size: const Size(180, 40),
              waveStyle: WaveStyle(
                waveColor: Theme.of(context).colorScheme.primary,
                extendWaveform: true,
                showMiddleLine: false,
                spacing: 4.0,
                waveThickness: 2.5,
              ),
            ),

          if (willCancel) const SizedBox(height: 40),

          const SizedBox(height: 12),

          // 提示文字
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: willCancel
                  ? Theme.of(context).colorScheme.error.withValues(alpha: 0.8)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              willCancel ? '松开手指，取消发送' : '手指上滑，取消发送',
              style: const TextStyle(color: Colors.white, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
