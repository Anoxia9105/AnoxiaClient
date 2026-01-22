import 'dart:convert';

import 'package:anoxia/framework/logs/talker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class QuillImageBuild implements EmbedBuilder {
  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final dynamic rawData = jsonDecode(embedContext.node.value.data);
    log.info(rawData);
    Map<String, dynamic> dataMap = rawData.cast<String, dynamic>();
    if (dataMap.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 200, maxHeight: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        // 可选：加个淡边框，防止白底图片在白底聊天框看不清边界
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: dataMap["url"].toString(),
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          placeholder: (context, url) => Container(
            width: 100,
            height: 100,
            color: Colors.grey[100],
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 100,
            height: 100,
            color: Colors.grey[100],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  @override
  WidgetSpan buildWidgetSpan(Widget widget) {
    return WidgetSpan(child: widget, alignment: PlaceholderAlignment.bottom);
  }

  @override
  String get key => BlockEmbed.imageType;

  @override
  bool get expanded => false;

  @override
  String toPlainText(Embed node) {
    return '';
  }
}
