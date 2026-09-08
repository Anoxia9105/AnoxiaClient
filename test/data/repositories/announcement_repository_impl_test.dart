import 'package:anoxia/data/repositories/announcement_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active 响应 data 非列表时不能降级为空列表', () {
    expect(
      () => AnnouncementRepositoryImpl.parseActiveResponse({
        'code': 200,
        'data': {},
      }),
      throwsFormatException,
    );
  });

  test('分页响应缺少 total 时解析失败', () {
    expect(
      () => AnnouncementRepositoryImpl.parsePageResponse({
        'code': 200,
        'rows': [],
      }),
      throwsFormatException,
    );
  });

  test('active 响应解析 SQL 回退后的非空 publishAt', () {
    final items = AnnouncementRepositoryImpl.parseActiveResponse({
      'code': 200,
      'data': [
        {
          'id': 7,
          'revision': 2,
          'title': '公告',
          'content': '内容',
          'level': 'NORMAL',
          'publishAt': '2026-09-08T10:20:30',
          'expireAt': null,
          'read': false,
          'acknowledged': false,
        },
      ],
    });

    expect(items.single.publishAt, DateTime(2026, 9, 8, 10, 20, 30));
  });
}
