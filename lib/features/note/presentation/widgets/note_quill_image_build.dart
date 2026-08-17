import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hugeicons/hugeicons.dart';

/// 记事本-图片嵌入构建器
///
/// 渲染笔记内已上传的远程图片。图片在插入编辑器前已完成上传，
/// 因此无需关心本地待上传状态，地址为空时显示占位图标。
class NoteQuillImageBuild implements EmbedBuilder {
  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final data = embedContext.node.value.data;
    final dataMap = data is String ? jsonDecode(data) : data;
    String? url;
    if (dataMap is Map) {
      url = dataMap['url']?.toString();
    } else if (dataMap is String && dataMap.isNotEmpty) {
      url = dataMap;
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 320, maxHeight: 480),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildEmbeddedImage(url),
      ),
    );
  }

  /// 仅支持远程地址渲染；空地址显示占位图标。
  Widget _buildEmbeddedImage(String? url) {
    if (url == null || url.isEmpty) {
      return const Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedImageNotFound01,
          size: 36,
          color: Colors.grey,
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedImageNotFound01,
          size: 36,
          color: Colors.grey,
        ),
      ),
    );
  }

  @override
  WidgetSpan buildWidgetSpan(Widget widget) =>
      WidgetSpan(child: widget, alignment: PlaceholderAlignment.bottom);

  @override
  String get key => BlockEmbed.imageType;

  @override
  bool get expanded => false;

  @override
  String toPlainText(Embed node) => 'quill_image_plain'.tr();
}