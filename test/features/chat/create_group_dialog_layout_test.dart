import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anoxia/features/chat/presentation/widgets/create_chat_dialog_widget.dart';
import 'package:anoxia/features/chat/presentation/widgets/group_avatar_picker.dart';
import 'package:anoxia/framework/domain/chat_contact_vo.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DiskLoader extends AssetLoader {
  const _DiskLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) => Future.value(
    jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
        as Map<String, dynamic>,
  );
}

class _Contacts extends ContactListService {
  @override
  Map<int, ChatContactVO> build() => {
    2: ChatContactVO(contactId: 2, nickName: 'Alice'),
  };
}

ThemeData _testTheme() {
  final theme = AppTheme.getThemeByModeAndAccent(
    brightness: Brightness.light,
    accentIndex: 0,
  );
  if (!const bool.fromEnvironment('CAPTURE_GROUP_LAYOUT')) return theme;
  return theme.copyWith(
    textTheme: theme.textTheme.copyWith(
      labelLarge: theme.textTheme.labelLarge?.copyWith(
        fontFamily: 'JetBrainsMono',
        fontFamilyFallback: ['NotoSansSC'],
      ),
    ),
  );
}

void main() {
  var fontsLoaded = false;
  for (final scenario in [
    (size: const Size(1440, 900), keyboard: 0.0, locale: 'en', asPage: false),
    (size: const Size(390, 844), keyboard: 300.0, locale: 'zh', asPage: false),
    (size: const Size(844, 390), keyboard: 100.0, locale: 'ja', asPage: false),
    (size: const Size(390, 844), keyboard: 300.0, locale: 'zh', asPage: true),
    (size: const Size(844, 390), keyboard: 100.0, locale: 'ja', asPage: true),
  ]) {
    testWidgets(
      '建群弹窗 ${scenario.size} 键盘 ${scenario.keyboard} 页面 ${scenario.asPage} 无溢出且操作可见',
      (tester) async {
        if (const bool.fromEnvironment('CAPTURE_GROUP_LAYOUT') &&
            !fontsLoaded) {
          await tester.runAsync(() async {
            // Material 控件未声明字体时，测试引擎默认回退到 Ahem。
            for (final font in ['JetBrainsMono', 'NotoSansSC', 'Ahem', 'Roboto']) {
              final assetFont = font == 'Ahem' || font == 'Roboto'
                  ? 'JetBrainsMono'
                  : font;
              await (FontLoader(font)..addFont(
                    Future.value(
                      ByteData.sublistView(
                        File(
                          'assets/fonts/$assetFont[wght].ttf',
                        ).readAsBytesSync(),
                      ),
                    ),
                  ))
                  .load();
            }
            await (FontLoader('MaterialIcons')
                  ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
                .load();
            fontsLoaded = true;
          });
        }
        tester.view.physicalSize = scenario.size;
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = FakeViewPadding(bottom: scenario.keyboard);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        SharedPreferences.setMockInitialValues({});
        await EasyLocalization.ensureInitialized();
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('zh'), Locale('en'), Locale('ja')],
            path: 'assets/i18n',
            startLocale: Locale(scenario.locale),
            assetLoader: const _DiskLoader(),
            child: ProviderScope(
              overrides: [
                contactListServiceProvider.overrideWith(_Contacts.new),
                sortedContactGroupsProvider.overrideWith(
                  (ref) async => {
                    'A': [ChatContactVO(contactId: 2, nickName: 'Alice')],
                  },
                ),
              ],
              child: Builder(
                builder: (context) => MaterialApp(
                  locale: context.locale,
                  supportedLocales: context.supportedLocales,
                  localizationsDelegates: context.localizationDelegates,
                  theme: _testTheme(),
                  home: scenario.asPage
                      ? const CreateChatDialogWidget(asPage: true)
                      : Builder(
                          builder: (context) => Scaffold(
                            body: TextButton(
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (_) => const CreateChatDialogWidget(),
                              ),
                              child: const Text('open'),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (!scenario.asPage) {
          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();
        }
        expect(find.byType(GroupAvatarPicker), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byType(CheckboxListTile), findsOneWidget);
        final done = find.byType(FilledButton);
        expect(done, findsOneWidget);
        expect(tester.widget<FilledButton>(done).onPressed, isNull);
        final bounds = tester.getRect(done);
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(scenario.size.width));
        expect(bounds.top, greaterThanOrEqualTo(0));
        expect(
          bounds.bottom,
          lessThanOrEqualTo(scenario.size.height - scenario.keyboard),
        );
        if (const bool.fromEnvironment('CAPTURE_GROUP_LAYOUT')) {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              '../../../tasks/create_group_${scenario.size.width.toInt()}x${scenario.size.height.toInt()}_${scenario.asPage ? 'page' : 'dialog'}.png',
            ),
          );
        }
      },
    );
  }
}
