// Web 手工输入法验收页；不连接账号、数据库或网络业务接口。
import 'dart:convert';
import 'dart:js_interop';

import 'package:anoxia/common/widgets/quill_web_ime_anchor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:web/web.dart' as web;

void main() => runApp(const MaterialApp(home: _Probe()));

class _Probe extends StatefulWidget {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  final _key = GlobalKey<EditorState>();
  final _focus = FocusNode();
  final _ordinaryFocus = FocusNode();
  final _scroll = ScrollController();
  final _controller = QuillController(
    document: Document.fromJson([
      {'insert': 'Heading'},
      {
        'insert': '\n',
        'attributes': {'header': 1},
      },
      {'insert': 'Body: 在这里测试中文输入法、选区替换和自动换行。\n'},
      {
        'insert':
            '${List.generate(30, (i) => 'Line $i: 测试中文候选窗位置').join('\n')}\n',
      },
    ]),
    selection: const TextSelection.collapsed(offset: 8),
  );
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    if (const bool.fromEnvironment('IME_PROBE_AUTORUN')) _runChecks();
  }

  Map<String, Object> _snapshot() {
    final active = web.document.activeElement;
    if (active == null || !active.isA<web.HTMLTextAreaElement>()) {
      throw StateError('Quill textarea is not focused');
    }
    final input = active as web.HTMLTextAreaElement;
    final render = _key.currentState!.renderEditor;
    final caret = render.getLocalRectForCaret(const TextPosition(offset: 8));
    final target = render.localToGlobal(caret.bottomLeft);
    final box = input.getBoundingClientRect();
    // Body 是纯文本第二行，但其富文本位置随标题高度改变。
    final dx = box.left - target.dx;
    final dy = box.top + 2 * caret.height - input.scrollTop - target.dy;
    if (dx.abs() > 1 || dy.abs() > 1) {
      throw StateError('Caret offset: dx=$dx, dy=$dy');
    }
    return {'dx': dx, 'dy': dy};
  }

  Future<void> _settle() =>
      Future<void>.delayed(const Duration(milliseconds: 500));

  Future<void> _runChecks() async {
    final results = <String, Object>{};
    try {
      await _settle();
      _focus.requestFocus();
      await _settle();
      results['heading'] = _snapshot();
      _controller.formatText(0, 7, Attribute.h2);
      await _settle();
      results['headingChanged'] = _snapshot();
      _scroll.jumpTo(80);
      await _settle();
      results['scrolled'] = _snapshot();
      final previous = web.document.activeElement as web.HTMLTextAreaElement;
      _ordinaryFocus.requestFocus();
      await _settle();
      final restored =
          previous.style.getPropertyValue('translate').isEmpty &&
          web.document.querySelector('[data-quill-ime-mirror]') == null;
      if (!restored) throw StateError('Quill input styles were not restored');
      results['ordinaryInputRestored'] = restored;
      _focus.requestFocus();
      await _settle();
      results['refocus'] = _snapshot();
      results['passed'] = true;
    } catch (error) {
      results['error'] = error.toString();
      results['passed'] = false;
    }
    web.document.body!.setAttribute(
      'data-quill-ime-probe-results',
      jsonEncode(results),
    );
    debugPrint('Quill IME probe: ${jsonEncode(results)}');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quill Web IME probe')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            onPressed: () => setState(() => _enabled = !_enabled),
            child: Text(_enabled ? 'Fix ON' : 'Fix OFF'),
          ),
          SizedBox(width: 700, height: 320, child: _editor()),
          const SizedBox(height: 30),
          SizedBox(
            width: 500,
            child: TextField(
              focusNode: _ordinaryFocus,
              decoration: const InputDecoration(labelText: 'Ordinary input'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _editor() {
    final editor = QuillEditor.basic(
      controller: _controller,
      focusNode: _focus,
      scrollController: _scroll,
      config: QuillEditorConfig(
        editorKey: _key,
        padding: const EdgeInsets.all(12),
      ),
    );
    return _enabled
        ? QuillWebImeAnchor(
            editorKey: _key,
            controller: _controller,
            focusNode: _focus,
            child: editor,
          )
        : editor;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _ordinaryFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }
}
