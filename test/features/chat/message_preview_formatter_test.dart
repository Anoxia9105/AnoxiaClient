import 'dart:convert';
import 'dart:io';

import 'package:anoxia/features/chat/application/message_preview_formatter.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DiskAssetLoader extends AssetLoader {
  const _DiskAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) => Future.value(
    jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
        as Map<String, dynamic>,
  );
}

void main() {
  for (final entry in {
    'zh': ['[图像]', '[语音]', '[视频]', '[文件]'],
    'en': ['[Image]', '[Voice message]', '[Video]', '[File]'],
    'ja': ['[画像]', '[ボイスメッセージ]', '[動画]', '[ファイル]'],
  }.entries) {
    testWidgets('系统通知摘要使用 ${entry.key}，保留实际内容', (tester) async {
      SharedPreferences.setMockInitialValues(const {});
      await EasyLocalization.ensureInitialized();
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('zh'), Locale('en'), Locale('ja')],
          startLocale: Locale(entry.key),
          saveLocale: false,
          path: 'assets/i18n',
          assetLoader: const _DiskAssetLoader(),
          child: Builder(
            builder: (context) => MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final types = [
        MessageType.image,
        MessageType.audio,
        MessageType.video,
        MessageType.file,
      ];
      final markers = ['[image]', '[voice]', '[video]', '[file]'];
      for (var i = 0; i < types.length; i++) {
        expect(
          MessagePreviewFormatter.format(
            ChatMessage(messageType: types[i], content: markers[i]),
          ),
          entry.value[i],
        );
      }
      for (final marker in ['[audio]', '[voide]']) {
        expect(
          MessagePreviewFormatter.format(
            ChatMessage(messageType: MessageType.audio, content: marker),
          ),
          entry.value[1],
        );
      }
      expect(
        MessagePreviewFormatter.format(
          ChatMessage(
            messageType: MessageType.image,
            content: '[image]',
            payload: const MessagePayload(content: '周末照片'),
          ),
        ),
        '周末照片',
      );
      expect(
        MessagePreviewFormatter.format(
          ChatMessage(
            messageType: MessageType.file,
            content: '[file]',
            payload: const MessagePayload(file: Attachment(name: '报告.pdf')),
          ),
        ),
        '报告.pdf',
      );
      expect(
        MessagePreviewFormatter.format(
          ChatMessage(messageType: MessageType.text, content: '[image]'),
        ),
        '[image]',
      );
    });
  }
}
