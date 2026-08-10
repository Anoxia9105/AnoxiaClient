import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/domain/repositories/sticker_repository.dart';
import 'package:anoxia/framework/domain/sticker_pack.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/network/dio_client.dart';

/// 表情包仓库实现
///
/// 通过远程数据源（HTTP API）提供表情包数据，含用户自定义表情包的创建与删除。
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

  @override
  Future<int> createCustomPack(String name, {String? iconUrl}) async {
    try {
      final response = await DioClient().post(
        API.stickerCustomPack,
        data: {'name': name, 'iconUrl': ?iconUrl},
      );
      if (response.data is! Map || response.data['code'] != 200) {
        debugLog('创建自定义表情包失败: ${response.data}');
        return 0;
      }
      return int.tryParse(response.data['data']?.toString() ?? '') ?? 0;
    } catch (e, st) {
      debugLog('创建自定义表情包失败', e, st);
      return 0;
    }
  }

  @override
  Future<bool> addCustomSticker(
    int packId,
    String imageUrl, {
    int? width,
    int? height,
  }) async {
    try {
      final response = await DioClient().post(
        API.stickerCustomSticker,
        data: {
          'packId': packId,
          'imageUrl': imageUrl,
          'width': ?width,
          'height': ?height,
        },
      );
      return response.data is Map && response.data['code'] == 200;
    } catch (e, st) {
      debugLog('新增自定义表情失败: $e\n$st');
      return false;
    }
  }

  @override
  Future<bool> deleteCustomPack(int packId) async {
    try {
      final response = await DioClient().delete(
        '${API.stickerCustomPackDelete}/$packId',
      );
      return response.data is Map && response.data['code'] == 200;
    } catch (e, st) {
      debugLog('删除自定义表情包失败: $e\n$st');
      return false;
    }
  }

  @override
  Future<bool> deleteCustomSticker(int stickerId) async {
    try {
      final response = await DioClient().delete(
        '${API.stickerCustomStickerDelete}/$stickerId',
      );
      return response.data is Map && response.data['code'] == 200;
    } catch (e, st) {
      debugLog('删除自定义表情失败: $e\n$st');
      return false;
    }
  }

  /// 兼容多种后端响应格式
  List<dynamic> _extractList(dynamic data) {
    if (data is! Map) return const <dynamic>[];

    final rows = data['rows'];
    if (rows is List) return rows;

    final rawData = data['data'];
    if (rawData is List) return rawData;
    if (rawData is Map && rawData['rows'] is List) {
      return rawData['rows'] as List;
    }

    debugLog('表情包接口返回格式异常: $data');
    return const [];
  }
}
