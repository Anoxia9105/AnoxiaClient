/// 读取图片宽高
///
/// 发送链路此前为了拿宽高会把整个文件读进内存再 `instantiateImageCodec`
/// **完整解码首帧**，多图串行时直接拖慢"选完到发出"的耗时。这里先走
/// 只解析文件头的快路径（[ui.ImageDescriptor.encoded]），失败再退回整帧
/// 解码，兼顾速度与兼容性。
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// 从字节读取宽高，无法解析时返回 `(null, null)`
Future<(int?, int?)> readImageSizeFromBytes(Uint8List bytes) async {
  if (bytes.isEmpty) return (null, null);
  final headerSize = await _readSizeFromHeader(bytes);
  if (headerSize.$1 != null && headerSize.$2 != null) return headerSize;
  return _readSizeByDecoding(bytes);
}

/// 从本地文件读取宽高，无法解析时返回 `(null, null)`
Future<(int?, int?)> readImageSizeFromFile(String path) async {
  try {
    return await readImageSizeFromBytes(await File(path).readAsBytes());
  } catch (_) {
    return (null, null);
  }
}

/// 只解析图片文件头（不解码像素）
Future<(int?, int?)> _readSizeFromHeader(Uint8List bytes) async {
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    if (descriptor.width <= 0 || descriptor.height <= 0) return (null, null);
    return (descriptor.width, descriptor.height);
  } catch (_) {
    return (null, null);
  } finally {
    descriptor?.dispose();
    buffer?.dispose();
  }
}

/// 兜底：整帧解码取宽高（Web 上 `ImageDescriptor` 不可用时走这里）
Future<(int?, int?)> _readSizeByDecoding(Uint8List bytes) async {
  ui.Codec? codec;
  ui.Image? image;
  try {
    codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    image = frame.image;
    return (image.width, image.height);
  } catch (_) {
    return (null, null);
  } finally {
    image?.dispose();
    codec?.dispose();
  }
}
