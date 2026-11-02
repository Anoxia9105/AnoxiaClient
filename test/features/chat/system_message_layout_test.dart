import 'dart:convert';
import 'dart:io';

import 'package:anoxia/features/chat/presentation/widgets/message_bubble/system_message_bubble.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/system_message_strategy.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/chat_room_detail_status_tag.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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

void main() {
  testWidgets('所有系统通知居中使用浅色提示条，窄屏长文完整换行', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final longName = List.filled(12, '很长的群成员昵称').join();
    Widget notice(String action, {String name = ''}) => SystemMessageBubble(
      message: ChatMessage(
        messageId: action,
        roomId: 'r',
        senderId: 1,
        messageType: MessageType.system,
        properties: {
          'action': action,
          'nickName': name,
          'names': name,
          'isMute': 'true',
        },
      ),
      strategy: SystemMessageStrategy(),
      textColor: Colors.black,
      horizontalPadding: 8,
      contentInset: 38,
      verticalPadding: 2,
    );
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('zh')],
        startLocale: const Locale('zh'),
        path: 'assets/i18n',
        assetLoader: const _Loader(),
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    notice('USER_JOINED', name: longName),
                    notice('ROOM_MUTED'),
                    ChatRoomDetailStatusTag(text: longName),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final joined = find.text('$longName 加入了房间');
    expect(joined, findsOneWidget);
    expect(tester.getTopLeft(joined).dx, 40);
    expect(tester.getSize(joined).height, greaterThan(36));
    final noticeContainers = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(SystemMessageBubble),
            matching: find.byType(Container),
          ),
        )
        .toList();
    expect(noticeContainers.where((c) => c.decoration != null), hasLength(2));
    final status = find.descendant(
      of: find.byType(ChatRoomDetailStatusTag),
      matching: find.text(longName),
    );
    expect(tester.getTopLeft(status).dx, 41);
    expect(tester.getSize(status).height, greaterThan(30));
    expect(tester.takeException(), isNull);
  });
}
