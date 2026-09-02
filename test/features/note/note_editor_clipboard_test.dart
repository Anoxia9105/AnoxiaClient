// ignore_for_file: experimental_member_use

import 'package:anoxia/features/note/presentation/widgets/note_editor_clipboard.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('图片剪贴板优先处理且不触发富文本粘贴', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    Uint8List? pastedImage;
    var richPasteCalled = false;

    final result = await handleNoteEditorPaste(
      readImage: () async => bytes,
      pasteImage: (value) async => pastedImage = value,
      pasteRichText: () async {
        richPasteCalled = true;
        return true;
      },
    );

    expect(result, NotePasteResult.image);
    expect(pastedImage, bytes);
    expect(richPasteCalled, isFalse);
  });

  test('没有图片时交给 Quill 处理富文本 Delta', () async {
    var richPasteCalled = false;

    final result = await handleNoteEditorPaste(
      readImage: () async => null,
      pasteImage: (_) async {},
      pasteRichText: () async {
        richPasteCalled = true;
        return true;
      },
    );

    expect(result, NotePasteResult.richText);
    expect(richPasteCalled, isTrue);
  });

  test('平台图片剪贴板读取失败时仍回退 Quill 富文本粘贴', () async {
    final result = await handleNoteEditorPaste(
      readImage: () => Future<Uint8List?>.error(UnsupportedError('image')),
      pasteImage: (_) async {},
      pasteRichText: () async => true,
    );

    expect(result, NotePasteResult.richText);
  });

  testWidgets('同一 Quill 编辑器复制粘贴后保留加粗与颜色', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.getData') {
          return <String, dynamic>{'text': 'styled'};
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final controller = QuillController(
      document: Document.fromJson(const [
        {
          'insert': 'styled',
          'attributes': {'bold': true, 'color': '#ff0000'},
        },
        {'insert': '\n'},
      ]),
      selection: const TextSelection(baseOffset: 0, extentOffset: 6),
      config: const QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(enableExternalRichPaste: false),
      ),
    );
    addTearDown(controller.dispose);

    expect(controller.clipboardSelection(true), isTrue);
    controller.updateSelection(
      const TextSelection.collapsed(offset: 6),
      ChangeSource.local,
    );

    final result = await handleNoteEditorPaste(
      readImage: () async => null,
      pasteImage: (_) async {},
      pasteRichText: controller.clipboardPaste,
    );

    expect(result, NotePasteResult.richText);
    expect(controller.document.toDelta().toJson(), const [
      {
        'insert': 'styledstyled',
        'attributes': {'bold': true, 'color': '#ff0000'},
      },
      {'insert': '\n'},
    ]);
  });

  test('Web 剪贴板 HTML 会转换为保留加粗与颜色的 Delta', () {
    final controller = QuillController.basic();
    addTearDown(controller.dispose);

    final pasted = pasteNoteEditorHtml(
      controller,
      '<p><strong><span style="color: #ff0000">styled</span></strong></p>',
      plainTextFallback: 'styled',
    );

    expect(pasted, isTrue);
    final styledOperation = controller.document.toDelta().toList().firstWhere(
      (operation) => operation.data == 'styled',
    );
    expect(styledOperation.attributes?['bold'], isTrue);
    expect(styledOperation.attributes?['color'], '#ff0000');
  });

  testWidgets('Web 纯文本与内部复制内容一致时使用缓存 Delta', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final controller = QuillController(
      document: Document.fromJson(const [
        {
          'insert': 'styled',
          'attributes': {'bold': true, 'color': '#ff0000'},
        },
        {'insert': '\n'},
      ]),
      selection: const TextSelection(baseOffset: 0, extentOffset: 6),
    );
    addTearDown(controller.dispose);

    expect(controller.clipboardSelection(true), isTrue);
    controller.updateSelection(
      const TextSelection.collapsed(offset: 6),
      ChangeSource.local,
    );

    expect(pasteNoteEditorPlainText(controller, 'styled'), isTrue);
    expect(controller.document.toDelta().toJson(), const [
      {
        'insert': 'styledstyled',
        'attributes': {'bold': true, 'color': '#ff0000'},
      },
      {'insert': '\n'},
    ]);
  });
}
