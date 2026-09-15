import 'dart:convert';
import 'dart:io';

import 'package:anoxia/features/chat/application/system_message_formatter.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 测试环境直接读磁盘语言包。
///
/// `flutter test` 下 rootBundle 取不到 assets/i18n（既有测试也会刷
/// «Localization key [...] not found»），若沿用默认加载器，`.tr()` 只会返回
/// key 本身，断言就失去意义。
///
/// 注意用同步读 + `Future.value`：widget 测试跑在 fake async 里，
/// 真正的异步 I/O 不会被 `pumpAndSettle` 推进，语言包会永远加载不出来。
class _DiskAssetLoader extends AssetLoader {
  const _DiskAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) {
    final file = File('$path/${locale.languageCode}.json');
    if (!file.existsSync()) return Future<Map<String, dynamic>?>.value();
    return Future<Map<String, dynamic>?>.value(
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
    );
  }
}

/// 通话系统消息文案区分会话类型：1:1 用「通话」口径，群聊才是「会议」口径。
ChatMessage _systemMessage(
  String action, {
  Map<String, String> extra = const {},
}) {
  return ChatMessage(
    messageId: 'm1',
    roomId: 'r1',
    senderId: 1,
    messageType: MessageType.system,
    properties: {'action': action, ...extra},
  );
}

/// 最小探针：直接渲染 [SystemMessageFormatter] 的文案，避免依赖 Provider。
class _Probe extends StatelessWidget {
  const _Probe({required this.message, required this.isGroup});

  final ChatMessage message;
  final bool isGroup;

  @override
  Widget build(BuildContext context) => Text(
    SystemMessageFormatter.display(message, isGroup: isGroup).text,
  );
}

Future<void> _pumpProbe(
  WidgetTester tester, {
  required ChatMessage message,
  required bool isGroup,
}) async {
  SharedPreferences.setMockInitialValues(const {});
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('zh'), Locale('ja')],
      path: 'assets/i18n',
      assetLoader: const _DiskAssetLoader(),
      fallbackLocale: const Locale('zh'),
      startLocale: const Locale('zh'),
      useFallbackTranslations: true,
      // 必须把 EasyLocalization 的 delegates 交给内层 MaterialApp，
      // 否则 assemble 阶段不会调用 delegate.load()，`.tr()` 只会返回 key。
      child: Builder(
        builder: (context) => MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: Scaffold(body: _Probe(message: message, isGroup: isGroup)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('通话开始系统消息文案', () {
    testWidgets('1:1 显示「发起了通话」', (tester) async {
      await _pumpProbe(
        tester,
        message: _systemMessage('CALL_STARTED', extra: {'nickName': '张三'}),
        isGroup: false,
      );

      expect(find.text('张三 发起了通话'), findsOneWidget);
      expect(find.text('张三 开启了会议'), findsNothing);
    });

    testWidgets('群聊显示「开启了会议」', (tester) async {
      await _pumpProbe(
        tester,
        message: _systemMessage('CALL_STARTED', extra: {'nickName': '张三'}),
        isGroup: true,
      );

      expect(find.text('张三 开启了会议'), findsOneWidget);
      expect(find.text('张三 发起了通话'), findsNothing);
    });
  });

  group('通话结束系统消息文案', () {
    // 时长档位表（zh）：秒数 → 期望文案。0 秒/缺失走「不带时长」分支。
    const singleCases = <String, String>{
      '5': '通话已结束 5秒',
      '59': '通话已结束 59秒',
      '60': '通话已结束 1分钟',
      '125': '通话已结束 2分5秒',
      '219': '通话已结束 3分39秒',
      '3599': '通话已结束 59分59秒',
      '3600': '通话已结束 1小时',
      '3840': '通话已结束 1小时4分',
      '3930': '通话已结束 1小时5分',
      '7200': '通话已结束 2小时',
    };
    const groupCases = <String, String>{
      '5': '会议已结束 5秒',
      '60': '会议已结束 1分钟',
      '219': '会议已结束 3分39秒',
      '3840': '会议已结束 1小时4分',
    };

    for (final entry in singleCases.entries) {
      testWidgets('1:1 ${entry.key}s → ${entry.value}', (tester) async {
        await _pumpProbe(
          tester,
          message: _systemMessage('CALL_ENDED', extra: {'duration': entry.key}),
          isGroup: false,
        );

        expect(find.text(entry.value), findsOneWidget);
      });
    }

    for (final entry in groupCases.entries) {
      testWidgets('群聊 ${entry.key}s → ${entry.value}', (tester) async {
        await _pumpProbe(
          tester,
          message: _systemMessage('CALL_ENDED', extra: {'duration': entry.key}),
          isGroup: true,
        );

        expect(find.text(entry.value), findsOneWidget);
      });
    }

    testWidgets('1:1 不足 1 分钟不再显示「0分」', (tester) async {
      await _pumpProbe(
        tester,
        message: _systemMessage('CALL_ENDED', extra: {'duration': '42'}),
        isGroup: false,
      );

      expect(find.text('通话已结束 42秒'), findsOneWidget);
      expect(find.text('通话已结束 0分'), findsNothing);
    });

    testWidgets('0 秒按「不带时长」处理（1:1）', (tester) async {
      await _pumpProbe(
        tester,
        message: _systemMessage('CALL_ENDED', extra: {'duration': '0'}),
        isGroup: false,
      );

      expect(find.text('通话已结束'), findsOneWidget);
    });

    testWidgets('0 秒按「不带时长」处理（群聊 → 会议已结束）', (tester) async {
      await _pumpProbe(
        tester,
        message: _systemMessage('CALL_ENDED', extra: {'duration': '0'}),
        isGroup: true,
      );

      expect(find.text('会议已结束'), findsOneWidget);
    });

    testWidgets('秒数缺失时回落服务端 mm:ss（1:1）', (tester) async {
      await _pumpProbe(
        tester,
        message: _systemMessage(
          'CALL_ENDED',
          extra: {'durationText': '03:39'},
        ),
        isGroup: false,
      );

      expect(find.text('通话已结束 03:39'), findsOneWidget);
    });

    testWidgets('缺失时长时回落为「通话已结束」', (tester) async {
      await _pumpProbe(
        tester,
        message: _systemMessage('CALL_ENDED'),
        isGroup: false,
      );

      expect(find.text('通话已结束'), findsOneWidget);
    });
  });
}
