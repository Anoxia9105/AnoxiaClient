import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/domain/repositories/announcement_repository.dart';
import 'package:anoxia/framework/domain/announcement.dart';
import 'package:anoxia/framework/network/dio_client.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl({DioClient? client})
    : _client = client ?? DioClient();

  final DioClient _client;

  @override
  Future<List<Announcement>> fetchActive({
    required String platform,
    required int versionCode,
  }) async {
    final response = await _client.get(
      '${API.systemAnnouncements}/active',
      queryParameters: {'platform': platform, 'versionCode': versionCode},
    );
    return parseActiveResponse(response.data);
  }

  @override
  Future<AnnouncementPage> fetchPage({
    required String platform,
    required int versionCode,
    required int pageNum,
    required int pageSize,
  }) async {
    final response = await _client.get(
      API.systemAnnouncements,
      queryParameters: {
        'platform': platform,
        'versionCode': versionCode,
        'pageNum': pageNum,
        'pageSize': pageSize,
      },
    );
    return parsePageResponse(response.data);
  }

  @override
  Future<void> markRead(int id, int revision) =>
      _putStatus(id, revision, 'read');

  @override
  Future<void> acknowledge(int id, int revision) =>
      _putStatus(id, revision, 'acknowledgement');

  Future<void> _putStatus(int id, int revision, String action) async {
    final response = await _client.put(
      '${API.systemAnnouncements}/$id/revisions/$revision/$action',
    );
    _requireSuccess(response.data);
  }

  static List<Announcement> parseActiveResponse(dynamic payload) {
    final data = _ajaxData(payload);
    if (data is! List) throw const FormatException('invalid announcement data');
    return List<Announcement>.unmodifiable(
      data.map((item) {
        if (item is! Map) {
          throw const FormatException('invalid announcement row');
        }
        return Announcement.fromJson(item);
      }),
    );
  }

  static AnnouncementPage parsePageResponse(dynamic payload) {
    if (payload is! Map || payload['code'] != 200) {
      throw const FormatException('invalid announcement page');
    }
    final rows = payload['rows'];
    final total = payload['total'];
    if (rows is! List || total is! num) {
      throw const FormatException('invalid announcement page shape');
    }
    return AnnouncementPage(
      rows: List<Announcement>.unmodifiable(
        rows.map((item) {
          if (item is! Map) {
            throw const FormatException('invalid announcement row');
          }
          return Announcement.fromJson(item);
        }),
      ),
      total: total.toInt(),
    );
  }

  static dynamic _ajaxData(dynamic payload) {
    if (payload is! Map ||
        payload['code'] != 200 ||
        !payload.containsKey('data')) {
      throw const FormatException('invalid announcement response');
    }
    return payload['data'];
  }

  static void _requireSuccess(dynamic payload) {
    if (payload is! Map || payload['code'] != 200) {
      throw const FormatException('announcement operation failed');
    }
  }
}
