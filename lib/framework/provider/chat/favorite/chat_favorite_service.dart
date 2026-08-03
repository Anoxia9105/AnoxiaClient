import 'package:anoxia/data/repositories/favorite_repository_impl.dart';
import 'package:anoxia/domain/repositories/favorite_repository.dart';
import 'package:anoxia/framework/domain/chat_favorite.dart';
import 'package:anoxia/framework/provider/core/favorite_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_favorite_service.g.dart';

/// 聊天收藏列表 Provider
@Riverpod(keepAlive: true)
Future<List<ChatFavorite>> chatFavoriteList(Ref ref) async {
  return ChatFavoriteService(ref.read(favoriteRepositoryProvider))
      .listFavorites();
}

/// 聊天收藏服务
///
/// 封装收藏消息的列表查询逻辑。
class ChatFavoriteService {
  final FavoriteRepository _repo;

  ChatFavoriteService([FavoriteRepository? repo])
      : _repo = repo ?? FavoriteRepositoryImpl();

  /// 获取收藏消息列表
  ///
  /// [type] 可选的消息类型过滤
  ///
  /// 返回按时间倒序排列的收藏列表
  Future<List<ChatFavorite>> listFavorites({String? type}) {
    return _repo.listFavorites(type: type);
  }

  /// 取消收藏消息
  ///
  /// [favoriteId] 收藏记录 ID（[ChatFavorite.id]）
  ///
  /// 返回是否操作成功
  Future<bool> removeFavorite(int favoriteId) {
    return _repo.removeFavorite(favoriteId);
  }
}
