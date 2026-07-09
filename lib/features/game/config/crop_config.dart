import 'package:anoxia/features/game/config/crop_type_enum.dart';

class CropConfig {
  final CropType type;
  final String name;
  final int seedPrice;
  final int sellPrice;
  final double growSeconds; // 从种下到成熟要多久
  final double? witherSeconds; // 成熟后多久不收会枯萎，null=不会枯萎
  final int ripeFrameIndex; // 第几帧算“成熟”（0-indexed）
  final String iconPath; // 给 Flutter UI 用的图标路径（相对 assets/images/）

  // 生长动画是雪碧图（一张图横向拼了 N 帧），不是分开的文件
  final String spriteSheetPath; // 相对 assets/images/
  final int frameWidth; // 单帧宽度（像素）
  final int frameHeight; // 单帧高度（像素）
  final int frameCount; // 一共几帧

  const CropConfig({
    required this.type,
    required this.name,
    required this.seedPrice,
    required this.sellPrice,
    required this.growSeconds,
    required this.witherSeconds,
    required this.ripeFrameIndex,
    required this.iconPath,
    required this.spriteSheetPath,
    required this.frameWidth,
    required this.frameHeight,
    required this.frameCount,
  });

  /// 按你的素材目录结构（crops/<folder>/growth_basic/<sheetFileName>）生成配置。
  /// 命名规律是 corn_16x32_8frames.png 这种：作物名_单帧宽x单帧高_帧数frames.png
  /// 玉米已确认是 16x32、8帧；其余作物的雪碧图尺寸/帧数很可能不一样，
  /// 用之前必须去对应文件夹里核实文件名，改 sheetFileName / frameWidth / frameHeight / frameCount
  static CropConfig basic({
    required CropType type,
    required String assetFolder,
    required String sheetFileName,
    required String name,
    required int seedPrice,
    required int sellPrice,
    required double growSeconds,
    required int frameWidth,
    required int frameHeight,
    int frameCount = 8,
    double? witherSeconds = 15,
    String iconFile = 'icon.png',
  }) {
    return CropConfig(
      type: type,
      name: name,
      seedPrice: seedPrice,
      sellPrice: sellPrice,
      growSeconds: growSeconds,
      witherSeconds: witherSeconds,
      ripeFrameIndex: frameCount - 2, // 倒数第二帧=成熟，最后一帧留给“枯萎”
      iconPath: 'crops/$assetFolder/icon/$iconFile',
      spriteSheetPath: 'crops/$assetFolder/growth_basic/$sheetFileName',
      frameWidth: frameWidth,
      frameHeight: frameHeight,
      frameCount: frameCount,
    );
  }
}
