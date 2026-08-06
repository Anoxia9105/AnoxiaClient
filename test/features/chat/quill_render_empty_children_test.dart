import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

/// 回归测试：web-wasm 下粘贴/格式化代码块时，Quill 渲染子树与文档节点短暂
/// 失步（children 为空），同步的几何查询（光标/选区）不应崩溃。
///
/// 修复前 RenderEditor.childAtPosition 在 children 为空时直接
/// throw 'targetChild should not be null'（对应 flutter-quill issue #2253）。
/// 修复方式：所有几何查询入口在 children 为空时返回安全默认值。
void main() {
  testWidgets('RenderEditor children 为空时几何查询返回安全默认值', (tester) async {
    final cursor = CursorCont(
      show: ValueNotifier<bool>(false),
      style: CursorStyle(
        color: Colors.black,
        backgroundColor: Colors.white,
      ),
      tickerProvider: TestVSync(),
    );
    addTearDown(cursor.dispose);

    final editor = RenderEditor(
      document: Document()..insert(0, 'hello'),
      textDirection: TextDirection.ltr,
      hasFocus: false,
      selection: const TextSelection.collapsed(offset: 0),
      scrollable: false,
      startHandleLayerLink: LayerLink(),
      endHandleLayerLink: LayerLink(),
      padding: EdgeInsets.zero,
      cursorController: cursor,
      onSelectionChanged: (selection, cause) {},
      onSelectionCompleted: () {},
      scrollBottomInset: 0,
      floatingCursorDisabled: false,
      children: null,
    );
    addTearDown(editor.dispose);

    expect(
      editor.getEndpointsForSelection(
        const TextSelection.collapsed(offset: 0),
      ),
      isEmpty,
    );
    expect(editor.preferredLineHeight(const TextPosition(offset: 0)), 0.0);
    expect(
      editor.getPositionForOffset(Offset.zero),
      const TextPosition(offset: 0),
    );
    expect(editor.getOffsetToRevealCursor(100, 0, 0), isNull);
    expect(
      editor.getLocalRectForCaret(const TextPosition(offset: 0)),
      Rect.zero,
    );
  });
}
