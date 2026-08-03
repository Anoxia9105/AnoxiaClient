import 'package:anoxia/framework/domain/chat_favorite.dart';

/// 收藏仓库抽象接口
///
/// 定义聊天收藏相关的数据操作契约。
/// 数据层通过实现此接口提供具体实现，UI 层 Provider 仅依赖此接口。
abstract interface class FavoriteRepository {
  /// 获取收藏消息列表
  ///
  /// [type] 可选的消息类型过滤
  ///
  /// 返回按时间倒序排列的收藏列表。
  Future<List<ChatFavorite>> listFavorites({String? type});

  /// 收藏消息
  ///
  /// [messageId] 目标消息 ID
  ///
  /// 返回是否操作成功。
  Future<bool> addFavorite(String messageId);

  /// 取消收藏消息
  ///
  /// [favoriteId] 收藏记录 ID（[ChatFavorite.id]）
  ///
  /// 返回是否操作成功。
  Future<bool> removeFavorite(int favoriteId);
}
