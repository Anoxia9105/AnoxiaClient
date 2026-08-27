import 'dart:convert';
import 'dart:ui' as ui;

import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/embedBuilder/quill_file_build.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/embedBuilder/quill_image_build.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/embedBuilder/quill_mention_build.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_style_config.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_syntax_highlighter.dart';
import 'package:anoxia/features/chat/presentation/widgets/mention_list_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../../../framework/domain/chat_message.dart';
import 'code/code_block_view.dart';
import 'link_preview_card.dart';
import 'quill_renderer_helpers.dart';

/// 是否为 WASM 编译模式。
///
/// `kIsWeb` 在 JS 和 WASM 版 Web 均为 true，无法区分。利用
/// `dart.library.html` 仅在 JS 版 Web 为 true、WASM 版为 false 的特性来判定。
const _kIsWasm = kIsWeb && !bool.fromEnvironment('dart.library.html');

class QuillInternalRenderer extends StatefulWidget {
  final ChatMessage message;
  final Color textColor;
  final bool forceWasmRenderer;

  const QuillInternalRenderer({
    super.key,
    required this.message,
    required this.textColor,
    required this.forceWasmRenderer,
  });

  @override
  State<QuillInternalRenderer> createState() => QuillInternalRendererState();
}

class QuillInternalRendererState extends State<QuillInternalRenderer> {
  static final Set<QuillInternalRendererState> _mountedRenderers = {};

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

  /// 原始 Delta ops 列表，避免通过 Document.toDelta().toJson() 往返转换。
  ///
  /// WASM 模式下 flutter_quill 的 Document 往返可能产出空列表或格式异常，
  /// 导致消息渲染空白。直接缓存 JSON 解析后的原始 ops 可以绕过此问题。
  List<dynamic>? _rawDeltaOps;

  bool get _useWasmRenderer => _kIsWasm || widget.forceWasmRenderer;

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
  void didUpdateWidget(covariant QuillInternalRenderer oldWidget) {
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
      _rawDeltaOps = delta is List ? delta : null;
      _controller = QuillController(
        document: Document.fromJson(delta),
        selection: const TextSelection.collapsed(offset: 0),
      );
      _controller?.readOnly = true;
      _isError = false;
    } catch (e) {
      _controller = null;
      _rawDeltaOps = null;
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

    // WASM 降级：QuillEditor.basic 在 WASM 下可能触发 Platform._operatingSystem
    // 等不兼容问题，因此不能直接复用编辑器。但这里仍需按 Delta 渲染，不能使用
    // Document.toPlainText()：该方法会把 mention 等 embed 转成对象替换符 \uFFFC，
    // 同时会丢失 color/bold/italic 等所有 attributes。
    if (_useWasmRenderer) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = _safeMaxWidth(context, constraints.maxWidth);
          final targetWidth = _resolveTargetWidth(context, maxWidth);
          final previewSource = quillLinkPreviewSource(_rawDeltaOps);
          return SizedBox(
            width: targetWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWasmRichText(context),
                MessageLinkPreview(text: previewSource, maxWidth: targetWidth),
              ],
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = _safeMaxWidth(context, constraints.maxWidth);
        final targetWidth = _resolveTargetWidth(context, maxWidth);
        final previewSource = quillLinkPreviewSource(_rawDeltaOps);

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
    if (quillRequiresFullWidth(_rawDeltaOps)) return maxWidth;

    final hasLinkPreview =
        MessageLinkPreview.extractFirstUrl(
          quillLinkPreviewSource(_rawDeltaOps),
        ) != null;
    // 普通富文本按实际内容收缩；原来的 64px 下限会让 "111" 这类短消息
    // 无缘由地多出大块空白。链接预览仍保留卡片自身需要的最小宽度。
    final minWidth = hasLinkPreview ? MessageLinkPreview.minCardWidth : 1;
    final effectiveMinWidth = minWidth.clamp(0.0, maxWidth).toDouble();
    final measuredWidth = _measureInlineContentWidth(context, maxWidth);
    return measuredWidth.clamp(effectiveMinWidth, maxWidth).toDouble();
  }

