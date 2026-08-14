import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const expectedTooltips = <String, Map<String, String>>{
    'zh': {
      'appbar_voice_meeting_tooltip': '语音会议',
      'appbar_video_meeting_tooltip': '视频会议',
      'appbar_conversation_detail_tooltip': '会话详细',
    },
    'en': {
      'appbar_voice_meeting_tooltip': 'Voice meeting',
      'appbar_video_meeting_tooltip': 'Video meeting',
      'appbar_conversation_detail_tooltip': 'Conversation details',
    },
    'ja': {
      'appbar_voice_meeting_tooltip': '音声会議',
      'appbar_video_meeting_tooltip': 'ビデオ会議',
      'appbar_conversation_detail_tooltip': '会話の詳細',
    },
  };

  test('聊天顶栏按钮使用专用且语义正确的提示文案', () {
    for (final localeEntry in expectedTooltips.entries) {
      final translations = jsonDecode(
        File('assets/i18n/${localeEntry.key}.json').readAsStringSync(),
      ) as Map<String, dynamic>;

      for (final tooltipEntry in localeEntry.value.entries) {
        expect(
          translations[tooltipEntry.key],
          tooltipEntry.value,
          reason: '${localeEntry.key}.${tooltipEntry.key} 文案不正确',
        );
      }
    }
  });
}
