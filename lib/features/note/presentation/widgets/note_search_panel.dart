import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 记事本「在文档中查找」侧边面板
///
/// 以竖向卡片展示在编辑器右侧（无遮罩），支持：
/// - 即时搜索（300ms 防抖）
/// - 上一个 / 下一个导航
/// - 区分大小写 / 全字匹配开关
/// - 匹配计数显示
class NoteSearchPanel extends StatefulWidget {
  final QuillController controller;
  final FocusNode editorFocusNode;
  final VoidCallback onClose;

  const NoteSearchPanel({
    super.key,
    required this.controller,
    required this.editorFocusNode,
    required this.onClose,
  });

  @override
  State<NoteSearchPanel> createState() => _NoteSearchPanelState();
}

class _NoteSearchPanelState extends State<NoteSearchPanel> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  Timer? _debounce;

  String _query = '';
  List<int> _offsets = [];
  int _index = 0;
  bool _caseSensitive = false;
  bool _wholeWord = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _inputFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _query = text;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _findText);
  }

  void _findText() {
    final controller = widget.controller;
    if (!mounted) return;
    if (_query.isEmpty) {
      setState(() {
        _offsets = [];
        _index = 0;
      });
      _clearSelection(controller);
      return;
    }
    setState(() {
      _offsets = controller.document.search(
        _query,
        caseSensitive: _caseSensitive,
        wholeWord: _wholeWord,
      );
      _index = 0;
      if (_offsets.isNotEmpty) _moveTo(controller, 0);
    });
  }

  void _movePrevious() {
    if (_offsets.isEmpty) return;
    final next = _index > 0 ? _index - 1 : _offsets.length - 1;
    setState(() => _index = next);
    _moveTo(widget.controller, _index);
  }

  void _moveNext() {
    if (_offsets.isEmpty) return;
    final next = _index < _offsets.length - 1 ? _index + 1 : 0;
    setState(() => _index = next);
    _moveTo(widget.controller, _index);
  }

  void _moveTo(QuillController controller, int index) {
    final offset = _offsets[index];
    var len = _query.length;
    final leaf = controller.queryNode(offset);
    if (leaf is Embed) len = 1;
    controller.updateSelection(
      TextSelection(baseOffset: offset, extentOffset: offset + len),
      ChangeSource.local,
    );
  }

  void _clearSelection(QuillController controller) {
    final base = controller.selection.baseOffset;
    controller.updateSelection(
      TextSelection.collapsed(offset: base),
      ChangeSource.local,
    );
  }

  String get _matchLabel {
    if (_query.isEmpty) return '';
    if (_offsets.isEmpty) return 'note_find_no_match'.tr();
    return '${_index + 1}/${_offsets.length}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: .4),
        border: Border(
          left: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: .5),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch02,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'note_find_title'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'close'.tr(),
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onClose,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _inputController,
              focusNode: _inputFocusNode,
              onChanged: _onChanged,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'note_find_placeholder'.tr(),
                hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: .6),
                ),
                prefixIcon: SizedBox(
                  width: 32,
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch02,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                suffixText: _matchLabel,
                suffixStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: _offsets.isEmpty && _query.isNotEmpty
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                ),
                prefixIconConstraints:
                    const BoxConstraints.tightFor(width: 32, height: 32),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RadiusToken.md),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RadiusToken.md),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: .6),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RadiusToken.md),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _navButton(
                  tooltip: 'note_find_prev'.tr(),
                  icon: HugeIcons.strokeRoundedArrowUp01,
                  enabled: _offsets.isNotEmpty,
                  onTap: _movePrevious,
                ),
                const SizedBox(width: 6),
                _navButton(
                  tooltip: 'note_find_next'.tr(),
                  icon: HugeIcons.strokeRoundedArrowDown01,
                  enabled: _offsets.isNotEmpty,
                  onTap: _moveNext,
                ),
              ],
            ),
            const SizedBox(height: 4),
            _toggleRow(
              label: 'note_find_case_sensitive'.tr(),
              value: _caseSensitive,
              onChanged: (v) {
                setState(() => _caseSensitive = v);
                _findText();
              },
            ),
            _toggleRow(
              label: 'note_find_whole_word'.tr(),
              value: _wholeWord,
              onChanged: (v) {
                setState(() => _wholeWord = v);
                _findText();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _navButton({
    required String tooltip,
    required List<List<dynamic>> icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(RadiusToken.md),
        onTap: enabled ? onTap : null,
        child: Container(
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled
                ? colorScheme.surfaceContainerHighest.withValues(alpha: .6)
                : colorScheme.surfaceContainerHighest.withValues(alpha: .2),
            borderRadius: BorderRadius.circular(RadiusToken.md),
          ),
          child: HugeIcon(
            icon: icon,
            size: 14,
            color: enabled
                ? colorScheme.onSurfaceVariant
                : colorScheme.onSurfaceVariant.withValues(alpha: .3),
          ),
        ),
      ),
    );
  }

  Widget _toggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(RadiusToken.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 15,
              height: 15,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: value ? colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(RadiusToken.sm),
                border: Border.all(
                  color: value
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: 1.2,
                ),
              ),
              child: value
                  ? Icon(
                      Icons.check,
                      size: 11,
                      color: colorScheme.onPrimary,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: value
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}