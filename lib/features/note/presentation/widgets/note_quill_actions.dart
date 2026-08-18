import 'package:anoxia/common/utils/quill_embed_util.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/colors_box.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/provider/core/upload_repository_provider.dart';
import 'package:cross_file/cross_file.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// 清除光标处的所有行内/块级格式。
void noteClearFormat(QuillController controller) {
  final attributes = <Attribute>{};
  for (final style in controller.getAllSelectionStyles()) {
    for (final attr in style.attributes.values) {
      attributes.add(attr);
    }
  }
  for (final attribute in attributes) {
    controller.formatSelection(Attribute.clone(attribute, null));
  }
}

/// 切换行内格式（已存在则移除，否则应用）。
void noteToggleInline(QuillController controller, Attribute attr) {
  final has = controller
      .getSelectionStyle()
      .attributes
      .containsKey(attr.key);
  controller.formatSelection(has ? Attribute.clone(attr, null) : attr);
}

/// 设置/移除链接：弹出输入框。
Future<void> noteSetLink(
  BuildContext context,
  QuillController controller,
  FocusNode focusNode,
) async {
  final input = TextEditingController();
  final url = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('note_link'.tr()),
      content: TextField(
        controller: input,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(hintText: 'https://'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text('cancel'.tr()),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(input.text.trim()),
          child: Text('note_link_apply'.tr()),
        ),
      ],
    ),
  );
  if (!context.mounted) return;
  if (url != null && url.isEmpty) {
    controller.formatSelection(Attribute.clone(Attribute.link, null));
    return;
  }
  if (url == null) return;
  controller.formatSelection(LinkAttribute(url));
  focusNode.requestFocus();
}

/// 选择文字/背景颜色：弹出颜色面板。
Future<void> notePickColor(
  BuildContext context,
  QuillController controller,
  FocusNode focusNode, {
  required bool background,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      contentPadding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      content: ColorsBox.buildColorsWidget(
        (hex) {
          controller.formatSelection(
            hex == null
                ? Attribute.clone(
                    background ? Attribute.background : Attribute.color,
                    null,
                  )
                : background
                    ? BackgroundAttribute(hex)
                    : ColorAttribute(hex),
          );
          focusNode.requestFocus();
          Navigator.of(dialogContext).pop();
        },
        dialogContext,
      ),
    ),
  );
}

/// 选择并上传图片，成功后插入编辑器。
Future<void> noteInsertImage(
  BuildContext context,
  WidgetRef ref,
  QuillController controller,
  FocusNode focusNode,
) async {
  final result = await FilePicker.pickFiles(
    allowMultiple: true,
    type: FileType.image,
  );
  if (result == null || result.files.isEmpty) return;
  if (!context.mounted) return;

  final ids = List.generate(result.files.length, (_) => const Uuid().v4());
  final files = <XFile>[];
  for (var i = 0; i < result.files.length; i++) {
    final file = result.files[i];
    files.add(
      file.bytes != null
          ? XFile.fromData(file.bytes!, name: file.name)
          : XFile(file.path!),
    );
  }

  try {
    final uploads = await ref.read(uploadRepositoryProvider).uploadFiles(
          files,
          clientFileIds: ids,
        );
    if (!context.mounted) return;

    var inserted = 0;
    var failed = 0;
    for (var i = 0; i < uploads.length; i++) {
      final upload = uploads[i];
      if (!upload.isSuccess || upload.url == null) {
        failed++;
        continue;
      }
      QuillEmbedUtil.insertEmbed(
        controller: controller,
        type: BlockEmbed.imageType,
        data: {
          'kind': 'IMAGE',
          'url': upload.url,
          'name': result.files[i].name,
          'size': result.files[i].size,
          'type': 'image/${result.files[i].extension ?? 'jpeg'}',
        },
      );
      inserted++;
    }

    if (failed > 0) {
      Toast.showToast(
        'note_image_upload_failed'.tr(args: [failed.toString()]),
        type: ToastType.error,
      );
    }
    if (inserted > 0) {
      focusNode.requestFocus();
    }
  } catch (e, st) {
    debugLog('插入笔记图片失败: $e', st);
    if (!context.mounted) return;
    Toast.showToast(
      'note_image_upload_error'.tr(),
      type: ToastType.error,
    );
  }
}