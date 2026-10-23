import 'dart:convert';
import 'dart:io';

import 'package:anoxia/features/note/presentation/widgets/note_editor.dart';
import 'package:anoxia/framework/domain/note_doc.dart';
import 'package:anoxia/framework/provider/note/note_content_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('同篇笔记重新加载会重建编辑器，普通编辑不会', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final service = container.read(noteSessionServiceProvider.notifier);
    final doc = NoteDoc.fromJson(const {
      'id': 1,
      'title': '当前标题',
      'content': '[{"insert":"当前正文\\n"}]',
    });
    service.open(doc);
    Key? editorKey;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              // 只检查真实 NoteEditor 的子树身份，不启动剪贴板等平台插件。
              editorKey = const NoteEditor().build(context, ref).key;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    final firstKey = editorKey;
    service.updateTitle('输入中的标题');
    await tester.pump();
    expect(editorKey, firstKey);
    service.open(
      doc.copyWith(title: '历史标题', content: '[{"insert":"历史正文\\n"}]'),
    );
    await tester.pump();
    expect(editorKey, isNot(firstKey));
  });

  test('三种语言的还原确认文案使用 easy_localization 的顺序占位符', () {
    for (final locale in ['zh', 'en', 'ja']) {
      final messages =
          jsonDecode(File('assets/i18n/$locale.json').readAsStringSync())
              as Map<String, dynamic>;
      final template = messages['note_version_restore_confirm'] as String;
      expect(template, isNot(contains('{{')));
      expect('{}'.allMatches(template), hasLength(2));
    }
  });
}
