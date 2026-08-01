import 'dart:convert';
import 'dart:ui' as ui;

import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/embedBuilder/quill_file_build.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/embedBuilder/quill_image_build.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/embedBuilder/quill_mention_build.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_code_line_number.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/code_language.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_syntax_highlighter.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_style_config.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../../../framework/domain/chat_message.dart';
import 'base/message_render_strategy.dart';
import 'link_preview_card.dart';

/// 富文本消息渲染策略
///
/// 使用 Quill 编辑器渲染富文本消息，支持：
/// - 文本样式（加粗、斜体、颜色等）
/// - 图片嵌入
/// - 文件嵌入
/// - @提及用户高亮
/// - 动态宽度计算
class QuillMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    return _QuillInternalRenderer(message: message, textColor: textColor);
  }
}

class _QuillInternalRenderer extends StatefulWidget {
  final ChatMessage message;
  final Color textColor;

  const _QuillInternalRenderer({
    required this.message,
    required this.textColor,
  });

  @override
  State<_QuillInternalRenderer> createState() => _QuillInternalRendererState();
}

class _QuillInternalRendererState extends State<_QuillInternalRenderer> {
  static final Set<_QuillInternalRendererState> _mountedRenderers = {};

  /// 防止「清理兄弟气泡选区」链路重入。
  ///
  /// flutter_quill 的 `QuillRawEditorState` 会**无条件**监听 controller
  /// (`controller.addListener(_didChangeTextEditingValueListener)`)，并且
  /// `_didChangeTextEditingValue` 里有 Web 专属分支：
  ///
  /// ```dart
  /// if (kIsWeb) {
  ///   _onChangeTextEditingValue(ignoreFocus);
  ///   if (!ignoreFocus) requestKeyboard(); // -> focusNode.requestFocus()
  ///   return;
  /// }
  /// ```
  ///
  /// 也就是说在 Web 上，对只读气泡调用一次 `updateSelection` 就会让它把焦点抢回去。
  /// 于是会出现：A 获得焦点 -> 清空所有兄弟选区 -> 兄弟 requestFocus ->
  /// 兄弟获得焦点 -> 再清空所有兄弟选区 …… 同步无限互抢，主线程被打死，
  /// 表现为「切换聊天列表后页面直接卡死、无任何日志」。桌面/移动端不走该分支，
  /// 所以只在 Web 复现。
  static bool _clearingSiblings = false;

