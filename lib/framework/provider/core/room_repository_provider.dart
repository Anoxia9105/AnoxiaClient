import 'package:anoxia/data/repositories/room_repository_impl.dart';
import 'package:anoxia/domain/repositories/room_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 房间仓库 Provider
///
/// 提供 [RoomRepository] 接口的实现，供 UI 层 Provider 使用。
final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepositoryImpl();
});
