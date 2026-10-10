import 'package:anoxia/framework/domain/upload_entry.dart';
import 'package:anoxia/framework/provider/chat/input/chat_file_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_image_upload_controller.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// 查询某个附件当前的上传状态
///
/// 「即时发送」链路约定 `attachment.id == clientMsgId == clientFileId`，
/// 因此气泡只要拿到附件的 `id` 就能直接查到进度，不需要额外映射。
///
/// 两个控制器都要查：图片走 [chatImageUploadControllerProvider]，
/// 文件与视频走 [chatFileUploadControllerProvider]。
/// 不存在的 id 返回 `null`（正常消息、历史消息都会走这条路）。
UploadEntry? uploadEntryForId(WidgetRef ref, String? id) {
  if (id == null || id.isEmpty) return null;
  final imageEntry = ref.watch(
    chatImageUploadControllerProvider.select((entries) => entries[id]),
  );
  if (imageEntry != null) return imageEntry;
  return ref.watch(
    chatFileUploadControllerProvider.select((entries) => entries[id]),
  );
}

/// 附件上传状态遮罩
///
/// 覆盖在图片 / 视频气泡之上，呈现三种状态：
/// - 上传中：半透明遮罩 + 确定性进度环（百分比）+ 底部进度条
/// - 上传失败：遮罩 + 失败提示（重传入口在气泡的发送状态指示器上）
/// - 无记录 / 上传成功：不渲染任何内容
///
/// 视觉与桌面输入框内的图片嵌入保持一致（`quill_image_build.dart`）。
/// 文件卡片不使用本遮罩 —— 那里用卡片内的状态行 + 进度条 + 尾部环形指示器
/// 表达同一信息，再叠一层遮罩会过载。
class AttachmentUploadOverlay extends ConsumerWidget {
  const AttachmentUploadOverlay({super.key, required this.attachmentId});

  /// 附件 ID（即 `clientMsgId`）
  final String? attachmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = uploadEntryForId(ref, attachmentId);
    if (entry == null || entry.isSuccess) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final progress = entry.progress;
    final isFailed = entry.isFailed;

    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(RadiusToken.lg),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildIndicator(scheme, progress, isFailed),
              if (!isFailed)
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(ColorScheme scheme, double progress, bool isFailed) {
    if (isFailed) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.error,
              shape: BoxShape.circle,
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedCloudOff,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'upload_failed'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'chat_upload_failed_actions'.tr(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 10,
            ),
          ),
        ],
      );
    }

    return Container(
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
