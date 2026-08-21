import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:anoxia/features/note/presentation/widgets/note_editor_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('NoteEditorSkeleton 渲染标题/工具栏/正文/状态条占位', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: NoteEditorSkeleton())),
    );
    // 骨架块应存在多处（标题、工具栏按钮、正文行、状态条）
    expect(find.byType(SkeletonBox), findsWidgets);
    // 不应抛出布局异常
    expect(tester.takeException(), isNull);
  });
}