  double _measureInlineContentWidth(BuildContext context, double maxWidth) {
    final opsJson = _rawDeltaOps;
    if (opsJson is! List) return 64;

    // WASM 分支渲染使用 SelectableText.rich，Flutter 会把
    // `DefaultTextStyle.of(context).style.merge(spanStyle)` 应用到最终样式上
    // （见 selectable_text.dart），于是 span 中为 null 的字形属性（如
    // letterSpacing）会继承气泡默认样式。测量时必须使用同一份已合并的样式，
    // 否则继承下来的 letterSpacing 会让实际渲染行宽大于测量值，最后一个字
    // 被挤到下一行。桌面分支用 QuillEditor，样式不走此合并路径，故保持原样。
    final baseStyle = _useWasmRenderer
        ? _wasmRenderStyle(context)
        : _wasmBaseStyle(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final spans = <InlineSpan>[];
    final placeholders = <PlaceholderDimensions>[];
    var hasVisibleContent = false;
    var hasBlockQuote = false;

    for (var index = 0; index < opsJson.length; index++) {
      final op = opsJson[index];
      if (op is! Map) continue;
      final insert = op['insert'];
      final attributes = op['attributes'];
      if (attributes is Map &&
          attributes.containsKey(Attribute.blockQuote.key)) {
        hasBlockQuote = true;
      }

      if (insert is String) {
        final displayText = _displayText(opsJson, index, insert);
        if (displayText.replaceAll('\n', '').isNotEmpty) {
          hasVisibleContent = true;
        }
        spans.add(
          TextSpan(
            text: displayText,
            style: _inlineStyle(context, baseStyle, attributes),
          ),
        );
        continue;
      }

      if (insert is! Map || !insert.containsKey('mention')) continue;
      hasVisibleContent = true;

      final mentionSize = _wasmMentionSize(
        context,
        insert['mention'],
        textScaler,
      );
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: SizedBox.fromSize(size: mentionSize),
        ),
      );
      placeholders.add(
        PlaceholderDimensions(
          // mentionSize 已含 margin，与实际渲染的 WidgetSpan 尺寸一致
          size: mentionSize,
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
      ..layout(maxWidth: double.infinity);

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

  /// WASM 安全的 Quill Delta 渲染器。
  ///
  /// Flutter Quill 当前的只读编辑器仍会进入依赖原生平台判断的路径，WASM 下不能
  /// 使用；直接调用 [Document.toPlainText] 又会显示 embed 的对象图标并丢掉样式。
  /// 这里逐个解释 Delta operation：保留常用行内样式，显式渲染 mention embed，
  /// 并把携带 `code-block` 属性的操作按块渲染为「背景 + 行号」的代码块。
  ///
  /// 使用 [SelectionArea] + [Text.rich] 而非 [SelectableText.rich]：
  /// `SelectableText` 内部的 `EditableText` 在 Web 上会为光标保留额外空间，
  /// 导致实际可用文本宽度比测量宽度窄，最后一个字被挤换行；同时其选区机制
  /// 会把行内 [WidgetSpan]（mention 胶囊）渲染为块级元素，@块后文字另起一行。
  /// `Text.rich` 直接映射到 `RichText`，`WidgetSpan` 始终内联，且渲染宽度
  /// 与 `TextPainter` 测量结果严格一致。
  Widget _buildWasmRichText(BuildContext context) {
    final opsJson = _rawDeltaOps;
    final baseStyle = _wasmRenderStyle(context);
    if (opsJson is! List) {
      return Text('', style: baseStyle);
    }

    final children = <Widget>[];
    final plainSpans = <InlineSpan>[];
    String pendingCodeText = '';

    void flushPlain({bool isBlockQuote = false}) {
      if (plainSpans.isEmpty) return;
      // TextSpan 不复制 children 列表，必须先拍快照再 clear，
      // 否则 clear() 会同时清空 TextSpan.children 导致渲染空白。
      final spans = List<InlineSpan>.of(plainSpans);
      plainSpans.clear();
      final richText = Text.rich(TextSpan(style: baseStyle, children: spans));
      children.add(
        isBlockQuote
            ? Container(
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      width: 4,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: richText,
              )
            : richText,
      );
    }

    void appendPlainText(
      String rawText,
      String displayText,
      TextStyle style, {
      required bool isBlockQuote,
    }) {
      final lines = displayText.split('\n');
      for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
        final line = lines[lineIndex];
        if (line.isNotEmpty) {
          plainSpans.add(TextSpan(text: line, style: style));
        }
        if (lineIndex < lines.length - 1) {
          flushPlain(isBlockQuote: isBlockQuote);
        }
      }

      // 最后一个 Delta op 的文档终止换行会被 _displayText 去掉，
      // 但它携带的 blockquote 是行级属性，仍必须用它结束并包装当前行。
      if (rawText.endsWith('\n') && !displayText.endsWith('\n')) {
        flushPlain(isBlockQuote: isBlockQuote);
      } else if (isBlockQuote && !rawText.contains('\n')) {
        // 兼容服务端传来的非标准 Delta：blockquote 直接挂在文本 op 上。
        flushPlain(isBlockQuote: true);
      }
    }

    void flushCodeBlock() {
      if (pendingCodeText.isEmpty) return;
      children.add(_buildWasmCodeBlock(context, pendingCodeText));
      pendingCodeText = '';
    }

    for (var index = 0; index < opsJson.length; index++) {
      final op = opsJson[index];
      if (op is! Map) continue;
      final insert = op['insert'];
      final attributes = op['attributes'];
      final isCodeBlock = attributes is Map &&
          attributes.containsKey(Attribute.codeBlock.key);
      final isBlockQuote = attributes is Map &&
          attributes.containsKey(Attribute.blockQuote.key);

      if (insert is String) {
        if (isCodeBlock) {
          flushPlain();
          // 多行代码块每行是独立 op，必须累加而非覆盖。
          pendingCodeText += _displayText(opsJson, index, insert);
        } else {
          flushCodeBlock();
          appendPlainText(
            insert,
            _displayText(opsJson, index, insert),
            _inlineStyle(context, baseStyle, attributes),
            isBlockQuote: isBlockQuote,
          );
        }
        continue;
      }

      if (insert is Map && insert.containsKey('mention')) {
        flushCodeBlock();
        plainSpans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _buildWasmMention(context, insert['mention']),
          ),
        );
      }
    }
    flushPlain();
    flushCodeBlock();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildWasmCodeBlock(
    BuildContext context,
    String code,
  ) {
    // 与编辑框一致的「行号 + 代码」渲染，见 CodeBlockView。
    return CodeBlockView(code: code);
  }

  TextStyle _wasmBaseStyle(BuildContext context) {
    return TextStyle(
      fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
      color: widget.textColor,
      fontSize: 14,
      height: 1.4,
    );
  }

  /// 与 SelectableText 内部合并逻辑一致的渲染样式。
  ///
  /// SelectableText.rich 在构建时会执行
  /// `DefaultTextStyle.of(context).style.merge(spanStyle)`，所以 span 中为 null
  /// 的属性会继承气泡默认样式（例如 M3 bodyMedium 的 letterSpacing 0.25）。
  /// 测量宽度时用同一个已合并的样式，可以保证「测出宽度 == 实际渲染宽度」，
  /// 避免气泡因为样式继承而比文字本身窄，最后一个字被挤换行。
  TextStyle _wasmRenderStyle(BuildContext context) {
    return DefaultTextStyle.of(context).style.merge(_wasmBaseStyle(context));
  }

  /// Quill 文档总会以一个终止换行结尾。编辑器把它作为文档边界而非空白行，
  /// 手动构造 TextSpan 时也必须去掉，否则消息气泡底部会多出一行高度。
  ///
  /// 同时去除最后一个 op 的行尾空格：`computeLineMetrics` 不会计入行尾空白，
  /// 但渲染时会保留，导致末尾多出不可见的换行。
  String _displayText(List<dynamic> ops, int index, String text) {
    if (index == ops.length - 1) {
      return text.trimRight();
    }
    return text;
  }

  TextStyle _wasmMentionStyle(BuildContext context) {
    return TextStyle(
      fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
      color: Colors.red,
      fontWeight: FontWeight.bold,
      fontSize: 14,
      height: 1,
    );
  }

  Size _wasmMentionSize(
    BuildContext context,
    dynamic rawData,
    TextScaler textScaler,
  ) {
    // mention 的 Text 位于 WidgetSpan 内，会继承气泡的 DefaultTextStyle
    // （例如 letterSpacing 0.25），实际渲染宽度大于裸样式。测量必须使用
    // 同一份合并样式，否则胶囊与气泡宽度都会小于真实文字宽度，导致
    // 最后一个字被挤换行/溢出（仅 WASM 手动渲染路径存在该问题）。
    final style = DefaultTextStyle.of(
      context,
    ).style.merge(_wasmMentionStyle(context));
    final painter = TextPainter(
      text: TextSpan(text: _mentionText(rawData), style: style),
      textDirection: ui.TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    );
    painter.layout();

    // 组件完整尺寸（含 margin：水平 2+2、垂直 0）：
    // 宽 = 文本宽 + 水平 padding(4+4) + 水平 margin(2+2)
    // 高 = 文本高 + 垂直 padding(2+2)
    //
    // 注意：SizedBox.fromSize 会给 Container 施加紧约束，margin 会从
    // 尺寸内部扣除，因此 margin 必须计入尺寸，否则内容区比文本窄 4px。
    return Size(painter.width + 12, painter.height + 4);
  }

  Widget _buildWasmMention(BuildContext context, dynamic rawData) {
    final size = _wasmMentionSize(
      context,
      rawData,
      MediaQuery.textScalerOf(context),
    );
    return SizedBox.fromSize(
      size: size,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _mentionText(rawData),
          maxLines: 1,
          softWrap: false,
          style: _wasmMentionStyle(context),
        ),
      ),
    );
  }

  TextStyle _inlineStyle(
    BuildContext context,
    TextStyle baseStyle,
    dynamic attributes,
  ) {
    if (attributes is! Map) return baseStyle;

    final link = attributes['link']?.toString();
    final isInlineCode = attributes['code'] == true;
    final foreground = _quillColor(attributes['color']);
    final background = _quillColor(attributes['background']);
    final decorations = <TextDecoration>[
      if (attributes['underline'] == true || link?.isNotEmpty == true)
        TextDecoration.underline,
      if (attributes['strike'] == true) TextDecoration.lineThrough,
    ];

    return baseStyle.copyWith(
      color:
          foreground ??
          (link?.isNotEmpty == true ? Colors.blueAccent : baseStyle.color),
      backgroundColor:
          background ??
          (isInlineCode
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : null),
      fontWeight: attributes['bold'] == true ? FontWeight.bold : null,
      fontStyle: attributes['italic'] == true ? FontStyle.italic : null,
      fontSize: _quillFontSize(attributes['size']),
      fontFamily: isInlineCode
          ? 'monospace'
          : _quillFontFamily(attributes['font']),
      decoration: decorations.isEmpty
          ? null
          : TextDecoration.combine(decorations),
    );
  }

  double? _quillFontSize(dynamic value) {
    if (value is num && value > 0) return value.toDouble();
    switch (value?.toString()) {
      case 'small':
        return 10;
      case 'large':
        return 18;
      case 'huge':
        return 32;
    }
    return double.tryParse(value?.toString() ?? '');
  }

  String? _quillFontFamily(dynamic value) {
    final font = value?.toString().trim();
    return font == null || font.isEmpty ? null : font;
  }

  Color? _quillColor(dynamic value) {
    if (value is int) return Color(value);
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return null;

    var hex = raw.startsWith('#') ? raw.substring(1) : raw;
    if (hex.length == 3) {
      hex = hex.split('').map((char) => '$char$char').join();
    }
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;

    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? null : Color(parsed);
  }

  String _mentionText(dynamic rawData) {
    final userName = MentionUser.displayName(rawData);
    if (userName != null && userName.isNotEmpty) return '@$userName';
    return '@--';
  }
}
