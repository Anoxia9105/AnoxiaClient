import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hugeicons/hugeicons.dart';

import 'note_image_embed.dart';

class NoteQuillImageBuild implements EmbedBuilder {
  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    return _NoteImageEmbed(
      controller: embedContext.controller,
      node: embedContext.node,
      readOnly: embedContext.readOnly,
    );
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

class _NoteImageEmbed extends StatefulWidget {
  const _NoteImageEmbed({
    required this.controller,
    required this.node,
    required this.readOnly,
  });

  final QuillController controller;
  final Embed node;
  final bool readOnly;

  @override
  State<_NoteImageEmbed> createState() => _NoteImageEmbedState();
}

class _NoteImageEmbedState extends State<_NoteImageEmbed> {
  double? _dragWidth;
  double? _dragHeight;

  @override
  Widget build(BuildContext context) {
    final data = decodeNoteImageData(widget.node.value.data);
    final id = data['id']?.toString();
    final url = data['url']?.toString();
    final rawWidth = (data['width'] as num?)?.toDouble() ?? 320;
    final rawHeight = (data['height'] as num?)?.toDouble() ?? 220;
    final storedWidth = rawWidth > 0 ? rawWidth : 320.0;
    final storedHeight = rawHeight > 0 ? rawHeight : 220.0;
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 40;
        final width = (_dragWidth ?? storedWidth).clamp(120.0, maxWidth);
        final height = _dragHeight ?? storedHeight * width / storedWidth;
        return ListenableBuilder(
          listenable: noteImageUploadStore,
          builder: (context, _) {
            final upload = noteImageUploadStore[id];
            final isUploading =
                upload?.status == NoteImageUploadStatus.uploading;
            final isFailed = upload?.status == NoteImageUploadStatus.failed;
            final progress = upload?.progress ?? 0;
            return Container(
              width: width,
              height: height,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isFailed
                      ? scheme.error
                      : scheme.outlineVariant,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (url != null && url.isNotEmpty)
                    Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          _placeholder(isFailed),
                    )
                  else
                    _placeholder(isFailed),
                  if (isUploading) ...[
                    ColoredBox(color: Colors.black.withValues(alpha: .28)),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            value: progress > 0 ? progress : null,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            progress > 0
                                ? '${(progress * 100).round()}%'
                                : '0%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: LinearProgressIndicator(
                        value: progress > 0 ? progress : null,
                        minHeight: 4,
                      ),
                    ),
                  ],
                  if (!widget.readOnly && !isUploading)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeUpLeftDownRight,
                        child: GestureDetector(
                          key: const ValueKey('note_image_resize_handle'),
                          behavior: HitTestBehavior.opaque,
                          onPanUpdate: (details) {
                            final resized = noteImageResize(
                              _dragWidth ?? width,
                              _dragHeight ?? height,
                              details.delta.dx,
                              maxWidth: maxWidth,
                            );
                            setState(() {
                              _dragWidth = resized.$1;
                              _dragHeight = resized.$2;
                            });
                          },
                          onPanEnd: (_) {
                            if (_dragWidth == null) return;
                            final changes = {
                              'width': _dragWidth,
                              'height': _dragHeight,
                            };
                            if (id != null) {
                              updateNoteImageEmbed(
                                widget.controller,
                                id,
                                changes,
                              );
                            } else {
                              updateNoteImageAtOffset(
                                widget.controller,
                                widget.node.documentOffset,
                                {...data, ...changes},
                              );
                            }
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: scheme.surface.withValues(alpha: .9),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                              ),
                            ),
                            child: Icon(
                              Icons.open_in_full,
                              size: 16,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _placeholder(bool failed) {
    return Center(
      child: HugeIcon(
        icon: failed
            ? HugeIcons.strokeRoundedCloudOff
            : HugeIcons.strokeRoundedImage01,
        size: 40,
        color: failed ? Theme.of(context).colorScheme.error : Colors.grey,
      ),
    );
  }
}
