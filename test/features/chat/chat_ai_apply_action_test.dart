import 'dart:convert';
import 'dart:io';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/ai/chat_ai_assist_core.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/chat_ai_assist_popup.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/mobile/mobile_chat_ai_panel.dart';
import 'package:anoxia/framework/domain/user_info.dart';
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
  for (final desktop in [false, true]) {
    for (final selected in [false, true]) {
      for (final continuation in [false, true]) {
        testWidgets('$desktop/$selected/$continuation 按动作应用而不是按当前光标位置插入', (
          tester,
        ) async {
          SharedPreferences.setMockInitialValues({});
          await EasyLocalization.ensureInitialized();
          final mobile = MobileTextInputController()
            ..replaceAllText('原草稿后文', cursorOffset: 0);
          final quill = QuillController.basic()..document.insert(0, '原草稿后文');
          final selection = selected
              ? const TextSelection(baseOffset: 0, extentOffset: 3)
              : const TextSelection.collapsed(offset: 1);
          mobile.textController.selection = selection;
          quill.updateSelection(selection, ChangeSource.local);
          final focus = FocusNode();
          final core = ChatAiAssistCore(
            transport: (_, {body}) => Stream.fromIterable([
              SseFrame(event: 'done', data: '{"text":"新内容"}'),
            ]),
          );
          final container = ProviderContainer(
            overrides: [
              authControllerProvider.overrideWith(_Auth.new),
              aiFeatureFlagsProvider.overrideWith(_Flags.new),
              roomMessagesProvider(
                'room',
              ).overrideWith((ref) => Stream.value([])),
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
                                onClose: () {},
                              )
                            : MobileChatAiPanel(
                                inputController: mobile,
                                roomId: 'room',
                                core: core,
                                onClose: () {},
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text(continuation ? '续写' : '润色'));
          await tester.pumpAndSettle();
          // 生成后移动光标，不能改变操作的目标位置。
          mobile.textController.selection = const TextSelection.collapsed(
            offset: 0,
          );
          quill.updateSelection(
            const TextSelection.collapsed(offset: 0),
            ChangeSource.local,
          );
          await tester.pump();
          final label = continuation
              ? '追加到原文末尾'
              : selected
              ? '替换选中文字'
              : '替换全部';
          await tester.tap(find.text(label));
          await tester.pump();
          final expected = continuation
              ? selected
                    ? '原草稿新内容后文'
                    : '原草稿后文新内容'
              : selected
              ? '新内容后文'
              : '新内容';
          expect(
            desktop ? quill.document.toPlainText().trim() : mobile.text,
            expected,
          );
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
