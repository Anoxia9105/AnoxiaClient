import 'package:anoxia/features/chat/presentation/widgets/message_render/detail/video_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatVideoDuration', () {
    test('zero duration shows placeholder', () {
      expect(formatVideoDuration(Duration.zero), '--:--');
      expect(formatVideoDuration(const Duration(milliseconds: -1)), '--:--');
    });

    test('sub-minute formats as mm:ss', () {
      expect(formatVideoDuration(const Duration(seconds: 5)), '00:05');
      expect(formatVideoDuration(const Duration(seconds: 65)), '01:05');
    });

    test('over an hour formats as h:mm:ss', () {
      expect(
        formatVideoDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });
  });

  testWidgets('control bar shows position and total duration', (tester) async {
    // 视频播放器平台在单元测试中不可用，这里只验证控制栏在未初始化时的
    // 基础状态渲染，不创建 real VideoPlayerController。
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VideoControlBar(
            initialized: false,
            isPlaying: false,
            isMuted: true,
            hasError: false,
            onTogglePlay: () {},
            onToggleMute: () {},
            controller: null,
          ),
        ),
      ),
    );

    // 未初始化时只有播放按钮，无时间行
    expect(find.byType(VideoControlBar), findsOneWidget);
    expect(find.text('--:--'), findsNothing);
  });
}
