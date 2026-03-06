import 'dart:convert';
import 'dart:io';

import 'package:anoxia/framework/protocol/message/Attachment.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/provider/chat/input/images/chat_image_upload_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuillImageBuild implements EmbedBuilder {
  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    // 1. 先解析基础数据
    final data = embedContext.node.value.data;
    final dataMap = data is String ? jsonDecode(data) : data;
    Attachment attachment = Attachment.fromJson(dataMap);

    return Consumer(
      builder: (context, ref, child) {
        // 监听上传状态
        final uploadState = ref.watch(chatImageUploadControllerProvider);
        final isUploading = ref.watch(isUploadingProvider);

        final bool isSuccess = uploadState.containsKey(attachment.id);
        // 如果不在上传映射表里，且全局上传状态已经停止，判定为失败
        final bool isFailed = !isSuccess && !isUploading;

        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 200, maxHeight: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isFailed
                      ? Colors.red
                      : Colors.grey.withValues(alpha: 0.2),
                  width: isFailed ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Opacity(
                  opacity: isFailed ? 0.5 : 1.0,
                  // 只有本地文件存在时才 Image.file
                  child: Image.file(File(attachment.url!), fit: BoxFit.cover),
                ),
              ),
            ),

            // 失败遮罩层
            if (isFailed)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, color: Colors.red, size: 32),
                  Text(
                    "upload_failed".tr(),
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

            // 上传中进度（可选）
            if (!isSuccess && isUploading)
              const CircularProgressIndicator(strokeWidth: 2),
          ],
        );
      },
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
    return 'quill_image_plain'.tr();
  }
}
