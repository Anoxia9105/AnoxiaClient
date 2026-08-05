import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/domain/repositories/sticker_repository.dart';
import 'package:anoxia/framework/domain/sticker_pack.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/network/dio_client.dart';

/// 表情包仓库实现
///
/// 通过远程数据源（HTTP API）提供表情包数据。
class StickerRepositoryImpl implements StickerRepository {
  @override
  Future<List<StickerPack>> fetchPacks() async {
    final response = await DioClient().get(API.stickerPacks);
    final data = response.data;
    final rawList = _extractList(data);

    return rawList
        .map((e) => StickerPack.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// 兼容多种后端响应格式
  dynamic _extractList(dynamic data) {
    if (data is! Map) return const [];

    final rows = data['rows'];
    if (rows is List) return rows;

    final rawData = data['data'];
    if (rawData is List) return rawData;
    if (rawData is Map && rawData['rows'] is List) {
      return rawData['rows'] as List;
    }

    log.error('表情包接口返回格式异常: $data');
    return const [];
  }
}
