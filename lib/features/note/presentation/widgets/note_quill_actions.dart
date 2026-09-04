import 'dart:typed_data';

import 'package:anoxia/common/utils/quill_embed_util.dart';
import 'package:anoxia/common/widgets/adaptive_page_presenter.dart';
import 'package:anoxia/common/widgets/bubble_dialog.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/colors_box.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/provider/core/upload_repository_provider.dart';
import 'package:anoxia/framework/provider/note/note_content_provider.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:cross_file/cross_file.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'note_image_embed.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

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
  final has = controller.getSelectionStyle().attributes.containsKey(attr.key);
  controller.formatSelection(has ? Attribute.clone(attr, null) : attr);
}

/// 设置/移除链接：弹出输入框（斜杠命令等无按钮锚点时使用）。
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
          onPressed: () => Navigator.of(dialogContext).pop(input.text.trim()),
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

/// 在按钮下方弹出气泡面板（仿聊天输入框的气泡样式）。
///
/// 返回关闭函数；点击气泡外部会自动关闭。
/// 使用 OverlayEntry + GlobalKey 精确计算箭头偏移，确保气泡尖角指向按钮中心。
///
/// [anchorKey] 按钮的 GlobalKey，提供时可精确获取按钮 render box；不提供时退回 Builder 上下文查找。
Function showNoteBubble(
  BuildContext anchorContext, {
  required Widget child,
  double arrowOffset = 20,
  double maxWidth = 260,
  GlobalKey? anchorKey,
}) {
  final colorScheme = Theme.of(anchorContext).colorScheme;
  RenderBox? getRenderBox() {
    if (anchorKey != null && anchorKey.currentContext != null) {
      return anchorKey.currentContext!.findRenderObject() as RenderBox?;
    }
    return anchorContext.findRenderObject() as RenderBox?;
  }

  final renderBox = getRenderBox();
  if (renderBox == null || !renderBox.hasSize) {
    return Toast.showWidget(
      anchorContext,
      direction: PreferDirection.bottomLeft,
      child: Material(
        color: Colors.transparent,
        child: BubbleWidget(
          arrowDirection: AxisDirection.up,
          arrowOffset: arrowOffset,
          backgroundColor: colorScheme.surface,
          border: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: .8),
            width: .5,
          ),
          borderRadius: BorderRadius.circular(RadiusToken.lg),
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .16),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
          contentBuilder: (_) => ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      ),
    );
  }

  final buttonGlobal = renderBox.localToGlobal(Offset.zero);
  final screenSize = MediaQuery.sizeOf(anchorContext);
  final targetRect = Rect.fromLTWH(
    buttonGlobal.dx,
    buttonGlobal.dy,
    renderBox.size.width,
    renderBox.size.height,
  );
  final bubbleWidth = maxWidth;
  final estimatedHeight = 200.0;
  final placement = resolveAnchoredBubblePlacement(
    targetRect: targetRect,
    screenSize: screenSize,
    bubbleWidth: bubbleWidth,
    estimatedHeight: estimatedHeight,
    preferRightArrow: targetRect.center.dx >= screenSize.width / 2,
    arrowInset: 20,
    safeTop: MediaQuery.paddingOf(anchorContext).top,
  );

  // 修正：left 不能超出屏幕右边界；arrowOffset 必须在气泡宽度范围内
  final clampedLeft = placement.left.clamp(8.0, screenSize.width - bubbleWidth - 8.0);
  final clampedArrowOffset = placement.arrowOffset.clamp(20.0, bubbleWidth - 20.0);

  final overlay = Overlay.of(anchorContext, rootOverlay: true);
  late final OverlayEntry entry;
  bool closed = false;

  void close() {
    if (closed) return;
    closed = true;
    entry.remove();
  }

  entry = OverlayEntry(
    builder: (_) => Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => close(),
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          left: clampedLeft,
          top: placement.showBelow ? placement.anchorY : null,
          bottom: placement.showBelow ? null : screenSize.height - placement.anchorY,
          child: Material(
            color: Colors.transparent,
            child: BubbleWidget(
              arrowDirection: placement.arrowDirection,
              arrowOffset: clampedArrowOffset,
              backgroundColor: colorScheme.surface,
              border: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: .8),
                width: .5,
              ),
              borderRadius: BorderRadius.circular(RadiusToken.lg),
              shadows: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .16),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
              contentBuilder: (_) => SizedBox(
                width: bubbleWidth,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: placement.maxHeight - 10),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  overlay.insert(entry);
  return close;
}

