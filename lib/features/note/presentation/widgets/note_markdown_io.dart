/// 记事本 Markdown 导入 / 导出（文件级 IO）
///
/// - 导出：桌面 / Web 走系统保存对话框（Web 直接下载），移动端走系统分享面板；
///   兜底复制到剪贴板。
/// - 导入：文件选择 .md → 文本 → Delta，整体替换当前编辑文档（由
///   QuillController.document setter 通知会话自动保存）。
library;

import 'dart:convert';

import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/provider/core/toast_service_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'note_markdown.dart';

/// 导出当前文档为 .md 文件，返回是否成功执行（取消不视为失败）。
Future<bool> exportNoteMarkdown(
  WidgetRef ref, {
  required String title,
  required QuillController controller,
}) async {
  final markdown = deltaToMarkdown(controller.document);
  final fileName = '${_safeFileName(title)}.md';

  if (DeviceUtil.isRealMobile()) {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(utf8.encode(markdown)),
              mimeType: 'text/markdown',
              name: fileName,
            ),
          ],
          subject: title,
        ),
      );
      return true;
    } catch (_) {
      // 分享失败时兜底复制
    }
  } else {
    try {
      final bytes = utf8.encode(markdown);
      final path = await FilePicker.saveFile(
        dialogTitle: 'note_markdown_export'.tr(),
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['md'],
        bytes: Uint8List.fromList(bytes),
      );
      if (path == null) return false; // 用户取消
      // FilePicker.saveFile(bytes: ...) 已负责落盘（桌面端写文件/Web 直接下载），
      // 无需再手动 File.writeAsBytes（且 dart:io 会破坏 Web 编译）。
      _toast(ref, 'note_markdown_exported', ToastType.success);
      return true;
    } catch (_) {
      // 保存失败时兜底复制
    }
  }

  await Clipboard.setData(ClipboardData(text: markdown));
  _toast(ref, 'note_markdown_copied', ToastType.success);
  return true;
}

/// 选择 .md 文件并替换当前文档，返回是否成功导入。
Future<bool> importNoteMarkdown(
  WidgetRef ref, {
  required QuillController controller,
}) async {
  try {
    // withData:true 让各端（桌面/移动/Web）都直接返回 bytes，
    // 无需 dart:io File 读盘（dart:io 会破坏 Web 编译，且桌面端默认
    // withData:false 时 bytes 为空是“导入失败”的另一常见来源）。
    final result = await FilePicker.pickFiles(
      dialogTitle: 'note_markdown_import'.tr(),
      type: FileType.custom,
      allowedExtensions: ['md', 'markdown', 'txt'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return false; // 用户取消

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      _toast(ref, 'note_markdown_import_failed', ToastType.error);
      return false;
    }
    final text = utf8.decode(bytes, allowMalformed: true);
    // markdownToDocument 已保证永不抛错（空文件返回空文档），
    // 这里不再因空文件/特殊 HTML 而显示“导入失败”。
    controller.document = markdownToDocument(text);
    _toast(ref, 'note_markdown_imported', ToastType.success);
    return true;
  } catch (_) {
    _toast(ref, 'note_markdown_import_failed', ToastType.error);
    return false;
  }
}

/// 导入前确认：导入会替换当前编辑内容
Future<bool> confirmImportMarkdown(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('note_markdown_import'.tr()),
      content: Text('note_markdown_import_confirm'.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text('dialog_cancel'.tr()),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text('note_confirm'.tr()),
        ),
      ],
    ),
  );
  return result ?? false;
}

String _safeFileName(String title) {
  final cleaned = title.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  return cleaned.isEmpty ? 'note' : cleaned;
}

void _toast(WidgetRef ref, String key, ToastType type) {
  ref.read(toastServiceProvider).showToast(key.tr(), type: type);
}