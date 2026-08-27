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
        final entry = uploadState[attachment.id] ?? UploadEntry.uploading;
        final scheme = Theme.of(context).colorScheme;
        final isFailed = entry.isFailed;
        final isUploading = entry.isUploading;
        final progress = entry.progress;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          constraints: const BoxConstraints(maxWidth: 220, maxHeight: 320),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFailed
                  ? Colors.redAccent
                  : isUploading
                      ? scheme.primary.withValues(alpha: 0.35)
                      : Colors.grey.withValues(alpha: 0.18),
              width: isFailed ? 2 : 1.2,
            ),
            boxShadow: [
              if (!isFailed)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: isFailed ? 0.45 : 1.0,
                  child: _buildEmbeddedImage(
                    attachment.url,
                    ref.read(chatImageUploadControllerProvider.notifier).bytesOf(attachment.id),
                  ),
                ),
                // 上传中半透明遮罩 + 确定性进度环
                if (isUploading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.18),
                      child: Center(
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.42),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 42,
                                height: 42,
                                child: CircularProgressIndicator(
                                  value: progress > 0 ? progress : null,
                                  strokeWidth: 3,
                                  color: Colors.white,
                                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                                ),
                              ),
                              Text(
                                progress > 0 ? '${(progress * 100).round()}%' : '',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // 失败态
                if (isFailed)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                            child: const HugeIcon(icon: HugeIcons.strokeRoundedCloudOff, color: Colors.white, size: 22),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'upload_failed'.tr(),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'upload_failed_retry'.tr(),
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                // 成功角标
                if (!isUploading && !isFailed)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                      child: const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle01, size: 14, color: Color(0xFF4CAF50)),
                    ),
                  ),
                // 底部确定性进度条
                if (isUploading)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                    ),
                  ),
                if (isFailed)
                  Positioned(left: 0, right: 0, bottom: 0, child: Container(height: 4, color: Colors.redAccent)),
              ],
            ),
          ),
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
