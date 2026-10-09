import 'dart:convert';

import 'package:anoxia/framework/domain/upload_entry.dart';
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:anoxia/framework/provider/chat/input/chat_file_upload_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'quill_file_widgets.dart';

/// Quill 文件嵌入构建器
///
/// 区分视频与普通文件：
/// - 视频：展示视频风格缩略容器（深色背景+播放图标+文件名/大小渐变遮罩+底部进度条）
/// - 文件：卡片式布局，强化边框/阴影/圆角，底部确定性进度条 + 百分比文案，失败态醒目红色
class QuillFileBuild implements EmbedBuilder {
  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final data = embedContext.node.value.data;
    final dataMap = data is String ? jsonDecode(data) : data;
    final attachment = Attachment.fromJson(dataMap);

    return Consumer(
      builder: (context, ref, _) {
        final uploadState = ref.watch(chatFileUploadControllerProvider);
        final entry = uploadState[attachment.id] ?? UploadEntry.uploading;
        final isVideo = attachment.isVideo;
        void retry() => ref
            .read(chatFileUploadControllerProvider.notifier)
            .retryUpload(attachment);

        if (isVideo) {
          return VideoEmbedCard(
            attachment: attachment,
            entry: entry,
            onRetry: retry,
          );
        }
        return FileEmbedCard(
          attachment: attachment,
          entry: entry,
          onRetry: retry,
        );
      },
    );
  }

  @override
  WidgetSpan buildWidgetSpan(Widget widget) =>
      WidgetSpan(child: widget, alignment: PlaceholderAlignment.bottom);

  @override
  String get key => 'file';

  @override
  bool get expanded => false;

  @override
  String toPlainText(Embed node) => 'quill_file_plain'.tr();
}
