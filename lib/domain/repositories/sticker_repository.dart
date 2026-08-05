import 'package:anoxia/framework/domain/sticker_pack.dart';

/// 表情包仓库抽象接口
///
/// 定义表情包数据的获取契约。
/// 数据层通过实现此接口提供具体实现，UI 层 Provider 仅依赖此接口。
abstract interface class StickerRepository {
  /// 获取所有启用中的表情包（含包内表情）
  ///
  /// 返回按服务端排序的表情包列表，可能为空列表。
  Future<List<StickerPack>> fetchPacks();
}
