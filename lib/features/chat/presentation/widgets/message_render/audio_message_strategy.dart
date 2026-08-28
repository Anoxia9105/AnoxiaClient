import 'package:anoxia/common/utils/device_util.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/provider/chat/input/chat_audio_player_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../../framework/domain/chat_message.dart';
import 'base/message_render_strategy.dart';

/// 语音消息渲染策略
///
/// 处理语音消息的播放和显示，支持播放/暂停控制和进度显示
class AudioMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    /// 语音消息不支持桌面端
    if (DeviceUtil.isRealDesktop()) {
      return Text(
        'audio_message_mobile_only'.tr(),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      );
    }

    final url = message.payload?.audio?.url ?? '';
    final durationMs = message.payload?.audioDuration ?? 0;

    return _AudioBubble(
      messageId: message.messageId ?? '',
      url: url,
      durationMs: durationMs,
      textColor: textColor,
    );
  }
}

class _AudioBubble extends StatefulWidget {
  final String messageId;
  final String url;
  final int durationMs;
  final Color textColor;

  const _AudioBubble({
    required this.messageId,
    required this.url,
    required this.durationMs,
    required this.textColor,
  });

  @override
  State<_AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<_AudioBubble> {
  final manager = ChatAudioPlayerManager.instance;

  int _currentSeconds = 0;

  @override
  void initState() {
    super.initState();

    /// 监听播放器状态刷新 UI
    manager.addListener(_refresh);

    /// 监听播放进度
    manager.positionStream.listen((position) {
      if (!mounted) return;

      final isCurrent = manager.playingMessageId == widget.messageId;

      if (!isCurrent) return;

      setState(() {
        _currentSeconds = position.inSeconds;
      });
    });
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _togglePlay() async {
    if (widget.url.isEmpty) return;

    try {
      await manager.play(messageId: widget.messageId, url: widget.url);
    } catch (e) {
      debugPrint('播放失败: $e');
    }
  }

  @override
  void dispose() {
    manager.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// 当前是否是这条语音
    final isCurrent = manager.playingMessageId == widget.messageId;

    /// 当前是否播放中
    final isPlaying = isCurrent && manager.isPlaying;

    /// 当前显示秒数
    final totalSeconds = (widget.durationMs / 1000).ceil();
    final displaySeconds = isPlaying ? _currentSeconds : totalSeconds;

    /// 动态宽度
    final bubbleWidth = (40.0 + totalSeconds * 8.0).clamp(40.0, 200.0);

    return GestureDetector(
      onTap: _togglePlay,
      child: SizedBox(
        width: bubbleWidth,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: HugeIcon(
                key: ValueKey(isPlaying),
                icon: isPlaying
                    ? HugeIcons.strokeRoundedPauseCircle
                    : HugeIcons.strokeRoundedPlay,
                color: widget.textColor,
                size: 22,
              ),
            ),

            const SizedBox(width: 6),

            Text(
              '$displaySeconds″',
              style: TextStyle(
                fontSize: 13,
                color: widget.textColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
