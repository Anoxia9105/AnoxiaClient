import 'dart:convert';

import 'package:anoxia/features/chat/presentation/widgets/message_bubble/message_selection_scope.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_menu/chat_message_context_menu.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/quill_message_strategy.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/text_message_strategy.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/quill_renderer_helpers.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/code/code_message_strategy.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_bubble/user_message_bubble.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_bubble/message_bubble_view_data.dart';
import 'package:anoxia/framework/provider/setting/chat_bubble_settings_provider.dart';
import 'package:anoxia/framework/protocol/message/code_payload.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/user_info.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/ai/ai_feature_flags_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'message_text_selection_test.dart' show dragText;

class _Auth extends AuthController {
  @override
  Future<UserInfo?> build() async => null;
}

class _NoTails extends ChatBubbleTailEnabled {
  @override
  bool build() => false;
}

class _Flags extends AiFeatureFlagsNotifier {
  @override
  Future<AiFeatureFlags> build() async => const AiFeatureFlags(
    chatEnabled: false,
    noteEnabled: false,
    available: false,
  );
}

class _Loader extends AssetLoader {
  const _Loader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'chat_select_text': 'Select text',
    'chat_copy': 'Copy message',
  };
}

ChatMessage _message(String text, {bool rich = true}) => ChatMessage(
  messageId: text,
  messageType: rich ? MessageType.richText : MessageType.text,
  content: text,
  payload: MessagePayload(
    content: text,
    quillDelta: jsonEncode([
      {'insert': '$text\n'},
    ]),
  ),
);

