import 'dart:convert';
import 'dart:io';

import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/embedBuilder/quill_file_widgets.dart';
import 'package:anoxia/framework/domain/upload_entry.dart';
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization/src/easy_localization_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    await (FontLoader('NotoSansSC')..addFont(
          Future.value(
            ByteData.sublistView(
              File('assets/fonts/NotoSansSC[wght].ttf').readAsBytesSync(),
            ),
          ),
        ))
        .load();
  });

  for (final brightness in Brightness.values) {
    testWidgets('失败文件重试按钮可点击，图标保持紧凑（${brightness.name}）', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('zh')],
          startLocale: const Locale('zh'),
          path: 'assets/i18n',
          assetLoader: const _DiskLoader(),
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              theme: ThemeData(
                brightness: brightness,
                fontFamily: 'NotoSansSC',
              ),
              home: Scaffold(
                body: Center(
                  child: RepaintBoundary(
                    key: const ValueKey('card'),
                    child: FileEmbedCard(
                      attachment: const Attachment(
                        id: 'file1',
                        kind: 'FILE',
                        name: 'anoxiaclient.lib',
                        size: 2900,
                      ),
                      entry: UploadEntry.failed,
                      onRetry: () => retries++,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.byType(IconButton);
      expect(find.text('上传失败，点击重试'), findsOneWidget);
      expect(tester.widget<IconButton>(button).tooltip, '重试');
      final icon = find.descendant(of: button, matching: find.byType(HugeIcon));
      expect(tester.getSize(icon), const Size(18, 18));
      expect(tester.getSize(button).width, greaterThanOrEqualTo(36));
      await tester.tap(button);
      expect(retries, 1);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('card')),
        matchesGoldenFile('goldens/file_retry_${brightness.name}.png'),
      );
    });
  }
}
