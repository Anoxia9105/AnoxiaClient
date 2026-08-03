import 'package:anoxia/data/repositories/favorite_repository_impl.dart';
import 'package:anoxia/domain/repositories/favorite_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 收藏仓库 Provider
///
/// 提供 [FavoriteRepository] 接口的实现，供 UI 层 Provider 使用。
final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepositoryImpl();
});
