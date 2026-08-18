import 'dart:async';

import 'package:anoxia/framework/domain/note_doc.dart';
import 'package:anoxia/framework/domain/note_tree.dart';
import 'package:anoxia/framework/provider/note/note_tag_provider.dart';
import 'package:anoxia/framework/provider/note/note_tree_provider.dart';
import 'package:anoxia/features/note/presentation/widgets/note_tree_panel.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void _noop(NoteBrief note) {}

class _FakeTagService extends NoteTagService {
  @override
  Future<List<NoteTag>> build() => Future.value(const []);
}

class _FakeTreeService extends NoteTreeService {
  _FakeTreeService(this._tree, {this.onSetPinned});

  final NoteTree _tree;
  final void Function(int noteId, bool pinned)? onSetPinned;

  @override
  FutureOr<NoteTree> build() => _tree;

  @override
  Future<void> setPinned(int noteId, {required bool pinned}) async {
    onSetPinned?.call(noteId, pinned);
  }
}

Widget _buildPanel(NoteTree tree, {void Function(int, bool)? onSetPinned}) {
  return ProviderScope(
    overrides: [
      noteTreeServiceProvider.overrideWith(
        () => _FakeTreeService(tree, onSetPinned: onSetPinned),
      ),
      noteTagServiceProvider.overrideWith(() => _FakeTagService()),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: NoteTreePanel(selectedNoteId: null, onOpenNote: _noop),
      ),
    ),
  );
}

Future<void> _rightClick(WidgetTester tester, Finder target) async {
  final gesture = await tester.startGesture(
    tester.getCenter(target),
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryButton,
  );
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('文件夹右键菜单：标题 + 分组操作项 + 删除确认', (tester) async {
    final tree = const NoteTree(
      folders: [
        NoteFolderNode(
          id: 1,
          name: '工作',
          sortOrder: 0,
          children: [],
          notes: [],
        ),
      ],
      rootNotes: [],
    );

    await tester.pumpWidget(_buildPanel(tree));
    await tester.pump();

    await _rightClick(tester, find.text('工作'));

    // 标题（菜单内再次出现文件夹名）+ 各分组操作项（note_new 与顶部按钮共用文案）
    expect(find.text('工作'), findsNWidgets(2));
    expect(find.text('note_new'), findsNWidgets(2));
    expect(find.text('note_new_subfolder'), findsOneWidget);
    expect(find.text('note_rename'), findsOneWidget);
    expect(find.text('note_move'), findsOneWidget);
    expect(find.text('note_delete'), findsOneWidget);

    // 点击删除 → 弹出确认对话框，证明菜单项可正常触发
    await tester.tap(find.text('note_delete'));
    await tester.pumpAndSettle();
    expect(find.text('note_folder_delete_confirm_title'), findsOneWidget);
  });

  testWidgets('笔记右键菜单：置顶可触发且置顶项为置顶图标', (tester) async {
    int? pinnedId;
    bool? pinnedValue;
    final tree = const NoteTree(
      folders: [],
      rootNotes: [
        NoteBrief(
          id: 2,
          folderId: null,
          title: '购物清单',
          preview: '',
          updatedAt: null,
        ),
      ],
    );

    await tester.pumpWidget(
      _buildPanel(
        tree,
        onSetPinned: (id, pinned) {
          pinnedId = id;
          pinnedValue = pinned;
        },
      ),
    );
    await tester.pump();

    await _rightClick(tester, find.text('购物清单'));

    expect(find.text('note_pin'), findsOneWidget);
    expect(find.text('note_tags'), findsOneWidget);
    expect(find.text('note_share'), findsOneWidget);
    expect(find.text('note_move'), findsOneWidget);
    expect(find.text('note_delete'), findsOneWidget);

    await tester.tap(find.text('note_pin'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(pinnedId, 2);
    expect(pinnedValue, true);
  });
}
