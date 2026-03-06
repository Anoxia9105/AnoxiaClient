import 'dart:convert';

import 'package:anoxia/framework/protocol/message/Attachment.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart'; // 确保导入 isUploadingProvider
import 'package:anoxia/framework/provider/chat/input/files/chat_file_upload_controller.dart'; // 确保导入
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 必须导入

import '../../../../../../common/utils/fileUtil.dart';

class QuillFileBuild implements EmbedBuilder {
  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final data = embedContext.node.value.data;
    final Map<String, dynamic> dataMap = data is String
        ? jsonDecode(data)
        : data;
    Attachment attachment = Attachment.fromJson(dataMap);

    return Consumer(
      builder: (context, ref, child) {
        // 1. 监听文件上传映射表和全局上传状态
        final uploadState = ref.watch(chatFileUploadControllerProvider);
        final isUploading = ref.watch(isUploadingProvider);

        final bool isSuccess = uploadState.containsKey(attachment.id);
        final bool isFailed = !isSuccess && !isUploading;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          constraints: const BoxConstraints(maxWidth: 260),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // 失败时边框变红
            border: Border.all(
              color: isFailed
                  ? Colors.redAccent
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: ClipRRect(
            // 裁剪进度条
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // 根据状态切换图标：失败显示错误图标，成功/上传显示类型图标
                      FileUtil.buildFileIcon(
                        isFailed ? 'error' : (attachment.type ?? ''),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              attachment.name ?? 'file_unknown'.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isFailed ? Colors.redAccent : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isFailed
                                  ? "upload_failed_retry".tr()
                                  : FileUtil.formatFileSize(
                                      attachment.size ?? 0,
                                    ),
                              style: TextStyle(
                                fontSize: 12,
                                color: isFailed ? Colors.redAccent : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // 2. 进度条逻辑
                if (!isSuccess && isUploading)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  WidgetSpan buildWidgetSpan(Widget widget) {
    return WidgetSpan(child: widget, alignment: PlaceholderAlignment.bottom);
  }

  @override
  String get key => "file";

  @override
  bool get expanded => false;

  @override
  String toPlainText(Embed node) => 'quill_file_plain'.tr();
}
