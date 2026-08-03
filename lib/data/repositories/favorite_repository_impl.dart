import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/domain/repositories/favorite_repository.dart';
import 'package:anoxia/framework/domain/chat_favorite.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/network/dio_client.dart';

/// 收藏仓库实现
///
/// 通过远程数据源（HTTP API）提供收藏相关操作。
/// 实现 [FavoriteRepository] 抽象接口，供 UI 层 Provider 使用。
class FavoriteRepositoryImpl implements FavoriteRepository {
  @override
  Future<List<ChatFavorite>> listFavorites({String? type}) async {
    final response = await DioClient().get(
      API.chatFavoriteList,
      queryParameters: {
        if (type != null && type.isNotEmpty) 'type': type,
        'pageNum': 1,
        'pageSize': 200,
      },
    );

    final data = response.data;
    final List<dynamic> rawList = _extractList(data);

    final list = rawList
        .map((e) => ChatFavorite.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    // 按时间倒序，同时间按 ID 倒序
    list.sort((a, b) {
      final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
      final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
      if (bTime != aTime) return bTime.compareTo(aTime);
      return b.id.compareTo(a.id);
    });

    return list;
  }

  @override
  Future<bool> addFavorite(String messageId) async {
    try {
      final response = await DioClient().post('${API.chatFavoriteAdd}/$messageId');
      return response.data['code'] == 200;
    } catch (e) {
      log.error('收藏消息失败: $e');
      return false;
    }
  }

  @override
  Future<bool> removeFavorite(int favoriteId) async {
    try {
      final response = await DioClient().post(
        '${API.chatFavoriteRemove}/$favoriteId',
      );
      return response.data['code'] == 200;
    } catch (e) {
      log.error('取消收藏失败: $e');
      return false;
    }
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

    return const [];
  }
}
