import 'package:anoxia/features/note/presentation/widgets/note_editor.dart';
import 'package:anoxia/framework/provider/note/note_content_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSessionService extends NoteSessionService {
  _FakeSessionService(this._session);
  final NoteEditSession _session;

  @override
  NoteEditSession? build() => _session;
}

const _session = NoteEditSession(
  noteId: 1,
  folderId: null,
  title: 'test',
  content: '[{"insert":"hello world\\n"}]',
  plainText: 'hello world\n',
  dirty: false,
  saveState: NoteSaveState.saved,
  lastSavedAt: null,
);

Future<QuillController> _pumpEditor(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      noteSessionServiceProvider.overrideWith(() => _FakeSessionService(_session)),
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

  final rawEditor = tester
      .widgetList(find.byType(QuillRawEditor))
      .firstOrNull;
  expect(rawEditor, isNotNull, reason: '应能找到 Quill 控制器');
  final controller = rawEditor is QuillRawEditor ? rawEditor.controller : null;
  expect(controller, isNotNull);
  final quill = controller!;

  // 模拟在行首输入 /（真实输入时 caret 会移到插入字符之后）
  quill.updateSelection(
    const TextSelection.collapsed(offset: 0),
    ChangeSource.local,
  );
  quill.replaceText(0, 0, '/', const TextSelection.collapsed(offset: 1));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  expect(find.text('toolbar_bold'), findsOneWidget, reason: '菜单应弹出');

  return quill;
}

void main() {
  // 桌面端：点击菜单项会让编辑器失焦（flutter_quill onTapOutside），
  // 修复前菜单在点击完成前被卸载，onTap 永远不触发。
  testWidgets('桌面端点击斜杠菜单项应正常执行命令（不失焦丢点击）', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      final controller = await _pumpEditor(tester);

      // 先聚焦编辑器，让“点击菜单项导致失焦”的路径真实发生；
      // 点击会移动光标，聚焦后把光标放回 "/" 之后，菜单随之恢复
      await tester.tap(find.byType(QuillRawEditor));
      await tester.pump();
      controller.updateSelection(
        const TextSelection.collapsed(offset: 1),
        ChangeSource.local,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('toolbar_bold'), findsOneWidget, reason: '聚焦后菜单应恢复');

      // 鼠标悬停到菜单项（MouseRegion.onEnter 置位防关标记）再点击
      final item = find.text('toolbar_bold');
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      final center = tester.getCenter(item);
      await gesture.moveTo(center);
      await tester.pump();
      await gesture.down(center);
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 50));

      // 点击后：/ 被清除，加粗生效
      expect(controller.document.toPlainText(), 'hello world\n',
          reason: '输入 / 应被清除');
      expect(
        controller
            .getSelectionStyle()
            .attributes
            .containsKey(Attribute.bold.key),
        isTrue,
        reason: '点击加粗后 typing 属性应生效',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('键盘 ↑/↓ 切换选中项，回车执行，ESC 关闭', (tester) async {
    final controller = await _pumpEditor(tester);

    // ↓ 切到斜体（第 2 项）
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump(const Duration(milliseconds: 100));
    // 菜单应保持打开且不闪烁（高亮移动而非重建）
    expect(find.text('toolbar_bold'), findsOneWidget, reason: '菜单应保持打开');

    // 回车执行斜体
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.document.toPlainText(), 'hello world\n',
        reason: '输入 / 应被清除');
    expect(
      controller
          .getSelectionStyle()
          .attributes
          .containsKey(Attribute.italic.key),
      isTrue,
      reason: '回车应执行当前选中的斜体命令',
    );
    expect(
      controller.getSelectionStyle().attributes.containsKey(Attribute.bold.key),
      isFalse,
      reason: '不应误执行加粗',
    );

    // ESC 关闭菜单
    controller.replaceText(0, 0, '/', const TextSelection.collapsed(offset: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('toolbar_bold'), findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('toolbar_bold'), findsNothing, reason: 'ESC 应关闭菜单');
  });
}
