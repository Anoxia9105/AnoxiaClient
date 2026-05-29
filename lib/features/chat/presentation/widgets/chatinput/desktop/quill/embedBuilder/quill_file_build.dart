import 'dart:convert';

import 'package:anoxia/framework/domain/upload_entry.dart';
import 'package:anoxia/framework/protocol/message/Attachment.dart';
import 'package:anoxia/framework/provider/chat/input/files/chat_file_upload_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../../../common/utils/fileUtil.dart';

/// Quill 文件嵌入构建器
///
/// 实现 Quill 编辑器的文件附件渲染，支持：
/// - 显示文件名和大小
/// - 根据文件类型显示对应图标
/// - 显示上传状态（上传中、成功、失败）
/// - 上传失败时显示红色边框和错误提示
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

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          constraints: const BoxConstraints(maxWidth: 260),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: entry.isFailed
                  ? Colors.redAccent
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      FileUtil.buildFileIcon(
                        entry.isFailed ? 'error' : (attachment.type ?? ''),
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
                                color: entry.isFailed ? Colors.redAccent : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.isFailed
                                  ? 'upload_failed_retry'.tr()
                                  : FileUtil.formatFileSize(
                                      attachment.size ?? 0,
                                    ),
                              style: TextStyle(
                                fontSize: 12,
                                color: entry.isFailed ? Colors.redAccent : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (entry.isUploading)
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
  WidgetSpan buildWidgetSpan(Widget widget) =>
      WidgetSpan(child: widget, alignment: PlaceholderAlignment.bottom);

  @override
  String get key => 'file';

  @override
  bool get expanded => false;

  @override
  String toPlainText(Embed node) => 'quill_file_plain'.tr();
}
