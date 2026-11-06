import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:anoxia/framework/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class DesignAssetLoader extends AssetLoader {
  const DesignAssetLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) => Future.value(
    jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
        as Map<String, dynamic>,
  );
}

Future<void> loadDesignFonts() async {
  for (final family in ['JetBrainsMono', 'NotoSansSC']) {
    await (FontLoader(family)..addFont(
          Future.value(
            ByteData.sublistView(
              File('assets/fonts/$family[wght].ttf').readAsBytesSync(),
            ),
          ),
        ))
        .load();
  }
}

Widget designTestApp({
  required ProviderContainer container,
  required Widget child,
  required Locale locale,
  required Brightness brightness,
  double textScale = 1.3,
  GlobalKey? captureKey,
}) => UncontrolledProviderScope(
  container: container,
  child: EasyLocalization(
    key: ValueKey(locale),
    supportedLocales: [locale],
    startLocale: locale,
    path: 'assets/i18n',
    assetLoader: const DesignAssetLoader(),
    saveLocale: false,
    child: Builder(
      builder: (context) => MaterialApp(
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        theme: AppTheme.getThemeByModeAndAccent(
          brightness: brightness,
          accentIndex: 0,
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: RepaintBoundary(key: captureKey, child: child),
      ),
    ),
  ),
);
Future<void> captureDesign(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('../.tools/anoxia-ui-preview/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}
