import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'quill_ime_binding_stub.dart'
    if (dart.library.js_interop) 'quill_ime_binding_web.dart';

/// Web 的系统输入法以 DOM 光标定位，需要与 Quill 的实际布局单独对齐。
class QuillWebImeAnchor extends StatefulWidget {
  const QuillWebImeAnchor({
    super.key,
    required this.editorKey,
    required this.controller,
    required this.focusNode,
    required this.child,
  });

  final GlobalKey<EditorState> editorKey;
  final QuillController controller;
  final FocusNode focusNode;
  final Widget child;

  @override
  State<QuillWebImeAnchor> createState() => _QuillWebImeAnchorState();
}

class _QuillWebImeAnchorState extends State<QuillWebImeAnchor> {
  late final _binding = QuillImeBinding(
    readCaret: _readCaret,
    readText: () => widget.controller.plainTextEditingValue.text,
    readViewSize: () {
      final view = View.of(context);
      return view.physicalSize / view.devicePixelRatio;
    },
  );

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
    _onFocusChanged();
  }

  Rect? _readCaret() {
    if (!mounted || !widget.focusNode.hasFocus) return null;
    final state = widget.editorKey.currentState;
    final selection = widget.controller.selection;
    if (state == null || !selection.isValid || state.dirty) return null;
    final render = state.renderEditor;
    if (!render.attached || !render.hasSize) {
      return null;
    }
    final offset = selection.extentOffset.clamp(
      0,
      widget.controller.document.length - 1,
    );
    final local = render.getLocalRectForCaret(TextPosition(offset: offset));
    return Rect.fromPoints(
      render.localToGlobal(local.topLeft),
      render.localToGlobal(local.bottomRight),
    );
  }

  void _onFocusChanged() {
    if (widget.focusNode.hasFocus) {
      _binding.start();
    } else {
      _binding.stop();
    }
  }

  @override
  void didUpdateWidget(covariant QuillWebImeAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode ||
        oldWidget.controller != widget.controller) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      _binding.stop();
      widget.focusNode.addListener(_onFocusChanged);
      _onFocusChanged();
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    _binding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
