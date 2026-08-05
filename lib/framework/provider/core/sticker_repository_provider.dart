import 'package:anoxia/data/repositories/sticker_repository_impl.dart';
import 'package:anoxia/domain/repositories/sticker_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 表情包仓库 Provider
///
/// 提供 [StickerRepository] 接口的实现，供 UI 层 Provider 使用。
final stickerRepositoryProvider = Provider<StickerRepository>((ref) {
  return StickerRepositoryImpl();
});
