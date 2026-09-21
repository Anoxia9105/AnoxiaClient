import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hugeicons/hugeicons.dart';

import 'note_image_embed.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

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

  // 存量笔记可能没有宽高，此时从 ImageProvider 回调拿自然尺寸再自适应。
  double? _intrinsicWidth;
  double? _intrinsicHeight;
  String? _intrinsicUrl;
  ImageStream? _intrinsicStream;
  ImageStreamListener? _intrinsicListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeResolveIntrinsic();
    });
  }

  @override
  void didUpdateWidget(covariant _NoteImageEmbed oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeResolveIntrinsic();
    });
  }

  @override
  void dispose() {
    _detachIntrinsicListener();
    super.dispose();
  }

  /// embed 自带宽高或用户拖过尺寸时无需解析；否则按 url 解析自然尺寸。
  void _maybeResolveIntrinsic() {
    final data = decodeNoteImageData(widget.node.value.data);
    final storedWidth = (data['width'] as num?)?.toDouble();
    final storedHeight = (data['height'] as num?)?.toDouble();
    final hasStored = storedWidth != null &&
        storedWidth > 0 &&
        storedHeight != null &&
        storedHeight > 0;
    final url = data['url']?.toString();
    if (hasStored ||
        _dragWidth != null ||
        url == null ||
        url.isEmpty ||
        url == _intrinsicUrl) {
      return;
    }
    _detachIntrinsicListener();
    _intrinsicUrl = url;
    // url 已换，旧自然尺寸不再可用，先清掉避免沿用错误比例。
    _intrinsicWidth = null;
    _intrinsicHeight = null;
    final stream = NetworkImage(url).resolve(const ImageConfiguration());
    _intrinsicStream = stream;
    _intrinsicListener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(() {
          _intrinsicWidth = info.image.width.toDouble();
          _intrinsicHeight = info.image.height.toDouble();
        });
      },
      onError: (_, _) {},
    );
    stream.addListener(_intrinsicListener!);
  }

  void _detachIntrinsicListener() {
    final stream = _intrinsicStream;
    final listener = _intrinsicListener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _intrinsicStream = null;
    _intrinsicListener = null;
  }

  @override
  Widget build(BuildContext context) {
    final data = decodeNoteImageData(widget.node.value.data);
    final id = data['id']?.toString();
    final url = data['url']?.toString();
    // 缺宽高时不再回退固定值，交由 resolve 按自然尺寸或占位自适应。
    final storedWidth = (data['width'] as num?)?.toDouble();
    final storedHeight = (data['height'] as num?)?.toDouble();
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 40;
        final displaySize = resolveNoteImageDisplaySize(
          storedWidth: _dragWidth ?? storedWidth,
          storedHeight: _dragHeight ?? storedHeight,
          intrinsicWidth: _intrinsicWidth,
          intrinsicHeight: _intrinsicHeight,
          maxWidth: maxWidth,
        );
        final width = displaySize.width;
        final height = displaySize.height;
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
                borderRadius: BorderRadius.circular(RadiusToken.md),
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
                            // 右下角手柄只做等比缩放：以宽度为基准，
                            // 横向与纵向位移合并驱动，任意方向拖动都跟手。
                            final resized = noteImageResize(
                              width,
                              height,
                              details.delta.dx + details.delta.dy,
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
                                topLeft: Radius.circular(RadiusToken.md),
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