Future<void> _fixture(
  WidgetTester tester,
  TargetPlatform platform, {
  bool wasm = false,
  Key? roomKey,
  bool code = false,
  bool selfBubbles = false,
  Brightness brightness = Brightness.light,
  Color seedColor = Colors.deepPurple,
  String codeText = 'final value = 42;\n\n  print(value);',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_Auth.new),
        aiFeatureFlagsProvider.overrideWith(_Flags.new),
        chatBubbleTailEnabledProvider.overrideWith(_NoTails.new),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('en')],
        startLocale: const Locale('en'),
        path: 'unused',
        assetLoader: const _Loader(),
        child: Builder(
          builder: (context) => MaterialApp(
            theme: ThemeData(
              platform: platform,
              colorScheme: ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: brightness,
              ),
            ),
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: [
              ...context.localizationDelegates,
              FlutterQuillLocalizations.delegate,
            ],
            home: MessageSelectionScope(
              key: roomKey,
              child: Scaffold(
                body: Builder(
                  builder: (context) {
                    Widget bubble(ChatMessage message) {
                      final strategy =
                          message.messageType == MessageType.richText
                          ? QuillMessageStrategy(forceWasmRenderer: wasm)
                          : message.messageType == MessageType.codeSnippet
                          ? CodeMessageStrategy()
                          : TextMessageStrategy();
                      final scheme = Theme.of(context).colorScheme;
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: selfBubbles
                            ? MessageContentFrame(
                                message: message,
                                strategy: strategy,
                                view: MessageBubbleViewData(
                                  isCurrentUser: true,
                                  isMentionedMe: false,
                                  needsBubble: true,
                                  senderName: 'me',
                                  senderAvatar: null,
                                  senderMember: null,
                                  bubbleColor: scheme.primary,
                                  textColor: scheme.onPrimary,
                                  horizontalPadding: 0,
                                ),
                              )
                            : ChatMessageContextMenu(
                                message: message,
                                child: strategy.buildContent(
                                  context,
                                  message,
                                  Colors.black,
                                ),
                              ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bubble(_message('first message text')),
                        bubble(_message('second message text')),
                        bubble(
                          code
                              ? ChatMessage(
                                  messageId: 'code',
                                  messageType: MessageType.codeSnippet,
                                  payload: MessagePayload(
                                    code: CodePayload(code: codeText),
                                  ),
                                )
                              : _message('plain message text', rich: false),
                        ),
                        const SizedBox(
                          key: ValueKey('blank'),
                          width: 250,
                          height: 70,
                        ),
                        const TextField(key: ValueKey('input')),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

MessageSelectionHandle _handle(WidgetTester tester, int index) => tester
    .widgetList<MessageSelectionTarget>(find.byType(MessageSelectionTarget))
    .elementAt(index)
    .notifier!;

Future<void> _chooseSelection(WidgetTester tester, Finder body) async {
  await tester.longPressAt(tester.getCenter(body));
  await tester.pumpAndSettle();
  expect(find.text('Select text'), findsOneWidget);
  await tester.tap(find.text('Select text'));
  await tester.pumpAndSettle();
}

void main() {
  test('复制 Delta 选区保留换行、表情和 mention 名称', () {
    expect(
      quillCopyTextFromOps([
        {'insert': 'hello 🙂\n'},
        {
          'insert': {
            'mention': {'userId': 123, 'userName': '小明'},
          },
        },
        {'insert': ' 后文'},
      ]),
      'hello 🙂\n@小明 后文',
    );
  });
  String? clipboardText;
  setUp(() {
    clipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText = (call.arguments as Map)['text'] as String?;
          }
          if (call.method == 'Clipboard.getData') {
            return {'text': clipboardText};
          }
          if (call.method == 'Clipboard.hasStrings') {
            return {'value': clipboardText != null};
          }
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  for (final brightness in Brightness.values) {
    for (final seed in [Colors.deepPurple, Colors.blue, Colors.green]) {
      testWidgets('自己发送的 Quill 选区与气泡有可见对比 $brightness/$seed', (tester) async {
        await _fixture(
          tester,
          TargetPlatform.windows,
          selfBubbles: true,
          brightness: brightness,
          seedColor: seed,
        );
        await dragText(tester, find.byType(QuillEditor).first);
        final editor = tester.widget<QuillEditor>(
          find.byType(QuillEditor).first,
        );
        final scheme = Theme.of(
          tester.element(find.byType(QuillEditor).first),
        ).colorScheme;
        final selection = editor.config.textSelectionThemeData!.selectionColor!;
        final painted = Color.alphaBlend(selection, scheme.primary);
        final a = painted.computeLuminance();
        final b = scheme.primary.computeLuminance();
        final contrast = a > b
            ? (a + 0.05) / (b + 0.05)
            : (b + 0.05) / (a + 0.05);
        expect(contrast, greaterThan(1.3));
        expect(editor.controller.selection.isCollapsed, isFalse);
      });
    }
  }

  testWidgets('代码正文支持鼠标拖选并与 Quill 选区互斥', (tester) async {
    await _fixture(tester, TargetPlatform.windows, code: true);
    await dragText(tester, find.byType(QuillEditor).first);
    await dragText(tester, find.text('final value = 42;\n\n  print(value);'));
    expect(_handle(tester, 2).selectedText?.call(), isNotEmpty);
    expect(_handle(tester, 0).selectedText?.call(), isNull);
  });

  testWidgets('代码长按进入选择，全选复制保留缩进和空行', (tester) async {
    await _fixture(tester, TargetPlatform.android, code: true);
    await _chooseSelection(
      tester,
      find.text('final value = 42;\n\n  print(value);'),
    );
    expect(
      _handle(tester, 2).selectedText?.call(),
      'final value = 42;\n\n  print(value);',
    );
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(clipboardText, 'final value = 42;\n\n  print(value);');
  });

  testWidgets('窄屏长代码鼠标拖动选择，触摸未进入选择时仍能横向滚动', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final longCode =
        'final values = [${List.generate(80, (i) => i).join(', ')}];';
    await _fixture(
      tester,
      TargetPlatform.windows,
      code: true,
      codeText: longCode,
    );
    final code = find.text(longCode);
    final scrollView = find
        .ancestor(of: code, matching: find.byType(SingleChildScrollView))
        .first;
    final scrollable = find
        .descendant(of: scrollView, matching: find.byType(Scrollable))
        .first;
    final position = tester.state<ScrollableState>(scrollable).position;
    expect(position.maxScrollExtent, greaterThan(0));
    await dragText(tester, code);
    expect(_handle(tester, 2).selectedText?.call(), isNotEmpty);
    expect(position.pixels, 0);
    await _fixture(
      tester,
      TargetPlatform.android,
      code: true,
      codeText: longCode,
      roomKey: const ValueKey('touch code'),
    );
    final codeTop = tester.getTopLeft(find.text(longCode));
    await tester.dragFrom(Offset(260, codeTop.dy + 10), const Offset(-160, 0));
    await tester.pumpAndSettle();
    final touchScrollView = find
        .ancestor(
          of: find.text(longCode),
          matching: find.byType(SingleChildScrollView),
        )
        .first;
    final touchScrollable = find
        .descendant(of: touchScrollView, matching: find.byType(Scrollable))
        .first;
    expect(
      tester.state<ScrollableState>(touchScrollable).position.pixels,
      greaterThan(0),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('完整菜单外层下 Quill/普通文本选区互斥，空白和输入框退出', (tester) async {
    await _fixture(tester, TargetPlatform.windows);
    await dragText(tester, find.byType(QuillEditor).first);
    expect(_handle(tester, 0).selectedText?.call(), isNotEmpty);
    await dragText(tester, find.byType(QuillEditor).at(1));
    expect(_handle(tester, 0).selectedText?.call(), isNull);
    expect(_handle(tester, 1).selectedText?.call(), isNotEmpty);
    final firstState = tester.state<QuillEditorState>(
      find.byType(QuillEditor).first,
    );
    expect(
      firstState
          .editableTextKey
          .currentState!
          .renderEditor
          .selection
          .isCollapsed,
      isTrue,
    );
    await dragText(tester, find.text('plain message text'));
    expect(_handle(tester, 1).selectedText?.call(), isNull);
    expect(_handle(tester, 2).selectedText?.call(), isNotEmpty);
    await tester.tapAt(tester.getCenter(find.byKey(const ValueKey('blank'))));
    await tester.pumpAndSettle();
    expect(_handle(tester, 2).selectedText?.call(), isNull);
    await dragText(tester, find.byType(QuillEditor).first);
    await tester.tap(find.byKey(const ValueKey('input')));
    await tester.pumpAndSettle();
    expect(_handle(tester, 0).selectedText?.call(), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('桌面右键复制保留所选片段而不是整条消息', (tester) async {
    await _fixture(tester, TargetPlatform.windows);
    await dragText(tester, find.byType(QuillEditor).first);
    final selected = _handle(tester, 0).selectedText?.call();
    expect(selected, isNotEmpty);
    expect(selected, isNot('first message text'));
    final mouse = await tester.startGesture(
      tester.getCenter(find.byType(QuillEditor).first),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await mouse.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy message'));
    await tester.pumpAndSettle();
    expect(clipboardText, selected);
    expect(tester.takeException(), isNull);
  });

  testWidgets('桌面拖选后 Ctrl+C 复制片段，正文不可被键盘修改', (tester) async {
    await _fixture(tester, TargetPlatform.windows);
    await dragText(tester, find.byType(QuillEditor).first);
    final editor = tester.widget<QuillEditor>(find.byType(QuillEditor).first);
    expect(editor.focusNode.hasFocus, isTrue);
    final selected = _handle(tester, 0).selectedText?.call();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(clipboardText, selected);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(editor.controller.document.toPlainText(), 'first message text\n');
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('$platform 长按菜单进入 Quill 选择，显示手柄并复制', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await _fixture(tester, platform);
      await _chooseSelection(tester, find.byType(QuillEditor).first);
      final editor = tester.widget<QuillEditor>(find.byType(QuillEditor).first);
      expect(
        editor.controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 18),
      );
      expect(editor.focusNode.hasFocus, isTrue);
      final editorState = tester.state<QuillEditorState>(
        find.byType(QuillEditor).first,
      );
      expect(
        editorState
            .editableTextKey
            .currentState
            ?.selectionOverlay
            ?.handlesVisible,
        isTrue,
      );
      expect(_handle(tester, 0).selecting, isTrue);
      final handles = find.byWidgetPredicate(
        (widget) =>
            widget is GestureDetector &&
            widget.onPanStart != null &&
            widget.onPanUpdate != null,
      );
      expect(handles, findsNWidgets(2));
      await tester.drag(handles.last, const Offset(-55, 0));
      await tester.pumpAndSettle();
      expect(editor.controller.selection.isCollapsed, isFalse);
      expect(editor.controller.selection.end, lessThan(18));
      final selectedText = _handle(tester, 0).selectedText?.call();
      final copyButton = find.text(kIsWeb ? 'Copy message' : 'Copy');
      expect(copyButton, findsOneWidget);
      await tester.tap(copyButton);
      await tester.pumpAndSettle();
      expect(clipboardText, selectedText);
      expect(tester.testTextInput.isVisible, isFalse);
      await _chooseSelection(tester, find.byType(QuillEditor).at(1));
      expect(editor.controller.selection.isCollapsed, isTrue);
      await tester.tapAt(tester.getCenter(find.byKey(const ValueKey('blank'))));
      await tester.pumpAndSettle();
      expect(_handle(tester, 1).selecting, isFalse);
      expect(
        editorState
                .editableTextKey
                .currentState
                ?.selectionOverlay
                ?.handlesVisible ??
            false,
        isFalse,
      );
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('WASM 自绘与普通文本选择入口可全选并互相退出', (tester) async {
    await _fixture(tester, TargetPlatform.android, wasm: true);
    await _chooseSelection(tester, find.text('first message text'));
    expect(_handle(tester, 0).selectedText?.call(), 'first message text');
    await _chooseSelection(tester, find.text('plain message text'));
    expect(_handle(tester, 0).selectedText?.call(), isNull);
    expect(_handle(tester, 2).selectedText?.call(), 'plain message text');
    await _fixture(
      tester,
      TargetPlatform.android,
      wasm: true,
      roomKey: const ValueKey('another room'),
    );
    expect(_handle(tester, 2).selectedText?.call(), isNull);
    expect(tester.takeException(), isNull);
  });
}
