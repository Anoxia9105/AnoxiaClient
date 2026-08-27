import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/adaptive_page_presenter.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/detail/image_viewer.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/detail/video_viewer.dart';
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:flutter/material.dart';

/// 判断是否应使用对话框呈现媒体详情。
///
/// - 真实桌面端（Windows/macOS/Linux）一律对话框
/// - Web 端根据响应式宽度判断：桌面宽度(>1024) 用对话框，SP 宽度(<=600/1024) 用路由 + Hero
/// - 真实移动端一律路由 + Hero
bool shouldUseDialogForMedia(BuildContext context) {
  if (DeviceUtil.isRealDesktop()) return true;
  if (DeviceUtil.isWeb) return DeviceUtil.isDesktop(context);
  return false;
}

/// 统一的 Hero tag 生成，确保同一消息内唯一且跨类型不冲突。
String buildImageHeroTag(String? messageId, Attachment attachment) {
  final base = attachment.id ?? attachment.url ?? 'unknown';
  final mid = messageId ?? 'noMsg';
  return 'image-$mid-$base';
}

String buildVideoHeroTag(String? messageId, Attachment attachment) {
  final base = attachment.id ?? attachment.url ?? 'unknown';
  final mid = messageId ?? 'noMsg';
  return 'video-$mid-$base';
}

/// 打开图片详情：桌面/Web-PC 用对话框，手机/Web-SP 用 Hero 路由。
Future<void> openImageDetail(
  BuildContext context, {
  required Attachment attachment,
  required String heroTag,
  String? roomId,
  String? currentUrl,
}) async {
  if (attachment.url == null || attachment.url!.isEmpty) return;
  if (shouldUseDialogForMedia(context)) {
    await showEscClosableDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: _ImageDialogContent(
          attachment: attachment,
          roomId: roomId,
          currentUrl: currentUrl,
        ),
      ),
    );
  } else {
    // 使用自定义 PageRoute 保证 Hero 丝滑
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (ctx, animation, secondary) {
          return FadeTransition(
            opacity: animation,
            child: ImageViewer(
              attachment: attachment,
              heroTag: heroTag,
              roomId: roomId,
              currentUrl: currentUrl,
            ),
          );
        },
        transitionsBuilder: (ctx, animation, secondary, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );
  }
}

Future<void> openVideoDetail(
  BuildContext context, {
  required String videoUrl,
  String? coverUrl,
  int? videoWidth,
  int? videoHeight,
  String? fileName,
  int? fileSize,
  int? durationMs,
  required String heroTag,
}) async {
  if (videoUrl.isEmpty) return;
  if (shouldUseDialogForMedia(context)) {
    await showEscClosableDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: VideoViewerDialog(
          videoUrl: videoUrl,
          coverUrl: coverUrl,
          videoWidth: videoWidth,
          videoHeight: videoHeight,
          fileName: fileName,
          fileSize: fileSize,
          durationMs: durationMs,
        ),
      ),
    );
  } else {
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (ctx, animation, secondary) {
          return FadeTransition(
            opacity: animation,
            child: VideoViewerPage(
              heroTag: heroTag,
              videoUrl: videoUrl,
              coverUrl: coverUrl,
              videoWidth: videoWidth,
              videoHeight: videoHeight,
              fileName: fileName,
              fileSize: fileSize,
              durationMs: durationMs,
            ),
          );
        },
      ),
    );
  }
}

class _ImageDialogContent extends StatelessWidget {
  final Attachment attachment;
  final String? roomId;
  final String? currentUrl;
  const _ImageDialogContent({required this.attachment, this.roomId, this.currentUrl});
  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final maxW = (screen.width * 0.86).clamp(320.0, 920.0);
    final maxH = (screen.height * 0.86).clamp(320.0, 900.0);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW.toDouble(), maxHeight: maxH.toDouble()),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              // 复用 ImageViewer 的核心 PhotoView 能力，但以对话框尺寸展示
              Positioned.fill(
                child: ImageViewer(
                  attachment: attachment,
                  heroTag: '__dialog_no_hero__${attachment.url}',
                  roomId: roomId,
                  currentUrl: currentUrl,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
