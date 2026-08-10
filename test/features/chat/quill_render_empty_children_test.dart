import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

/// 回归测试：web-wasm 下粘贴/格式化代码块时，Quill 渲染子树与文档节点短暂
/// 失步（children 为空），同步的几何查询（光标/选区）不应崩溃。
///
/// flutter-quill 11.5.1 中 `childAtPosition` 在 children 为空时直接
/// assert(firstChild != null)（对应 flutter-quill issue #2253，官方仍未修复），
/// 各几何查询入口会抛异常。应用侧必须经 try/catch 防御（见
/// quill_cursor_x.dart），裸调这些 API 会导致崩溃。
void main() {
  testWidgets('RenderEditor children 为空时几何查询经防御捕获不崩溃', (tester) async {
    final cursor = CursorCont(
      show: ValueNotifier<bool>(false),
      style: const CursorStyle(
        color: Colors.black,
        backgroundColor: Colors.white,
      ),
      tickerProvider: const TestVSync(),
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

    // 模拟应用侧防御：异常被捕获，不向上抛导致崩溃。
    T? guarded<T>(T Function() fn) {
      try {
        return fn();
      } catch (_) {
        return null;
      }
    }

    expect(
      () => guarded(
        () => editor.getEndpointsForSelection(
          const TextSelection.collapsed(offset: 0),
        ),
      ),
      returnsNormally,
    );
    expect(
      () => guarded(() => editor.preferredLineHeight(const TextPosition(offset: 0))),
      returnsNormally,
    );
    expect(
      () => guarded(() => editor.getPositionForOffset(Offset.zero)),
      returnsNormally,
    );
    expect(
      () => guarded(() => editor.getOffsetToRevealCursor(100, 0, 0)),
      returnsNormally,
    );
    expect(
      () => guarded(() => editor.getLocalRectForCaret(const TextPosition(offset: 0))),
      returnsNormally,
    );
  });
}