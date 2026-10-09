import 'dart:convert';
import 'package:anoxia/framework/core/windows_incoming_call_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String build({bool video = false}) => buildWindowsIncomingCallContent(
    payload: {
      'inviteId': 'call"&<>',
      'roomId': 'room',
      'initialMedia': video ? 'video' : 'audio',
    },
    title: '张三 & <朋友>',
    body: '语音来电',
    avatar: Uri.parse('file:///C:/avatar.png'),
    rejectIcon: Uri.parse('file:///C:/reject.png'),
    acceptIcon: Uri.parse('file:///C:/accept.png'),
    rejectLabel: '拒绝',
    acceptLabel: '接听',
    rejectAction: 'call_reject',
    acceptAction: 'call_accept',
    voiceIcon: video ? Uri.parse('file:///C:/voice.png') : null,
    voiceLabel: '以语音接听',
    voiceAction: 'call_accept_voice',
  );

  test('来电布局包含头像、居中文案和彩色图标按钮，拒绝排在接听前', () {
    final xml = build();
    expect(xml, contains('scenario="incomingCall"'));
    expect(xml, contains('useButtonStyle="true"'));
    expect(
      xml,
      contains(
        '<image src="${const HtmlEscape().convert("file:///C:/avatar.png")}"',
      ),
    );
    expect(
      RegExp('hint-callScenarioCenterAlign="true"').allMatches(xml).length,
      2,
    );
    expect(xml, contains('hint-buttonStyle="Critical"'));
    expect(xml, contains('hint-buttonStyle="Success"'));
    expect(xml.indexOf('content="拒绝"'), lessThan(xml.indexOf('content="接听"')));
    expect(RegExp('<action ').allMatches(xml).length, 2);
    expect(xml, isNot(contains('appLogoOverride')));
  });

  test('转义姓名和 JSON 载荷，按钮保留原始邀请信息', () {
    final xml = build();
    expect(xml, contains('张三 &amp; &lt;朋友&gt;'));
    final expected = const HtmlEscape().convert(
      jsonEncode({
        'inviteId': 'call"&<>',
        'roomId': 'room',
        'initialMedia': 'audio',
        'kind': 'incoming_call',
        'actionId': 'call_reject',
      }),
    );
    expect(xml, contains('arguments="$expected"'));
  });

  test('视频来电额外提供语音接听且使用独立动作', () {
    final xml = build(video: true);
    expect(RegExp('<action ').allMatches(xml).length, 3);
    expect(xml, contains('content="以语音接听"'));
    expect(xml, contains('call_accept_voice'));
    expect(
      xml,
      contains(
        'imageUri="${const HtmlEscape().convert("file:///C:/voice.png")}"',
      ),
    );
  });
}
