import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:anoxia/features/chat/presentation/call/component/call_diagnostics_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
// SDK 2.13.1 返回的统计类型尚未在入口库导出。
// ignore: implementation_imports
import 'package:livekit_client/src/stats/stats.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Video extends Fake implements lk.LocalVideoTrack {
  int sample = 0;
  bool idle = false;
  @override
  String get codec => 'vp8';
  @override
  Future<List<VideoSenderStats>> getSenderStats() async {
    sample++;
    return [
      for (final id in ['high', 'low'])
        VideoSenderStats(id, sample * 3000000)
          ..bytesSent = (idle ? 2 : sample) * 187500
          ..framesSent = (idle ? 2 : sample) * 90
          ..frameWidth = 1280
          ..frameHeight = 720,
    ];
  }
}

class _Publication extends Fake
    implements lk.LocalTrackPublication<lk.LocalVideoTrack> {
  _Publication(this.track);
  @override
  final lk.LocalVideoTrack track;
  @override
  String get sid => 'camera';
  @override
  bool get muted => false;
  @override
  bool get isScreenShare => false;
}

class _Participant extends Fake implements lk.LocalParticipant {
  _Participant(this.videoTrackPublications);
  @override
  final List<lk.LocalTrackPublication<lk.LocalVideoTrack>>
  videoTrackPublications;
  @override
  String get identity => 'local';
}

class _Room extends Fake implements lk.Room {
  _Room(this.localParticipant);
  @override
  final lk.LocalParticipant localParticipant;
  @override
  UnmodifiableMapView<String, lk.RemoteParticipant> get remoteParticipants =>
      UnmodifiableMapView({});
}

class _Translations extends AssetLoader {
  const _Translations();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File('$path/en.json').readAsStringSync())
          as Map<String, dynamic>;
}

void main() {
  testWidgets('诊断主动采样多层流，微秒时间戳显示实际 Mbps 和零流量', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final video = _Video();
    final room = _Room(_Participant([_Publication(video)]));
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        startLocale: const Locale('en'),
        path: 'assets/i18n',
        assetLoader: const _Translations(),
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showCallDiagnostics(context, room, null),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Sampling…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('1.00 Mbps'), findsOneWidget);
    expect(find.text('30.0'), findsOneWidget);
    expect(find.textContaining('SDK'), findsNothing);
    video.idle = true;
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('0.0 kbps'), findsOneWidget);
    expect(find.text('0.0'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
