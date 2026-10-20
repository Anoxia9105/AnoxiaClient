import 'package:anoxia/framework/domain/call_log_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('完整字段解析：单聊进行中与群聊已完成', () {
    final page = CallHistoryPageData.fromJson(const {
      'total': 2,
      'rows': [
        {
          'messageId': 'm1',
          'roomId': 'room-a',
          'roomType': 0,
          'peerId': 9,
          'peerName': '对端',
          'peerAvatar': 'https://example.test/avatar.png',
          'callerId': 7,
          'outgoing': true,
          'startAt': 1000,
          'endAt': 1080,
          'durationSec': 80,
          'durationText': '01:20',
          'status': 'COMPLETED',
        },
        {
          'messageId': 'm2',
          'roomId': 'room-g',
          'roomType': 1,
          'roomName': '项目群',
          'callerId': 9,
          'outgoing': false,
          'startAt': 2000,
          'status': 'ONGOING',
        },
      ],
    });

    expect(page.total, 2);
    expect(page.entries, hasLength(2));

    final completed = page.entries[0];
    expect(completed.status, CallLogStatus.completed);
    expect(completed.outgoing, isTrue);
    expect(completed.durationSec, 80);
    expect(completed.durationText, '01:20');
    expect(completed.endAt, 1080);
    expect(completed.displayName, '对端');

    final ongoing = page.entries[1];
    expect(ongoing.status, CallLogStatus.ongoing);
    expect(ongoing.endAt, isNull);
    expect(ongoing.durationSec, isNull);
    expect(ongoing.displayName, '项目群');
  });

  test('响应缺 rows 或 rows 非 List 时得到空页', () {
    expect(CallHistoryPageData.fromJson(const {'total': 8}).entries, isEmpty);
    expect(
      CallHistoryPageData.fromJson(const {'total': 8}).total,
      8,
      reason: 'total 独立于 rows 单独下发',
    );
    expect(
      CallHistoryPageData.fromJson(const {'rows': 'not-a-list'}).total,
      0,
      reason: 'total 缺省回落 entries.length（此处为空）',
    );
  });

  test('total 显式给出时与行数解耦', () {
    final page = CallHistoryPageData.fromJson(const {'rows': []});
    expect(page.total, 0);
    expect(CallHistoryPageData.fromJson(const {'rows': [], 'total': 42}).total,
        42);
  });

  test('脏行容错：数字字符串转换 / 未知状态回落 completed / 非法行剔除', () {
    final page = CallHistoryPageData.fromJson(const {
      'rows': [
        {
          'messageId': 'm1',
          'roomId': 'room-a',
          'startAt': '1000',
          'status': 'MYSTERY',
          'outgoing': false,
        },
      ],
    });

    expect(page.entries, hasLength(1));
    expect(page.entries.single.startAt, 1000);
    expect(page.entries.single.status, CallLogStatus.completed);
    expect(page.entries.single.roomType, 0);
    expect(page.entries.single.displayName, '',
        reason: '无对端/房间名时退回空串，由 UI 层补占位');
  });

  test('displayName：单聊优先对端名，群聊优先房间名', () {
    final single = CallLogEntry.fromJson(const {
      'messageId': 's1',
      'roomId': 'r',
      'roomType': 0,
      'peerName': '张三',
      'roomName': '不该用',
      'outgoing': true,
      'startAt': 1,
    });
    final group = CallLogEntry.fromJson(const {
      'messageId': 'g1',
      'roomId': 'r',
      'roomType': 1,
      'peerName': '不该用',
      'roomName': '开发群',
      'outgoing': true,
      'startAt': 1,
    });

    expect(single.displayName, '张三');
    expect(group.displayName, '开发群');
  });
}
