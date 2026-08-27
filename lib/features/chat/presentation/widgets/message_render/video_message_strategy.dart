import 'package:anoxia/common/utils/media_viewer_helper.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:flutter/material.dart';

import 'base/message_render_strategy.dart';
import 'video_message_player.dart';

/// Renders videos as lazy, inline players inside message bubbles.
class VideoMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    final video = message.payload?.video;
    if (video == null || video.url == null || video.url!.isEmpty) {
      return const SizedBox.shrink();
    }

    final cover = message.payload?.cover;
    final heroTag = buildVideoHeroTag(
      message.messageId ?? message.clientMsgId,
      video,
    );
    return VideoMessagePlayer(
      heroTag: heroTag,
      videoUrl: video.url!,
      coverUrl: cover?.url ?? video.thumbnailUrl,
      videoWidth: video.width,
      videoHeight: video.height,
      fileName: video.name,
      fileSize: video.size,
      durationMs: message.payload?.audioDuration,
    );
  }
}
