import 'dart:convert';
import 'package:hugeicons/hugeicons.dart';
import 'dart:io';

import 'package:anoxia/framework/domain/upload_entry.dart';
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:anoxia/framework/provider/chat/input/chat_image_upload_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Quill 图片嵌入构建器
///
/// 实现 Quill 编辑器的图片附件渲染，支持：
/// - 显示本地图片预览
/// - 显示上传状态（上传中显示加载指示器、失败显示错误提示）
/// - 上传失败时显示红色边框和半透明效果
/// - 支持点击查看大图
class QuillImageBuild implements EmbedBuilder {
  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final data = embedContext.node.value.data;
    final dataMap = data is String ? jsonDecode(data) : data;
    final attachment = Attachment.fromJson(dataMap);

    return Consumer(
      builder: (context, ref, _) {
        final uploadState = ref.watch(chatImageUploadControllerProvider);
        // 直接读 per-item 状态，无需依赖全局 isUploadingProvider
        final entry = uploadState[attachment.id] ?? UploadEntry.uploading;

        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 200, maxHeight: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: entry.isFailed
                      ? Colors.red
                      : Colors.grey.withValues(alpha: 0.2),
                  width: entry.isFailed ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Opacity(
                  opacity: entry.isFailed ? 0.5 : 1.0,
                  child: _buildEmbeddedImage(
                    attachment.url,
                    ref
                        .read(chatImageUploadControllerProvider.notifier)
                        .bytesOf(attachment.id),
                  ),
                ),
              ),
            ),

            if (entry.isFailed)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HugeIcon(icon: HugeIcons.strokeRoundedCloudOff, color: Colors.red, size: 32),
                  Text(
                    'upload_failed'.tr(),
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

            if (entry.isUploading)
              const CircularProgressIndicator(strokeWidth: 2),
          ],
        );
      },
    );
  }

  /// Web 端不支持 dart:io 的 File / Image.file。
  /// 富文本内的图片嵌入统一优先按远程地址（http/https）用 Image.network 渲染；
  /// 仅非 Web 且为本地路径时才回退到 Image.file，避免触发
  /// "Unsupported operation: Platform._operatingSystem"。
  /// Web 端本地待上传图片（url 为空）回退到 bytes 内存预览。
  Widget _buildEmbeddedImage(String? url, Uint8List? bytes) {
    if (bytes != null && bytes.isNotEmpty && kIsWeb) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: HugeIcon(icon: HugeIcons.strokeRoundedImageNotFound01, size: 36, color: Colors.grey),
        ),
      );
    }

    if (url == null || url.isEmpty) {
      return const Center(
        child: HugeIcon(icon: HugeIcons.strokeRoundedImageNotFound01, size: 36, color: Colors.grey),
      );
    }

    final isRemote =
        url.startsWith('http://') || url.startsWith('https://');

    if (isRemote || kIsWeb) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: HugeIcon(icon: HugeIcons.strokeRoundedImageNotFound01, size: 36, color: Colors.grey),
        ),
      );
    }

    return Image.file(File(url), fit: BoxFit.cover);
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
