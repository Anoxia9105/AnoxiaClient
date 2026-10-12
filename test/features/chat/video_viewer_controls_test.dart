import 'package:anoxia/features/chat/presentation/widgets/message_render/detail/video_viewer_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('视频起点显示00:00，长视频保留小时', () {
    expect(formatVideoDuration(Duration.zero), '00:00');
    expect(
      formatVideoDuration(const Duration(hours: 1, seconds: 2)),
      '1:00:02',
    );
  });

  testWidgets('播放前显示总时长和禁用的进度条，初始化期间有反馈', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VideoControlBar(
            initialized: false,
            initializing: true,
            isPlaying: false,
            isMuted: true,
            hasError: false,
            controller: null,
            durationHint: const Duration(seconds: 65),
            onTogglePlay: () {},
            onToggleMute: () {},
          ),
        ),
      ),
    );
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('01:05'), findsOneWidget);
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