/// 选择文字/背景颜色：以气泡方式弹出颜色面板（仿聊天输入框），
/// 锚定在按钮下方，点击颜色立即生效并关闭。
void notePickColorBubble(
  BuildContext buttonContext,
  GlobalKey anchorKey,
  QuillController controller,
  FocusNode focusNode, {
  required bool background,
}) {
  Function? onCancel;
  onCancel = showNoteBubble(
    buttonContext,
    anchorKey: anchorKey,
    maxWidth: 300,
    child: ColorsBox.buildColorsWidget(
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
        onCancel?.call();
        focusNode.requestFocus();
      },
      buttonContext,
      // 气泡自带边框，关闭面板内层边框，避免双重描边
      showBorder: false,
      selectedColor: ColorsBox.parseColorFromValue(
        controller
            .getSelectionStyle()
            .attributes[background
                ? Attribute.background.key
                : Attribute.color.key]
            ?.value,
      ),
    ),
  );
}

/// 设置链接：气泡式输入框（仿聊天输入框），锚定在按钮下方。
///
/// 上方为「文本」输入、下方为「链接」输入；若已选中文本，
/// 文本输入框自动回显选中内容，只需填写链接即可。
void noteSetLinkBubble(
  BuildContext buttonContext,
  GlobalKey anchorKey,
  QuillController controller,
  FocusNode focusNode,
) {
  final selection = controller.selection;
  final hasSelection = selection.isValid && !selection.isCollapsed;
  final selectedText = hasSelection
      ? controller.document.getPlainText(
          selection.start,
          selection.end - selection.start,
        )
      : '';
  final currentUrl = controller
      .getSelectionStyle()
      .attributes[Attribute.link.key]
      ?.value;

  final textController = TextEditingController(text: selectedText);
  final urlController = TextEditingController(
    text: currentUrl is String ? currentUrl : '',
  );

  Function? onCancel;
  onCancel = showNoteBubble(
    buttonContext,
    anchorKey: anchorKey,
    maxWidth: 320,
    child: NoteLinkBubble(
      textController: textController,
      urlController: urlController,
      // 已回显选中文本时，直接聚焦链接输入框，只需填链接
      autofocusUrl: hasSelection,
      onApply: () {
        onCancel?.call();
        _applyLink(
          controller,
          focusNode,
          text: textController.text.trim(),
          url: urlController.text.trim(),
        );
      },
      onCancel: () => onCancel?.call(),
    ),
  );
}

/// 应用链接：优先用「文本」替换选区（无选区则在光标处插入），
/// 再对整个目标文本套用链接；链接为空则移除链接。
void _applyLink(
  QuillController controller,
  FocusNode focusNode, {
  required String text,
  required String url,
}) {
  final selection = controller.selection;
  final hasSelection = selection.isValid && !selection.isCollapsed;

  int start = selection.baseOffset;
  int end = selection.baseOffset;
  var replaced = false;

  if (text.isNotEmpty) {
    // 用自定义文本替换选区（无选区则在光标处插入）
    if (hasSelection) {
      start = selection.start;
      end = selection.end;
    }
    controller.replaceText(
      start,
      end - start,
      text,
      TextSelection.collapsed(offset: start + text.length),
    );
    end = start + text.length;
    replaced = true;
  } else if (hasSelection) {
    start = selection.start;
    end = selection.end;
  }

  if (url.isEmpty) {
    // 链接为空：移除链接（被替换的文本天然不带链接）
    if (!replaced) {
      controller.formatSelection(Attribute.clone(Attribute.link, null));
    }
  } else {
    if (replaced || hasSelection) {
      controller.updateSelection(
        TextSelection(baseOffset: start, extentOffset: end),
        ChangeSource.local,
      );
      controller.formatSelection(LinkAttribute(url));
    } else {
      // 折叠光标且无文本：仅设置待输入格式，后续输入即为链接
      controller.formatSelection(LinkAttribute(url));
    }
  }
  if (replaced || hasSelection) {
    controller.updateSelection(
      TextSelection.collapsed(offset: end),
      ChangeSource.local,
    );
  }
  focusNode.requestFocus();
}

