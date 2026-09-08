import 'package:anoxia/framework/domain/announcement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('严格解析完整公告', () {
    final item = Announcement.fromJson({
      'id': 7,
      'revision': 2,
      'title': '维护通知',
      'content': '内容',
      'level': 'REQUIRED',
      'publishAt': '2026-09-08T12:00:00Z',
      'expireAt': null,
      'read': false,
      'acknowledged': false,
    });

    expect(item.identity, '7:2');
    expect(item.level, AnnouncementLevel.required);
  });

  test('缺少状态字段时解析失败', () {
    expect(
      () => Announcement.fromJson({
        'id': 7,
        'revision': 2,
        'title': '通知',
        'content': '内容',
        'level': 'NORMAL',
        'publishAt': '2026-09-08T12:00:00Z',
      }),
      throwsFormatException,
    );
  });
}
