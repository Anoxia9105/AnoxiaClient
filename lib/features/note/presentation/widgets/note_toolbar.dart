import 'package:anoxia/common/utils/quill_embed_util.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/chat_quill_color_style_button.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/chat_quill_toggle_style_button.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/colors_box.dart';
import 'package:anoxia/framework/provider/core/upload_repository_provider.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:cross_file/cross_file.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:uuid/uuid.dart';

import '../../../../../common/widgets/toast.dart';

/// 记事本富文本工具栏
///
/// 双行布局：
/// - 第一行：撤销 / 重做 / 清除格式 / 标题级别 / 粗斜下划线删除线 / 行内代码 / 文字颜色 / 背景色
/// - 第二行：无序列表 / 有序列表 / 任务列表 / 引用 / 链接 / 图片 / 对齐
class NoteToolbar extends ConsumerWidget {
  final QuillController controller;
  final FocusNode focusNode;

  const NoteToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: .6),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildCustomBtn(
                HugeIcons.strokeRoundedUndo,
                'note_undo'.tr(),
                iconColor,
                controller.undo,
              ),
              _buildCustomBtn(
                HugeIcons.strokeRoundedRedo,
                'note_redo'.tr(),
                iconColor,
                controller.redo,
              ),
              _buildCustomBtn(
                HugeIcons.strokeRoundedTextClear,
                'toolbar_clear_format'.tr(),
                iconColor,
                _clearAttributes,
              ),
              _buildDivider(context),
              _buildHeaderButton(context, iconColor),
              _buildDivider(context),
              _buildActionButton(
                HugeIcons.strokeRoundedTextBold,
                Attribute.bold,
                'toolbar_bold'.tr(),
                iconColor,
              ),
              _buildActionButton(
                HugeIcons.strokeRoundedTextItalic,
                Attribute.italic,
                'toolbar_italic'.tr(),
                iconColor,
              ),
              _buildActionButton(
                HugeIcons.strokeRoundedTextUnderline,
                Attribute.underline,
                'toolbar_underline'.tr(),
                iconColor,
              ),
              _buildActionButton(
                HugeIcons.strokeRoundedTextStrikethrough,
                Attribute.strikeThrough,
                'toolbar_strikethrough'.tr(),
                iconColor,
              ),
              _buildActionButton(
                HugeIcons.strokeRoundedSourceCode,
                Attribute.inlineCode,
                'toolbar_inline_code'.tr(),
                iconColor,
              ),
              _buildDivider(context),
              ChatQuillColorStyleButton(
                controller: controller,
                type: ChatQuillColorStyleType.foreground,
                tooltip: 'toolbar_text_color'.tr(),
                onPressed: () {
                  Function? onCancel;
                  onCancel = Toast.showWidget(
                    context,
                    child: ColorsBox.buildColorsWidget((hex) {
                      controller.formatSelection(ColorAttribute(hex));
                      onCancel?.call();
                      focusNode.requestFocus();
                    }, context),
                  );
                },
              ),
              ChatQuillColorStyleButton(
                controller: controller,
                type: ChatQuillColorStyleType.background,
                tooltip: 'toolbar_bg_color'.tr(),
                onPressed: () {
                  Function? onCancel;
                  onCancel = Toast.showWidget(
                    context,
                    child: ColorsBox.buildColorsWidget((hex) {
                      controller.formatSelection(BackgroundAttribute(hex));
                      onCancel?.call();
                      focusNode.requestFocus();
                    }, context),
                  );
                },
              ),
            ],
          ),
          Row(
            children: [
              _buildActionButton(
                HugeIcons.strokeRoundedLeftToRightListBullet,
                Attribute.ul,
                'note_bullet_list'.tr(),
                iconColor,
              ),
              _buildActionButton(
                HugeIcons.strokeRoundedLeftToRightListNumber,
                Attribute.ol,
                'note_ordered_list'.tr(),
                iconColor,
              ),
              _buildTaskListButton(context, iconColor),
              _buildActionButton(
                HugeIcons.strokeRoundedQuoteDown,
                Attribute.blockQuote,
                'toolbar_quote'.tr(),
                iconColor,
              ),
              _buildDivider(context),
              _buildLinkButtonImpl(context, iconColor),
              _buildCustomBtn(
                HugeIcons.strokeRoundedImage01,
                'note_image'.tr(),
                iconColor,
                () => _insertImage(context, ref),
              ),
              _buildDivider(context),
              _buildAlignButton(context, iconColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    List<List<dynamic>> icon,
    Attribute attr,
    String tooltip,
    Color color,
  ) {
    return ChatQuillToggleStyleButton(
      controller: controller,
      focusNode: focusNode,
      icon: icon,
      attribute: attr,
      tooltip: tooltip,
      color: color,
    );
  }

  Widget _buildCustomBtn(
    List<List<dynamic>> icon,
    String tooltip,
    Color color,
    VoidCallback? action,
  ) {
    return IconButton(
      mouseCursor: SystemMouseCursors.click,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: action,
      icon: HugeIcon(icon: icon, size: 16, color: color),
    );
  }

  Widget _buildTaskListButton(BuildContext context, Color color) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final isSelected = controller
            .getSelectionStyle()
            .attributes
            .containsKey(Attribute.list.key);
        return IconButton(
          mouseCursor: SystemMouseCursors.click,
          tooltip: 'note_task_list'.tr(),
          visualDensity: VisualDensity.compact,
          isSelected: isSelected,
          style: IconButton.styleFrom(
            foregroundColor:
                isSelected ? Theme.of(context).colorScheme.primary : color,
          ),
          onPressed: () {
            controller.formatSelection(Attribute.checked);
            focusNode.requestFocus();
          },
          icon: Icon(
            Icons.checklist,
            size: 18,
            color: isSelected ? Theme.of(context).colorScheme.primary : color,
          ),
        );
      },
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .5),
    );
  }

  /// 标题级别按钮（正文 / H1 / H2 / H3 / 代码块）
  Widget _buildHeaderButton(BuildContext context, Color color) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final style = controller.getSelectionStyle();
        final headerValue = style.attributes[Attribute.header.key]?.value;
        final isCodeBlock =
            style.attributes.containsKey(Attribute.codeBlock.key);

        final IconData icon;
        final bool active;
        if (isCodeBlock) {
          icon = Icons.code;
          active = true;
        } else {
          icon = switch (headerValue) {
            1 => Icons.title,
            2 => Icons.title,
            3 => Icons.title,
            _ => Icons.text_fields,
          };
          active = headerValue != null;
        }

        return IconButton(
          mouseCursor: SystemMouseCursors.click,
          tooltip: 'note_header'.tr(),
          visualDensity: VisualDensity.compact,
          isSelected: active,
          style: IconButton.styleFrom(
            foregroundColor: active ? Theme.of(context).colorScheme.primary : color,
            backgroundColor: active
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
          ),
          onPressed: () {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final offset = box.localToGlobal(Offset.zero);

            showMenu<Object>(
              context: context,
              position: RelativeRect.fromLTRB(
                offset.dx,
                offset.dy + box.size.height + 4,
                offset.dx + box.size.width,
                offset.dy + box.size.height + 4 + 240,
              ),
              items: [
                _menuItem('note_header_normal', Icons.text_fields),
                _menuItem('note_header_h1', Icons.title),
                _menuItem('note_header_h2', Icons.title),
                _menuItem('note_header_h3', Icons.title),
                _menuItem('note_header_code', Icons.code),
              ],
            ).then((value) {
              if (value == null) return;
              switch (value) {
                case 'normal':
                  controller.formatSelection(
                    Attribute.clone(Attribute.header, null),
                  );
                case 'h1':
                  controller.formatSelection(Attribute.h1);
                case 'h2':
                  controller.formatSelection(Attribute.h2);
                case 'h3':
                  controller.formatSelection(Attribute.h3);
                case 'code':
                  controller.formatSelection(Attribute.codeBlock);
              }
              focusNode.requestFocus();
            });
          },
          icon: Icon(icon, size: 16),
        );
      },
    );
  }

  PopupMenuItem<Object> _menuItem(String labelKey, IconData icon) {
    return PopupMenuItem<Object>(
      value: labelKey,
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(labelKey.tr()),
        ],
      ),
    );
  }

  /// 对齐方式按钮
  Widget _buildAlignButton(BuildContext context, Color color) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final style = controller.getSelectionStyle();
        final alignValue = style.attributes[Attribute.align.key]?.value;
        final icon = switch (alignValue) {
          'center' => HugeIcons.strokeRoundedTextAlignCenter,
          'right' => HugeIcons.strokeRoundedTextAlignRight,
          'justify' => HugeIcons.strokeRoundedTextAlignJustifyCenter,
          _ => HugeIcons.strokeRoundedTextAlignLeft,
        };
        final active = alignValue != null;

        return IconButton(
          mouseCursor: SystemMouseCursors.click,
          tooltip: 'note_align'.tr(),
          visualDensity: VisualDensity.compact,
          isSelected: active,
          style: IconButton.styleFrom(
            foregroundColor: active ? Theme.of(context).colorScheme.primary : color,
          ),
          onPressed: () {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final offset = box.localToGlobal(Offset.zero);

            showMenu<String>(
              context: context,
              position: RelativeRect.fromLTRB(
                offset.dx,
                offset.dy + box.size.height + 4,
                offset.dx + box.size.width,
                offset.dy + box.size.height + 4 + 240,
              ),
              items: [
                _stringMenuItem('note_align_left', Icons.format_align_left),
                _stringMenuItem('note_align_center', Icons.format_align_center),
                _stringMenuItem('note_align_right', Icons.format_align_right),
                _stringMenuItem('note_align_justify', Icons.format_align_justify),
              ],
            ).then((value) {
              if (value == null) return;
              controller.formatSelection(
                switch (value) {
                  'center' => Attribute.centerAlignment,
                  'right' => Attribute.rightAlignment,
                  'justify' => Attribute.justifyAlignment,
                  _ => Attribute.leftAlignment,
                },
              );
              focusNode.requestFocus();
            });
          },
          icon: HugeIcon(icon: icon, size: 16),
        );
      },
    );
  }

  PopupMenuItem<String> _stringMenuItem(String labelKey, IconData icon) {
    return PopupMenuItem<String>(
      value: labelKey,
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(labelKey.tr()),
        ],
      ),
    );
  }

  void _clearAttributes() {
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

  /// 链接按钮：弹出输入框设置/移除链接
  Widget _buildLinkButtonImpl(BuildContext context, Color color) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final isLinked = controller
            .getSelectionStyle()
            .attributes
            .containsKey(Attribute.link.key);
        return IconButton(
          mouseCursor: SystemMouseCursors.click,
          tooltip: 'note_link'.tr(),
          visualDensity: VisualDensity.compact,
          isSelected: isLinked,
          style: IconButton.styleFrom(
            foregroundColor:
                isLinked ? Theme.of(context).colorScheme.primary : color,
          ),
          onPressed: () => _onLinkPressed(context, isLinked),
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedLink01, size: 16),
        );
      },
    );
  }

  Future<void> _onLinkPressed(BuildContext context, bool isLinked) async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('note_link'.tr()),
        content: TextField(
          controller: controller,
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
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text('note_link_apply'.tr()),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (url != null && url.isEmpty) {
      this.controller.formatSelection(
        Attribute.clone(Attribute.link, null),
      );
      return;
    }
    if (url == null) return;
    this.controller.formatSelection(LinkAttribute(url));
    focusNode.requestFocus();
  }

  /// 选择并上传图片，成功后插入编辑器
  Future<void> _insertImage(BuildContext context, WidgetRef ref) async {
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
}