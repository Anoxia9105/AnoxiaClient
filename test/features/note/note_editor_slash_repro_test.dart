import 'package:anoxia/features/note/presentation/widgets/note_editor.dart';
import 'package:anoxia/framework/provider/note/note_content_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSessionService extends NoteSessionService {
  _FakeSessionService(this._session);
  final NoteEditSession _session;

  @override
  NoteEditSession? build() => _session;
}

void main() {
  testWidgets('输入 / 不应清空内容、不应崩溃', (tester) async {
    const content = '[{"insert":"hello world\\n"}]';
    const session = NoteEditSession(
      noteId: 1,
      folderId: null,
      title: 'test',
      content: content,
      plainText: 'hello world\n',
      dirty: false,
      saveState: NoteSaveState.saved,
      lastSavedAt: null,
    );

    final container = ProviderContainer(
      overrides: [
        noteSessionServiceProvider.overrideWith(
          () => _FakeSessionService(session),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: NoteEditor())),
      ),
    );
    await tester.pump();

    QuillController? controller;
    final rawEditor = tester
        .widgetList(find.byType(QuillRawEditor))
        .firstOrNull;
    if (rawEditor is QuillRawEditor) {
      controller = rawEditor.controller;
    }
    expect(controller, isNotNull, reason: '应能找到 Quill 控制器');

    // 光标移到行首，模拟输入 /（真实输入时 caret 会移到插入字符之后）
    controller!.updateSelection(
      const TextSelection.collapsed(offset: 0),
      ChangeSource.local,
    );
    controller.replaceText(0, 0, '/', const TextSelection.collapsed(offset: 1));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final textAfter = controller.document.toPlainText();
    debugPrint('slash input -> plainText: "$textAfter"');
    expect(textAfter, contains('hello world'), reason: '输入 / 后内容不应消失');
    expect(textAfter, contains('/'), reason: '/ 应保留在文档中');

    // 菜单应已弹出（测试内 .tr() 回退为 key，菜单项标签即 key）
    expect(
      find.text('toolbar_bold'),
      findsOneWidget,
      reason: '输入 / 后应弹出斜杠命令菜单',
    );

    // 继续输入查询字符
    controller.replaceText(1, 0, 'b', const TextSelection.collapsed(offset: 2));
    await tester.pump();
    final textAfterQuery = controller.document.toPlainText();
    debugPrint('query input -> plainText: "$textAfterQuery"');
    expect(textAfterQuery, contains('hello world'));
    expect(find.text('toolbar_bold'), findsOneWidget, reason: '输入查询字符后菜单应保持打开');
  });

  testWidgets('连续输入 / + 查询字符（未泵帧）也能正确弹出菜单', (tester) async {
    const session = NoteEditSession(
      noteId: 1,
      folderId: null,
      title: 'test',
      content: '[{"insert":"hello world\\n"}]',
      plainText: 'hello world\n',
      dirty: false,
      saveState: NoteSaveState.saved,
      lastSavedAt: null,
    );

    final container = ProviderContainer(
      overrides: [
        noteSessionServiceProvider.overrideWith(
          () => _FakeSessionService(session),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: NoteEditor())),
      ),
    );
    await tester.pump();

    QuillController? controller;
    final rawEditor = tester
        .widgetList(find.byType(QuillRawEditor))
        .firstOrNull;
    if (rawEditor is QuillRawEditor) {
      controller = rawEditor.controller;
    }
    expect(controller, isNotNull);

    // 同一帧内连续输入 / 与查询字符，验证延迟插入菜单的路径
    controller!.updateSelection(
      const TextSelection.collapsed(offset: 0),
      ChangeSource.local,
    );
    controller.replaceText(0, 0, '/', const TextSelection.collapsed(offset: 1));
    controller.replaceText(1, 0, 'b', const TextSelection.collapsed(offset: 2));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(controller.document.toPlainText(), contains('hello world'));
    expect(controller.document.toPlainText(), contains('/b'));
    expect(find.text('toolbar_bold'), findsOneWidget, reason: '延迟插入后菜单应弹出');
  });
}
