// 离线交互验收：flutter run -d windows -t test/manual/message_selection_smoke.dart
// 复用真实菜单与渲染器，不登录、不连接消息服务、不发送任何消息。
import 'dart:convert';

import 'package:anoxia/features/chat/presentation/widgets/message_bubble/message_selection_scope.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_menu/chat_message_context_menu.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/quill_message_strategy.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/text_message_strategy.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/user_info.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/framework/provider/ai/ai_feature_flags_provider.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _OfflineAuth extends AuthController {
  @override
  Future<UserInfo?> build() async => null;
}

class _OfflineFlags extends AiFeatureFlagsNotifier {
  @override
  Future<AiFeatureFlags> build() async => const AiFeatureFlags(
    chatEnabled: false,
    noteEnabled: false,
    available: false,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_OfflineAuth.new),
        aiFeatureFlagsProvider.overrideWith(_OfflineFlags.new),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('zh'), Locale('en'), Locale('ja')],
        startLocale: const Locale('zh'),
        path: 'assets/i18n',
        child: Builder(
          builder: (context) => MaterialApp(
            title: 'Message selection smoke test',
            theme: ThemeData(fontFamily: 'NotoSansSC'),
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: [
              ...context.localizationDelegates,
              FlutterQuillLocalizations.delegate,
            ],
            home: const _SelectionSmoke(),
          ),
        ),
      ),
    ),
  );
}

class _SelectionSmoke extends StatelessWidget {
  const _SelectionSmoke();

  @override
  Widget build(BuildContext context) {
    Widget bubble(String text, {bool rich = true}) {
      final message = ChatMessage(
        messageId: text,
        senderId: 123,
        messageType: rich ? MessageType.richText : MessageType.text,
        content: text,
        payload: MessagePayload(
          content: text,
          quillDelta: jsonEncode([
            {
              'insert': text,
              'attributes': {'bold': true},
            },
            {'insert': '\n'},
          ]),
        ),
      );
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ChatMessageContextMenu(
          message: message,
          child: Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: rich
                ? QuillMessageStrategy().buildContent(
                    context,
                    message,
                    Colors.black,
                  )
                : TextMessageStrategy().buildContent(
                    context,
                    message,
                    Colors.black,
                  ),
          ),
        ),
      );
    }

    return MessageSelectionScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('文字选择离线验收')),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bubble('第一条富文本消息，可以拖动选中文字。'),
            bubble('第二条富文本消息，选择后第一条应取消高亮。'),
            bubble('普通文字也能选中和复制。', rich: false),
            const Expanded(child: SizedBox.expand()),
            const Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(hintText: '复制后在此粘贴，检查选中的内容'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
