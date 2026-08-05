import 'package:anoxia/framework/domain/sticker_pack.dart';
import 'package:anoxia/framework/provider/core/sticker_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 表情包列表 Provider
///
/// 拉取所有启用中的表情包（含包内表情）。
/// 失败时进入 [AsyncError] 状态，由 UI 层提供重试入口。
final stickerPacksProvider = FutureProvider<List<StickerPack>>((ref) async {
  return ref.watch(stickerRepositoryProvider).fetchPacks();
});
