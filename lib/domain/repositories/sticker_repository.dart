import 'package:anoxia/framework/domain/sticker_pack.dart';

/// 表情包仓库抽象接口
///
/// 定义表情包数据的获取契约。
/// 数据层通过实现此接口提供具体实现，UI 层 Provider 仅依赖此接口。
abstract interface class StickerRepository {
  /// 获取所有启用中的表情包（含包内表情）
  ///
  /// 返回按服务端排序的表情包列表，可能为空列表。
  /// 服务端会合并全局表情包与当前用户自定义表情包。
  Future<List<StickerPack>> fetchPacks();

  /// 创建用户自定义表情包
  ///
  /// 返回新创建的包ID；失败返回 0。
  Future<int> createCustomPack(String name, {String? iconUrl});

  /// 向用户自定义表情包新增表情
  ///
  /// [packId] 目标表情包ID（必须属于当前用户），上传成功后返回图片 URL 及宽高。
  Future<bool> addCustomSticker(
    int packId,
    String imageUrl, {
    int? width,
    int? height,
  });

  /// 删除用户自定义表情包（级联删除包内表情）
  Future<bool> deleteCustomPack(int packId);

  /// 删除用户自定义表情包内的单个表情
  Future<bool> deleteCustomSticker(int stickerId);
}