  QuillController? _controller;
  bool _isError = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _mountedRenderers.add(this);
    // Web 端只读气泡：禁止 FocusNode 抢占焦点。
    //
    // flutter_quill 的 Web 分支在 _didChangeTextEditingValue 中会无条件调用
    // requestKeyboard() -> focusNode.requestFocus()（见本文件上方长注释）。
    // 现有的 _clearingSiblings 标志只能拦住「应用侧」清选区触发的 requestFocus，
    // 拦不住 quill 内部（手势/选区叠加层）直接 updateSelection 触发的 requestFocus。
    // 多个只读气泡因此会同步互抢焦点 -> 无限递归 -> Maximum call stack size exceeded，
    // 表现为「聊天消息渲染卡死」。让 FocusNode 不可抢焦点后 requestFocus 变为 no-op，
    // 从根本上掐断互抢链路；桌面/移动端不受 kIsWeb 分支影响，保留完整选区交互。
    _focusNode = FocusNode(canRequestFocus: !kIsWeb);
    _focusNode.addListener(_onFocusChanged);
    _initController();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _clearSiblingSelections();
      return;
    }

    _clearSelection();
  }

  @override
  void didUpdateWidget(covariant _QuillInternalRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.payload?.quillDelta !=
        widget.message.payload?.quillDelta) {
      _controller?.dispose();
      _initController();
      setState(() {});
    }
  }

  void _initController() {
    try {
      final delta = jsonDecode(widget.message.payload?.quillDelta ?? '[]');
      _controller = QuillController(
        document: Document.fromJson(delta),
        selection: const TextSelection.collapsed(offset: 0),
      );
      _controller?.readOnly = true;
      _isError = false;
    } catch (e) {
      _controller = null;
      _isError = true;
    }
  }

  @override
  void dispose() {
    _mountedRenderers.remove(this);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError || _controller == null) {
      return Text('chat_message_format_error'.tr());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = _safeMaxWidth(context, constraints.maxWidth);
        final targetWidth = _resolveTargetWidth(context, maxWidth);
        final previewSource = _linkPreviewSource();

        return SizedBox(
          width: targetWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Listener(
                    onPointerDown: (_) => _clearSiblingSelections(),
                    child: QuillEditor.basic(
                      focusNode: _focusNode,
                      controller: _controller!,
                      config: QuillEditorConfig(
                        textSelectionThemeData: TextSelectionThemeData(
                          selectionColor: Colors.blueAccent.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        enableSelectionToolbar: false,
                        showCursor: false,
                        autoFocus: false,
                        expands: false,
                        scrollable: false,
                        padding: EdgeInsets.zero,
                        customStyles: QuillStyleConfig.get(
                          context,
                          color: widget.textColor,
                          compact: true,
                        ),
                        textSpanBuilder: QuillSyntaxHighlighter.buildSpan,
                        // ignore: experimental_member_use
                        customLeadingBlockBuilder: (node, config) =>
                            QuillCodeLineNumber.build(
                              node,
                              config,
                              showLanguageBadge: false,
                            ),
                        onTapOutside: (_, focusNode) {
                          focusNode.unfocus();
                          _clearSelection();
                        },
                        embedBuilders: [
                          QuillImageBuild(),
                          QuillFileBuild(),
                          QuillMentionBuild(),
                        ],
                      ),
                    ),
                  ),
                  if (_codeLanguage() case final language?)
                    Positioned(
                      top: 2,
                      right: 8,
                      child: IgnorePointer(
                        child: QuillCodeLanguageBadge(language: language),
                      ),
                    ),
                ],
              ),
              MessageLinkPreview(text: previewSource, maxWidth: targetWidth),
            ],
          ),
        );
      },
    );
  }

  void _clearSiblingSelections() {
    if (_clearingSiblings) return;
    _clearingSiblings = true;
    try {
      // 迭代前先快照：_clearSelection 会触发 Quill 重建，期间可能有气泡
      // mount/dispose 从而增删 _mountedRenderers，直接遍历会抛
      // ConcurrentModificationError。
      for (final renderer in _mountedRenderers.toList(growable: false)) {
        if (identical(renderer, this)) continue;
        renderer._clearSelection();
      }
    } finally {
      _clearingSiblings = false;
    }
  }

  void _clearSelection() {
    final controller = _controller;
    if (controller == null) return;

    final selection = controller.selection;
    // `TextSelection.collapsed(offset: 0)` 本身也是 isValid，原先的判断等价于
    // 「永远执行」，导致每次焦点变化都会对全部气泡写一次 selection。
    // 只有真正存在可见选区时才需要清理。
    if (!selection.isValid || selection.isCollapsed) return;

    // 抑制 Web 分支里的 requestKeyboard() -> focusNode.requestFocus()，
    // 否则被清理的气泡会把焦点抢回来，形成焦点/选区死循环。
    final previousIgnoreFocus = controller.ignoreFocusOnTextChange;
    controller.ignoreFocusOnTextChange = true;
    try {
      controller.updateSelection(
        const TextSelection.collapsed(offset: 0),
        ChangeSource.local,
      );
    } finally {
      controller.ignoreFocusOnTextChange = previousIgnoreFocus;
    }
  }

  /// 计算消息内容的目标宽度
  double _safeMaxWidth(BuildContext context, double constraintWidth) {
    if (!constraintWidth.isFinite || constraintWidth <= 0) {
      return MessageLinkPreview.maxCardWidth;
    }
    if (constraintWidth <= 64) return constraintWidth;

    final viewportLimit = MediaQuery.sizeOf(context).width * 0.72;
    final availableWidth = viewportLimit < constraintWidth
        ? viewportLimit
        : constraintWidth;
    return availableWidth.clamp(64.0, constraintWidth).toDouble();
  }

  double _resolveTargetWidth(BuildContext context, double maxWidth) {
    // Code blocks need a stable content column next to their fixed line-number
    // gutter. Treat them like other block content instead of shrinking the
    // message bubble to the measured width of a short code line.
    if (_requiresFullWidth()) return maxWidth;

    final hasLinkPreview =
        MessageLinkPreview.extractFirstUrl(_linkPreviewSource()) != null;
    final minWidth = hasLinkPreview ? MessageLinkPreview.minCardWidth : 64;
    final effectiveMinWidth = minWidth.clamp(0.0, maxWidth).toDouble();
    final measuredWidth = _measureInlineContentWidth(context, maxWidth);
    return measuredWidth.clamp(effectiveMinWidth, maxWidth).toDouble();
  }

  double _measureInlineContentWidth(BuildContext context, double maxWidth) {
    final dynamic opsJson = _controller?.document.toDelta().toJson();
    if (opsJson is! List) return 64;

    final baseStyle = TextStyle(
      fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
      fontSize: 14,
      height: 1,
    );
    final textScaler = MediaQuery.textScalerOf(context);
    final spans = <InlineSpan>[];
    final placeholders = <PlaceholderDimensions>[];
    var hasVisibleContent = false;
    var hasBlockQuote = false;

    for (final op in opsJson) {
      if (op is! Map) continue;
      final insert = op['insert'];
      final attributes = op['attributes'];
      if (attributes is Map &&
          attributes.containsKey(Attribute.blockQuote.key)) {
        hasBlockQuote = true;
      }

      if (insert is String) {
        if (insert.replaceAll('\n', '').isNotEmpty) hasVisibleContent = true;
        spans.add(
          TextSpan(
            text: insert,
            style: _measurementStyle(baseStyle, attributes),
          ),
        );
        continue;
      }

      if (insert is! Map || !insert.containsKey('mention')) continue;
      hasVisibleContent = true;

      final mentionText = _mentionText(insert['mention']);
      final mentionStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);
      final mentionPainter = TextPainter(
        text: TextSpan(text: mentionText, style: mentionStyle),
        textDirection: ui.TextDirection.ltr,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();

      // 与 QuillMentionBuild 的左右 margin(4) + padding(8) 保持一致。
      final mentionWidth = mentionPainter.width + 12;
      final mentionHeight = mentionPainter.height + 4;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: SizedBox(width: mentionWidth, height: mentionHeight),
        ),
      );
      placeholders.add(
        PlaceholderDimensions(
          size: Size(mentionWidth, mentionHeight),
          alignment: PlaceholderAlignment.middle,
        ),
      );
    }

    if (!hasVisibleContent) return 64;

    final painter = TextPainter(
      text: TextSpan(style: baseStyle, children: spans),
      textDirection: ui.TextDirection.ltr,
      textScaler: textScaler,
    );
    painter
      ..setPlaceholderDimensions(placeholders)
      ..layout(maxWidth: maxWidth);

    var widestLine = 0.0;
    for (final line in painter.computeLineMetrics()) {
      if (line.width > widestLine) widestLine = line.width;
    }

    // 给字形取整和 Quill 行布局留少量余量，避免临界宽度提前换行。
    // Leave room for the quote bar and its inset, but keep short quotes
    // compact instead of forcing them to occupy the full message width.
    final blockQuoteInset = hasBlockQuote ? 24.0 : 0.0;
    return (widestLine.ceilToDouble() + blockQuoteInset + 2)
        .clamp(0.0, maxWidth)
        .toDouble();
  }

  TextStyle _measurementStyle(TextStyle baseStyle, dynamic attributes) {
    if (attributes is! Map) return baseStyle;

    return baseStyle.copyWith(
      fontWeight: attributes['bold'] == true ? FontWeight.bold : null,
      fontStyle: attributes['italic'] == true ? FontStyle.italic : null,
      decoration:
          attributes['underline'] == true || attributes['strike'] == true
          ? TextDecoration.combine([
              if (attributes['underline'] == true) TextDecoration.underline,
              if (attributes['strike'] == true) TextDecoration.lineThrough,
            ])
          : null,
    );
  }

  String _mentionText(dynamic rawData) {
    try {
      final dynamic data = rawData is String ? jsonDecode(rawData) : rawData;
      if (data is Map) {
        final userName = data['userName']?.toString().trim();
        if (userName != null && userName.isNotEmpty) return '@$userName';
      }
    } catch (_) {
      // 渲染器会使用占位名称；测量失败时保持相同的安全回退。
    }
    return '@--';
  }

  bool _requiresFullWidth() {
    final dynamic opsJson = _controller?.document.toDelta().toJson();
    if (opsJson is! List) return false;

    for (final op in opsJson) {
      if (op is! Map) continue;
      final insert = op['insert'];
      final attributes = op['attributes'];
      if (attributes is Map) {
        if (attributes.containsKey(Attribute.codeBlock.key)) {
          return true;
        }
      }
      if (insert is Map && !insert.containsKey('mention')) return true;
    }
    return false;
  }

  String _linkPreviewSource() {
    final buffer = StringBuffer(_controller?.document.toPlainText() ?? '');
    final dynamic opsJson = _controller?.document.toDelta().toJson();
    if (opsJson is! List) return buffer.toString();

    for (final op in opsJson) {
      if (op is! Map) continue;
      final attributes = op['attributes'];
      if (attributes is! Map) continue;
      final link = attributes['link']?.toString();
      if (link == null || link.isEmpty) continue;
      buffer
        ..write(' ')
        ..write(link);
    }
    return buffer.toString();
  }

  CodeLanguage? _codeLanguage() {
    final dynamic opsJson = _controller?.document.toDelta().toJson();
    if (opsJson is! List) return null;

    final source = StringBuffer();
    String? selectedLanguage;
    var pendingText = '';
    var foundCodeBlock = false;

    for (final op in opsJson) {
      if (op is! Map) continue;
      final insert = op['insert'];
      if (insert is String) pendingText += insert;

      final attributes = op['attributes'];
      final codeValue = attributes is Map
          ? attributes[Attribute.codeBlock.key]
          : null;
      if (codeValue != null) {
        foundCodeBlock = true;
        source.write(pendingText);
        pendingText = '';
        if (codeValue is String) selectedLanguage ??= codeValue;
      } else if (insert is String && insert.contains('\n') && foundCodeBlock) {
        break;
      }
    }

    if (!foundCodeBlock) return null;
    return selectedLanguage == null
        ? CodeLanguageDetector.detect(source.toString())
        : CodeLanguageDetector.fromId(selectedLanguage) ??
              CodeLanguageDetector.plainText;
  }
}