/// 气泡式链接输入面板：文本输入 + 链接输入 + 取消/应用。
class NoteLinkBubble extends StatefulWidget {
  const NoteLinkBubble({
    super.key,
    required this.textController,
    required this.urlController,
    required this.autofocusUrl,
    required this.onApply,
    required this.onCancel,
  });

  final TextEditingController textController;
  final TextEditingController urlController;

  /// 已回显选中文本时为 true，打开后直接聚焦链接输入框
  final bool autofocusUrl;
  final VoidCallback onApply;
  final VoidCallback onCancel;

  @override
  State<NoteLinkBubble> createState() => _NoteLinkBubbleState();
}

class _NoteLinkBubbleState extends State<NoteLinkBubble> {
  final FocusNode _textFocus = FocusNode();
  final FocusNode _urlFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.autofocusUrl) {
        _urlFocus.requestFocus();
      } else {
        _textFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _textFocus.dispose();
    _urlFocus.dispose();
    widget.textController.dispose();
    widget.urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: widget.textController,
              focusNode: _textFocus,
              style: const TextStyle(fontSize: 14),
              onSubmitted: (_) => _urlFocus.requestFocus(),
              decoration: InputDecoration(
                labelText: 'note_link_text'.tr(),
                hintText: 'note_link_text_hint'.tr(),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RadiusToken.md),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: widget.urlController,
              focusNode: _urlFocus,
              style: const TextStyle(fontSize: 14),
              keyboardType: TextInputType.url,
              onSubmitted: (_) => widget.onApply(),
              decoration: InputDecoration(
                labelText: 'note_link_url'.tr(),
                hintText: 'note_link_url_hint'.tr(),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RadiusToken.md),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: Text('cancel'.tr()),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: widget.onApply,
                  child: Text('note_link_apply'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 选择文字/背景颜色：弹出颜色面板。
Future<void> notePickColor(
  BuildContext context,
  QuillController controller,
  FocusNode focusNode, {
  required bool background,
}) async {
  await showEscClosableDialog<void>(
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
        selectedColor: ColorsBox.parseColorFromValue(
          controller
              .getSelectionStyle()
              .attributes[background
                  ? Attribute.background.key
                  : Attribute.color.key]
              ?.value,
        ),
      ),
    ),
  );
}

/// 在光标处插入水平分隔线（横向实线）。
///
/// 使用与 flutter_quill markdown 包内置 [horizontalRule] 相同的
/// `divider` 类型，保证 Markdown 导出（`---`）往返兼容。
void noteInsertHorizontalRule(QuillController controller, FocusNode focusNode) {
  final offset = controller.selection.baseOffset;
  if (offset < 0) return;
  controller.replaceText(
    offset,
    0,
    const BlockEmbed('divider', 'hr'),
    TextSelection.collapsed(offset: offset + 1),
  );
  focusNode.requestFocus();
}

/// 选择图片后立即插入占位，上传成功时按图片 ID 原位替换。
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

  final noteId = ref.read(noteSessionServiceProvider)?.noteId;
  if (noteId == null) return;

  final ids = List.generate(result.files.length, (_) => const Uuid().v4());
  final files = <XFile>[];
  final sizes = <int>[];
  for (var i = 0; i < result.files.length; i++) {
    final file = result.files[i];
    files.add(
      file.bytes != null
          ? XFile.fromData(file.bytes!, name: file.name)
          : XFile(file.path!, name: file.name),
    );
    sizes.add(file.size);
  }
  await _insertNoteImageEmbeds(controller, files, ids, sizes);
  if (!context.mounted) return;
  focusNode.requestFocus();

  await _uploadNoteImages(context, ref, controller, noteId, files, ids);
}

