import 'package:flutter/material.dart';

import '../message_bubble/message_selection_scope.dart';

/// 普通文字、代码与 WASM 自绘 Delta 共用 Flutter 原生选择机制。
class SelectableMessageBody extends StatefulWidget {
  const SelectableMessageBody({super.key, required this.child});
  final Widget child;

  @override
  State<SelectableMessageBody> createState() => _SelectableMessageBodyState();
}

class _SelectableMessageBodyState extends State<SelectableMessageBody> {
  final _key = GlobalKey<SelectionAreaState>();
  final _focusNode = FocusNode();
  MessageSelectionHandle? _handle;
  MessageSelectionScopeState? _scope;
  String? _selectedText;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _handle?.activate(_scope);
    } else {
      _handle?.clear();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final handle = MessageSelectionTarget.maybeOf(context);
    if (handle != _handle) {
      _unbind();
      _handle = handle;
      handle?.selectAll = _selectAll;
      handle?.clearSelection = _clear;
      handle?.selectedText = _getSelectedText;
    }
    _scope = MessageSelectionScope.maybeOf(context);
  }

  void _unbind() {
    if (_handle?.selectAll == _selectAll) _handle?.selectAll = null;
    if (_handle?.clearSelection == _clear) _handle?.clearSelection = null;
    if (_handle?.selectedText == _getSelectedText) _handle?.selectedText = null;
  }

  String? _getSelectedText() => _selectedText;

  void _selectAll() {
    _handle?.activate(_scope);
    _focusNode.requestFocus();
    _key.currentState?.selectableRegion.selectAll(
      SelectionChangedCause.toolbar,
    );
  }

  void _clear() {
    _key.currentState?.selectableRegion.clearSelection();
    _key.currentState?.selectableRegion.hideToolbar();
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _unbind();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final touchPlatform =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    // 未进入选择状态时，让手机长按由外层消息菜单处理。
    return IgnorePointer(
      ignoring: touchPlatform && _handle != null && !_handle!.selecting,
      child: SelectionArea(
        key: _key,
        focusNode: _focusNode,
        onSelectionChanged: (selection) => _selectedText = selection?.plainText,
        contextMenuBuilder: (context, region) {
          if (_handle != null && !_handle!.selecting) {
            return const SizedBox.shrink();
          }
          return AdaptiveTextSelectionToolbar.selectableRegion(
            selectableRegionState: region,
          );
        },
        child: widget.child,
      ),
    );
  }
}
