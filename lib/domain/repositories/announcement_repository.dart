import 'package:anoxia/framework/domain/announcement.dart';

abstract interface class AnnouncementRepository {
  Future<List<Announcement>> fetchActive({
    required String platform,
    required int versionCode,
  });

  Future<AnnouncementPage> fetchPage({
    required String platform,
    required int versionCode,
    required int pageNum,
    required int pageSize,
  });

  Future<void> markRead(int id, int revision);

  Future<void> acknowledge(int id, int revision);
}