/// 从剪贴板粘贴图片字节，参考聊天输入框行为：立即插入占位并上传，成功后原位替换。
Future<void> notePasteImageBytes(
  BuildContext context,
  WidgetRef ref,
  QuillController controller,
  Uint8List imageBytes,
) async {
  final noteId = ref.read(noteSessionServiceProvider)?.noteId;
  if (noteId == null || imageBytes.isEmpty) return;

  final id = const Uuid().v4();
  final file = XFile.fromData(imageBytes, name: 'pasted_image.png');
  await _insertNoteImageEmbeds(controller, [file], [id], [imageBytes.length]);
  if (!context.mounted) return;

  await _uploadNoteImages(context, ref, controller, noteId, [file], [id]);
}

/// 为每个文件生成图片嵌入占位并标记上传中。
///
/// 插入前先解码图片自然尺寸并写入 embed，展示层首帧即可按真实比例
/// 自适应，而不是固定 320x220；解码失败则不写宽高，由展示层占位。
Future<void> _insertNoteImageEmbeds(
  QuillController controller,
  List<XFile> files,
  List<String> ids, [
  List<int>? sizes,
]) async {
  final dimensions = <(double?, double?)>[];
  for (final file in files) {
    dimensions.add(await _readNoteImageDimensions(file));
  }
  for (var i = 0; i < files.length; i++) {
    final file = files[i];
    noteImageUploadStore.uploading(ids[i]);
    final data = <String, dynamic>{
      'id': ids[i],
      'kind': 'IMAGE',
      'url': '',
      'name': file.name,
      'size': sizes != null ? sizes[i] : 0,
      'type': 'image/${file.name.split('.').last.toLowerCase()}',
    };
    final (naturalWidth, naturalHeight) = dimensions[i];
    if (naturalWidth != null && naturalHeight != null) {
      data['width'] = naturalWidth;
      data['height'] = naturalHeight;
    }
    QuillEmbedUtil.insertEmbed(
      controller: controller,
      type: BlockEmbed.imageType,
      data: data,
    );
  }
}

/// 读取待插入图片的自然尺寸，失败返回 (null, null) 不阻塞插入。
Future<(double?, double?)> _readNoteImageDimensions(XFile file) async {
  try {
    return await decodeNoteImageBytesSize(await file.readAsBytes());
  } catch (_) {
    return (null, null);
  }
}

/// 上传图片列表，成功后按图片 ID 把占位替换为真实 URL。
Future<void> _uploadNoteImages(
  BuildContext context,
  WidgetRef ref,
  QuillController controller,
  int? noteId,
  List<XFile> files,
  List<String> ids,
) async {
  try {
    final uploads = await ref
        .read(uploadRepositoryProvider)
        .uploadFiles(
          files,
          clientFileIds: ids,
          noteId: noteId,
          onProgress: (id, sent, total) {
            noteImageUploadStore.uploading(id, total <= 0 ? 0 : sent / total);
          },
          onCompleted: (upload) {
            if (!upload.isSuccess || upload.url == null) {
              noteImageUploadStore.failed(upload.clientFileId);
              return;
            }
            updateNoteImageEmbed(controller, upload.clientFileId, {
              'url': upload.url,
            });
            noteImageUploadStore.complete(upload.clientFileId);
          },
        );

    final failed = uploads.where((upload) => !upload.isSuccess).length;

    if (failed > 0 && context.mounted) {
      Toast.showToast(
        'note_image_upload_failed'.tr(args: [failed.toString()]),
        type: ToastType.error,
      );
    }
  } catch (e, st) {
    for (final id in ids) {
      noteImageUploadStore.failed(id);
    }
    debugLog('插入笔记图片失败: $e', st);
    if (!context.mounted) return;
    Toast.showToast('note_image_upload_error'.tr(), type: ToastType.error);
  }
}
