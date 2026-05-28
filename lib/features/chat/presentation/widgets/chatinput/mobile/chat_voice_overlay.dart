// widgets/chat_voice_overlay.dart

import 'package:anoxia/framework/provider/chat/input/voice_record_controller.dart';
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
        child: Center(
          child: _VoiceIndicator(willCancel: controller.willCancel),
        ),
      ),
    );
  }
}

class _VoiceIndicator extends StatelessWidget {
  final bool willCancel;
  const _VoiceIndicator({required this.willCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            willCancel ? Icons.undo_rounded : Icons.mic_rounded,
            size: 64,
            color: willCancel ? Colors.redAccent : Colors.white,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: willCancel
                  ? Colors.redAccent.withValues(alpha: 0.8)
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
