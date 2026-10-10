import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization/src/easy_localization_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_menu/chat_message_context_menu.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Input extends ChatInputController {
  int retries = 0;
  ChatMessage? deleted;
  @override
  QuillController build(String roomId) {
    final editor = QuillController.basic();
    ref.onDispose(editor.dispose);
    return editor;
  }

  @override
  Future<bool> retryLocalMediaMessage(ChatMessage message) async {
    retries++;
    return true;
  }

  @override
  Future<void> discardFailedMessage(ChatMessage message) async {
    deleted = message;
  }
}

class _DiskLoader extends AssetLoader {
  const _DiskLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) => Future.value(
    jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
        as Map<String, dynamic>,
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalizationController.initEasyLocation();
  });
  for (final action in ['retry', 'chat_delete_failed_message']) {
    testWidgets('失败消息长按菜单可执行 $action', (tester) async {
      final input = _Input();
      final message = ChatMessage(
        messageId: 'local',
        clientMsgId: 'local',
        roomId: 'room',
        deliveryStatus: DeliveryStatus.failed,
        messageType: MessageType.image,
        payload: const MessagePayload().withMedia(MessageType.image, [
          const Attachment(id: 'local', url: '/tmp/image.png'),
        ]),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatInputControllerProvider('room').overrideWith(() => input),
          ],
          child: EasyLocalization(
            supportedLocales: const [Locale('zh')],
            startLocale: const Locale('zh'),
            path: 'assets/i18n',
            assetLoader: const _DiskLoader(),
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Scaffold(
                  body: ChatMessageContextMenu(
                    message: message,
                    child: const SizedBox(
                      width: 200,
                      height: 160,
                      child: Text('failed image'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.longPress(find.text('failed image'));
      await tester.pumpAndSettle();
      expect(find.text('重试'), findsOneWidget);
      expect(find.text('删除消息'), findsOneWidget);
      await tester.tap(find.text(action == 'retry' ? '重试' : '删除消息'));
      await tester.pumpAndSettle();
      expect(
        action == 'retry' ? input.retries : input.deleted,
        action == 'retry' ? 1 : message,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
