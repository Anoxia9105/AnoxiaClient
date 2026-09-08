import 'dart:async';

import 'package:anoxia/domain/repositories/announcement_repository.dart';
import 'package:anoxia/framework/domain/announcement.dart';
import 'package:anoxia/framework/provider/announcement/announcement_controller.dart';
import 'package:anoxia/framework/provider/core/announcement_repository_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Announcement item({
  required int id,
  required AnnouncementLevel level,
  required DateTime publishAt,
  bool read = false,
  bool acknowledged = false,
}) => Announcement(
  id: id,
  revision: 1,
  title: '$id',
  content: 'content',
  level: level,
  publishAt: publishAt,
  expireAt: null,
  read: read,
  acknowledged: acknowledged,
);

void main() {
  test('待处理队列优先 REQUIRED，再按发布时间稳定排序', () {
    final result = pendingAnnouncements([
      item(
        id: 3,
        level: AnnouncementLevel.normal,
        publishAt: DateTime(2026, 1, 1),
      ),
      item(
        id: 2,
        level: AnnouncementLevel.required,
        publishAt: DateTime(2026, 1, 2),
      ),
      item(
        id: 1,
        level: AnnouncementLevel.required,
        publishAt: DateTime(2026, 1, 1),
      ),
    ]);

    expect(result.map((value) => value.id), [2, 1, 3]);
  });

  test('NORMAL 以 read、REQUIRED 以 acknowledged 判断待处理', () {
    final result = pendingAnnouncements([
      item(
        id: 1,
        level: AnnouncementLevel.normal,
        publishAt: DateTime(2026),
        read: true,
      ),
      item(
        id: 2,
        level: AnnouncementLevel.required,
        publishAt: DateTime(2026),
        read: true,
      ),
      item(
        id: 3,
        level: AnnouncementLevel.required,
        publishAt: DateTime(2026),
        acknowledged: true,
      ),
    ]);

    expect(result.map((value) => value.id), [2]);
  });

  test('build number 非整数时回退为 0', () {
    expect(parseBuildNumber('not-a-number'), 0);
    expect(parseBuildNumber(' 42 '), 42);
  });

  test('并发 refresh 复用同一个请求', () async {
    final repository = _FakeAnnouncementRepository();
    final clientInfo = Completer<AnnouncementClientInfo>();
    final container = ProviderContainer(
      overrides: [
        announcementRepositoryProvider.overrideWithValue(repository),
        announcementControllerProvider.overrideWith(
          () =>
              AnnouncementController(clientInfoLoader: () => clientInfo.future),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(announcementControllerProvider.notifier);

    final first = controller.refresh();
    final second = controller.refresh();
    clientInfo.complete((platform: 'web', versionCode: 0));
    await Future.wait([first, second]);

    expect(repository.activeCalls, 1);
  });
}

class _FakeAnnouncementRepository implements AnnouncementRepository {
  int activeCalls = 0;

  @override
  Future<List<Announcement>> fetchActive({
    required String platform,
    required int versionCode,
  }) async {
    activeCalls++;
    return const [];
  }

  @override
  Future<void> acknowledge(int id, int revision) async {}

  @override
  Future<AnnouncementPage> fetchPage({
    required String platform,
    required int versionCode,
    required int pageNum,
    required int pageSize,
  }) => throw UnimplementedError();

  @override
  Future<void> markRead(int id, int revision) async {}
}
