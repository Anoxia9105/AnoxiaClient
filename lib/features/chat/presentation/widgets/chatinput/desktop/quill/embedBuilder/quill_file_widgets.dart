import 'package:anoxia/common/utils/file_util.dart';
import 'package:anoxia/common/widgets/video_first_frame_view.dart';
import 'package:anoxia/framework/domain/upload_entry.dart';
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:anoxia/framework/provider/chat/input/chat_file_upload_controller.dart';
import 'package:anoxia/framework/theme/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

class VideoEmbedCard extends ConsumerStatefulWidget {
  final Attachment attachment;
  final UploadEntry entry;
  const VideoEmbedCard({super.key, required this.attachment, required this.entry});

  @override
  ConsumerState<VideoEmbedCard> createState() => VideoEmbedCardState();
}

class VideoEmbedCardState extends ConsumerState<VideoEmbedCard> {
  @override
  Widget build(BuildContext context) {
    final attachment = widget.attachment;
    final entry = widget.entry;
    final scheme = Theme.of(context).colorScheme;
    final isFailed = entry.isFailed;
    final isUploading = entry.isUploading;
    final progress = entry.progress;
    final isRemote =
        attachment.url != null &&
        (attachment.url!.startsWith('http://') ||
            attachment.url!.startsWith('https://'));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      width: 260,
      height: 148,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        border: Border.all(
          color: isFailed ? Colors.redAccent : Colors.white.withValues(alpha: 0.08),
          width: isFailed ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 视频首帧缩略图（play→pause 触发解码），未加载时显示图标占位
            VideoFirstFrameView(
              bytes: isRemote
                  ? null
                  : ref.read(chatFileUploadControllerProvider.notifier).bytesOf(attachment.id),
              filePath: isRemote ? null : attachment.url,
              networkUrl: isRemote ? attachment.url : null,
              mimeType: attachment.type,
              placeholder: Container(
                color: const Color(0xFF1A1A1E),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedVideo01,
                        size: 28,
                        color: Colors.white.withValues(alpha: isFailed ? 0.5 : 0.95),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      FileUtil.formatFileSize(attachment.size ?? 0),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            // 深色遮罩保证文字可读
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.72)],
                  ),
                ),
              ),
            ),
            // 底部文件名 + 进度文案
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Row(
                  children: [
                    const HugeIcon(icon: HugeIcons.strokeRoundedFilmRoll01, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        attachment.name ?? 'video',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (!isFailed && isUploading)
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      )
                    else if (isFailed)
                      const HugeIcon(icon: HugeIcons.strokeRoundedAlert02, size: 14, color: Colors.redAccent),
                  ],
                ),
              ),
            ),
            // 顶部角标
            if (isFailed)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(RadiusToken.pill)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedRefresh, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('retry'.tr(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              )
            else if (!isUploading)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                  child: const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle01, size: 16, color: Color(0xFF4CAF50)),
                ),
              ),
            // 上传中半透明遮罩 + 进度环
            if (isUploading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.22),
                  child: Center(
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        value: progress > 0 ? progress : null,
                        strokeWidth: 3,
                        color: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                ),
              ),
            // 底部进度条
            if (isUploading)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  value: progress > 0 ? progress : null,
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                ),
              ),
            if (isFailed)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(height: 3, color: Colors.redAccent),
              ),
          ],
        ),
      ),
    );
  }
}

class FileEmbedCard extends StatelessWidget {
  final Attachment attachment;
  final UploadEntry entry;
  const FileEmbedCard({super.key, required this.attachment, required this.entry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>();
    final isFailed = entry.isFailed;
    final isUploading = entry.isUploading;
    final progress = entry.progress;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      constraints: const BoxConstraints(maxWidth: 300, minWidth: 220),
      decoration: BoxDecoration(
        color: isFailed
            ? scheme.errorContainer.withValues(alpha: 0.18)
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(RadiusToken.xl),
        border: Border.all(
          color: isFailed ? scheme.error : scheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55),
          width: isFailed ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RadiusToken.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isFailed ? scheme.error.withValues(alpha: 0.12) : scheme.surface,
                      borderRadius: BorderRadius.circular(RadiusToken.lg),
                      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    alignment: Alignment.center,
                    child: FileUtil.buildFileIcon(
                      isFailed ? 'error' : (attachment.type ?? ''),
                      fileName: attachment.name,
                    ),
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
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: isFailed ? scheme.error : scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(RadiusToken.pill),
                              ),
                              child: Text(
                                FileUtil.formatFileSize(attachment.size ?? 0),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isUploading)
                              Text(
                                'chat_upload_progress'.tr(args: ['${(progress * 100).round()}']),
                                style: TextStyle(fontSize: 11, color: scheme.primary, fontWeight: FontWeight.w600),
                              )
                            else if (isFailed)
                              Text(
                                'upload_failed_retry'.tr(),
                                style: TextStyle(fontSize: 11, color: scheme.error, fontWeight: FontWeight.w700),
                              )
                            else
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle01, size: 12, color: appColors?.success ?? const Color(0xFF2E7D32)),
                                  const SizedBox(width: 4),
                                  Text('chat_uploaded'.tr(), style: TextStyle(fontSize: 11, color: appColors?.success ?? const Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  TrailingStatus(entry: entry),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: isUploading
                  ? Column(
                      key: const ValueKey('uploading'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(RadiusToken.pill),
                            child: LinearProgressIndicator(
                              value: progress > 0 ? progress : null,
                              minHeight: 6,
                              backgroundColor: scheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                            ),
                          ),
                        ),
                      ],
                    )
                  : isFailed
                      ? Container(
                          key: const ValueKey('failed'),
                          height: 3,
                          color: scheme.error,
                        )
                      : const SizedBox.shrink(key: ValueKey('idle')),
            ),
          ],
        ),
      ),
    );
  }
}

class TrailingStatus extends StatelessWidget {
  final UploadEntry entry;
  const TrailingStatus({super.key, required this.entry});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (entry.isUploading) {
      final p = entry.progress;
      return SizedBox(
        width: 28,
        height: 28,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: p > 0 ? p : null,
              strokeWidth: 2.6,
              color: scheme.primary,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
            Text(
              p > 0 ? '${(p * 100).round()}%' : '',
              style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: scheme.primary),
            ),
          ],
        ),
      );
    }
    if (entry.isFailed) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: scheme.error, shape: BoxShape.circle),
        child: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh, size: 16, color: Colors.white),
      );
    }
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E9),
        shape: BoxShape.circle,
      ),
      child: const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle01, size: 18, color: Color(0xFF2E7D32)),
    );
  }
}
