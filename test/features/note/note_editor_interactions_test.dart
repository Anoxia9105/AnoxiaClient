import 'package:anoxia/features/note/presentation/widgets/note_editor_interactions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('task checkbox keeps a fixed slot and uses click cursor', (
    tester,
  ) async {
    const builder = NoteTaskCheckboxBuilder();
    var changedTo = false;
    Widget checkbox(bool checked) => MaterialApp(
      home: Builder(
        builder: (context) => builder.build(
          context: context,
          isChecked: checked,
          onChanged: (value) => changedTo = value,
        ),
      ),
    );

    await tester.pumpWidget(checkbox(false));

    final slot = tester.widget<SizedBox>(
      find.byKey(const ValueKey('note_task_checkbox_slot')),
    );
    final uncheckedSize = tester.getSize(
      find.byKey(const ValueKey('note_task_checkbox_slot')),
    );
    final mouse = tester.widget<MouseRegion>(find.byType(MouseRegion).last);
    expect(slot.width, 26);
    expect(slot.height, 24);
    expect(mouse.cursor, SystemMouseCursors.click);

    final bounds = tester.getRect(
      find.byKey(const ValueKey('note_task_checkbox_slot')),
    );
    await tester.tapAt(Offset(bounds.right - 1, bounds.center.dy));
    expect(changedTo, isTrue);

    await tester.pumpWidget(checkbox(true));
    expect(
      tester.getSize(find.byKey(const ValueKey('note_task_checkbox_slot'))),
      uncheckedSize,
    );
  });

  testWidgets('link text always uses click cursor', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final document = Document.fromJson([
      {
        'insert': 'https://example.test',
        'attributes': {'link': 'https://example.test'},
      },
      {'insert': '\n'},
    ]);
    final line = document.root.children.first as Line;
    final node = line.children.first;

    final span =
        noteTextSpanBuilder(
              tester.element(find.byType(SizedBox)),
              node,
              0,
              'https://example.test',
              const TextStyle(),
              null,
            )
            as TextSpan;

    expect(span.mouseCursor, SystemMouseCursors.click);
  });
}
