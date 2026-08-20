/// 记事本 PDF 导出（文件级 IO）
///
/// 生成期间显示加载弹窗；桌面 / Web 走系统保存对话框（Web 直接下载），
/// 移动端走系统分享面板。
library;

import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'note_pdf.dart';

/// 导出当前文档为 PDF 文件，返回是否成功执行（取消不视为失败）。
Future<bool> exportNotePdf(
  BuildContext context, {
  required String title,
  required String deltaJson,
  String? updatedAtLabel,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    // 生成中的加载弹窗：用骨架占位替代转圈动画
    builder: (_) => Dialog(
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(20),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonLine(width: 160, height: 14, radius: 6),
            SizedBox(height: 14),
            SkeletonLine(width: 220, height: 12, radius: 6),
            SizedBox(height: 10),
            SkeletonLine(width: 180, height: 12, radius: 6),
            SizedBox(height: 10),
            SkeletonLine(width: 120, height: 12, radius: 6),
          ],
        ),
      ),
    ),
  );

  try {
    final bytes = await buildNotePdf(
      title: title,
      deltaJson: deltaJson,
      updatedAtLabel: updatedAtLabel,
      untitled: 'note_untitled'.tr(),
      emptyContent: 'note_card_no_content'.tr(),
    );
    if (!context.mounted) return false;
    final fileName = '${_safeFileName(title)}.pdf';

    if (DeviceUtil.isRealMobile()) {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(bytes, mimeType: 'application/pdf', name: fileName),
          ],
          subject: title,
        ),
      );
    } else {
      final path = await FilePicker.saveFile(
        dialogTitle: 'note_pdf_export'.tr(),
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );
      if (path == null) return false; // 用户取消
    }
    Toast.showToast('note_pdf_exported'.tr(), type: ToastType.success);
    return true;
  } catch (_) {
    if (context.mounted) {
      Toast.showToast('note_pdf_export_failed'.tr(), type: ToastType.error);
    }
    return false;
  } finally {
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}

String _safeFileName(String title) {
  final cleaned = title.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  return cleaned.isEmpty ? 'note' : cleaned;
}
