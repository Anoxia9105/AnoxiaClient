import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/ai/chat_ai_assist_core.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/chat_ai_assist_popup.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/mobile/mobile_chat_ai_panel.dart';
import 'package:anoxia/framework/domain/user_info.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/chat/input/reply_target_provider.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/ai/smart_reply_bar.dart';
import 'package:anoxia/framework/network/sse_client.dart';
import 'package:anoxia/framework/provider/ai/ai_feature_flags_provider.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/input/mobile_text_input_controller.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Loader extends AssetLoader {
  const _Loader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) => Future.value(
    jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
        as Map<String, dynamic>,
  );
}

class _Auth extends AuthController {
  @override
  Future<UserInfo?> build() async => null;
  void switchUser(int id) =>
      state = AsyncData(UserInfo.fromJson({'userId': id}));
}

class _Flags extends AiFeatureFlagsNotifier {
  @override
  Future<AiFeatureFlags> build() async => const AiFeatureFlags(
    chatEnabled: true,
    noteEnabled: true,
    available: true,
  );
}

void main() {
  testWidgets('智能回复草稿及引用变化后失效，选中完整回复而不重复拼接', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final draft = TextEditingController(text: '周六不方便');
    final requests = <Map>[];
    var previousAccount = true;
    final oldHistory = Completer<List<ChatMessage>>();
    var historyReads = 0;
    final core = ChatAiAssistCore(
      transport: (path, {body}) {
        expect(path, '/chat/ai/replies/stream');
        requests.add(body as Map);
        return Stream.fromIterable([
          SseFrame(
            event: 'done',
            data: jsonEncode({
              'text': jsonEncode(['周日可以吗？', '我们改天再约吧。', '这周六不行，下周方便吗？']),
            }),
          ),
        ]);
      },
    );
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_Auth.new),
        aiFeatureFlagsProvider.overrideWith(_Flags.new),
        roomMessagesProvider('room').overrideWith(
          (ref) => Stream.value([
            ChatMessage(
              roomId: 'room',
              senderId: 2,
              messageType: MessageType.text,
              content: '周六见吗？',
            ),
          ]),
        ),
      ],
    );
    addTearDown(() {
      container.dispose();
      draft.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: EasyLocalization(
          supportedLocales: const [Locale('zh')],
          path: 'assets/i18n',
          startLocale: const Locale('zh'),
          assetLoader: const _Loader(),
          child: Builder(
            builder: (context) => MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: Scaffold(
                body: SmartReplyBar(
                  historyReader: ({required limit, beforeSeq}) {
                    historyReads++;
                    if (historyReads == 1) return oldHistory.future;
                    return Future.value(
                      previousAccount && historyReads > 2
                          ? [
                              ChatMessage(
                                roomId: 'room',
                                messageId: 'private',
                                senderId: 9,
                                messageType: MessageType.text,
                                content: 'previous-account-only',
                              ),
                            ]
                          : <ChatMessage>[],
                    );
                  },
                  roomId: 'room',
                  core: core,
                  draftListenable: draft,
                  readDraft: () => draft.text,
                  onPick: (text) => draft.text = text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('智能回复'));
    await tester.pump();
    draft.text = '临时修改';
    draft.text = '周六不方便';
    await tester.pump();
    await tester.tap(find.text('智能回复'));
    await tester.pumpAndSettle();
    oldHistory.complete([
      ChatMessage(
        roomId: 'room',
        messageId: 'stale',
        messageType: MessageType.text,
        content: 'stale-request-only',
      ),
    ]);
    await tester.pumpAndSettle();
    expect(requests.single['draft'], '周六不方便');
    expect(
      requests.single['conversation'],
      isNot(contains('stale-request-only')),
    );
    expect(find.text('周日可以吗？'), findsOneWidget);
    draft.text = '周六有空';
    await tester.pump();
    expect(find.text('周日可以吗？'), findsNothing);
    await tester.tap(find.text('智能回复'));
    await tester.pumpAndSettle();
    expect(requests.last['draft'], '周六有空');
    container
        .read(replyTargetControllerProvider.notifier)
        .set(
          'room',
          ChatMessage(
            roomId: 'room',
            senderId: 3,
            messageType: MessageType.text,
            content: '改周日呢？',
          ),
        );
    await tester.pump();
    expect(find.text('周日可以吗？'), findsNothing);
    await tester.tap(find.text('智能回复'));
    await tester.pumpAndSettle();
    expect(requests, hasLength(3));
    expect(requests.last['quotedMessage'], contains('改周日呢'));
    expect(requests.last['conversation'], contains('previous-account-only'));
    await tester.tap(find.byTooltip('关闭'));
    await tester.pump();
    previousAccount = false;
    (container.read(authControllerProvider.notifier) as _Auth).switchUser(2);
    await tester.pump();
    await tester.tap(find.text('智能回复'));
    await tester.pumpAndSettle();
    expect(requests, hasLength(4));
    expect(
      requests.last['conversation'],
      isNot(contains('previous-account-only')),
    );
    await tester.tap(find.text('周日可以吗？'));
    await tester.pump();
    expect(draft.text, '周日可以吗？');
    await tester.pumpWidget(const SizedBox());
  });

  for (final desktop in [false, true]) {
    testWidgets('${desktop ? "桌面" : "移动"}草稿变化时拒绝覆盖，重新生成后可以应用且没有撤销按钮', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      final mobile = MobileTextInputController()
        ..replaceAllText('原草稿', cursorOffset: 3);
      final quill = QuillController.basic()..document.insert(0, '原草稿');
      final focus = FocusNode();
      var closed = false;
      final requests = <Map>[];
      final core = ChatAiAssistCore(
        transport: (_, {body}) {
          requests.add(body as Map);
          return Stream.fromIterable([
            SseFrame(event: 'done', data: '{"text":"改写结果"}'),
          ]);
        },
      );
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(_Auth.new),
          aiFeatureFlagsProvider.overrideWith(_Flags.new),
          roomMessagesProvider('room').overrideWith((ref) => Stream.value([])),
        ],
      );
      addTearDown(() {
        container.dispose();
        mobile.dispose();
        quill.dispose();
        focus.dispose();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: EasyLocalization(
            supportedLocales: const [Locale('zh')],
            path: 'assets/i18n',
            startLocale: const Locale('zh'),
            assetLoader: const _Loader(),
            child: Builder(
              builder: (context) => MaterialApp(
                scaffoldMessengerKey: Toast.messengerKey,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                home: Scaffold(
                  body: SizedBox(
                    width: 420,
                    height: 580,
                    child: desktop
                        ? ChatAiAssistCard(
                            controller: quill,
                            editorFocusNode: focus,
                            roomId: 'room',
                            core: core,
                            onClose: () => closed = true,
                          )
                        : MobileChatAiPanel(
                            inputController: mobile,
                            roomId: 'room',
                            core: core,
                            onClose: () => closed = true,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('润色'));
      await tester.pumpAndSettle();
      if (desktop) {
        // 仅改变格式也必须阻止旧结果覆盖。
        quill.formatText(0, 3, Attribute.bold);
      } else {
        mobile.replaceAllText('用户新草稿', cursorOffset: 5);
      }
      await tester.pump();
      await tester.tap(find.text('替换全部'));
      await tester.pump();
      expect(closed, isFalse);
      expect(
        desktop ? quill.document.toPlainText().trim() : mobile.text,
        desktop ? '原草稿' : '用户新草稿',
      );
      expect(find.text('草稿已变化，未应用 AI 结果。请重新生成或复制结果。'), findsOneWidget);
      Toast.messengerKey.currentState!.hideCurrentSnackBar();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('换一版'));
      await tester.pumpAndSettle();
      expect(requests, hasLength(2));
      expect(
        (jsonDecode(requests.last['content'] as String) as Map)['target'],
        desktop ? '原草稿' : '用户新草稿',
      );
      await tester.tap(find.text('替换全部'));
      await tester.pump();
      expect(
        desktop ? quill.document.toPlainText().trim() : mobile.text,
        '改写结果',
      );
      expect(closed, isTrue);
      expect(find.byType(SnackBarAction), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
