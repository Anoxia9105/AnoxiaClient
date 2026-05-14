import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/domain/ChatFavorite.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 聊天收藏服务
final chatFavoriteServiceProvider = Provider<ChatFavoriteService>((ref) {
  return ChatFavoriteService();
});

/// 聊天收藏列表 Provider
///
/// 支持自动销毁，离开页面时自动清理内存
final chatFavoriteListProvider =
    FutureProvider.autoDispose<List<ChatFavorite>>((ref) async {
      final service = ref.watch(chatFavoriteServiceProvider);
      return service.listFavorites();
    });

/// 聊天收藏服务
///
/// 封装收藏消息的列表查询逻辑。
class ChatFavoriteService {
  /// 获取收藏消息列表
  ///
  /// [type] 可选的消息类型过滤
  ///
  /// 返回按时间倒序排列的收藏列表
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
      if (bTime != aTime) {
        return bTime.compareTo(aTime);
      }
      return b.id.compareTo(a.id);
    });

    return list;
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
