import 'dart:typed_data';
import 'dart:ui' as ui;

/// 头像只接受静态位图，按内容校验，避免改扩展名绕过选择器。
bool isStaticAvatarImage(Uint8List bytes) {
  bool matches(int offset, List<int> signature) {
    if (bytes.length < offset + signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[offset + i] != signature[i]) return false;
    }
    return true;
  }

  if (matches(0, [0xff, 0xd8, 0xff]) || matches(0, [0x42, 0x4d])) {
    return true;
  }
  final data = ByteData.sublistView(bytes);
  if (matches(0, [137, 80, 78, 71, 13, 10, 26, 10])) {
    var offset = 8;
    while (offset + 12 <= bytes.length) {
      final length = data.getUint32(offset);
      if (offset + length + 12 > bytes.length) return false;
      if (matches(offset + 4, [97, 99, 84, 76])) return false; // APNG acTL
      if (matches(offset + 4, [73, 69, 78, 68])) return true;
      offset += length + 12;
    }
    return false;
  }
  if (matches(0, [82, 73, 70, 70]) && matches(8, [87, 69, 66, 80])) {
    var offset = 12;
    while (offset + 8 <= bytes.length) {
      final length = data.getUint32(offset + 4, Endian.little);
      if (offset + length + 8 > bytes.length) return false;
      if (matches(offset, [65, 78, 73, 77]) ||
          matches(offset, [65, 78, 77, 70])) {
        return false;
      }
      if (matches(offset, [86, 80, 56, 88]) &&
          length > 0 &&
          bytes[offset + 8] & 2 != 0) {
        return false;
      }
      offset += 8 + length + (length & 1);
    }
    return offset == bytes.length;
  }
  return false;
}

Future<ui.Image> decodeStaticAvatarImage(
  Uint8List bytes, {
  int maxSide = 2048,
}) async {
  if (!isStaticAvatarImage(bytes)) {
    throw const FormatException('static avatar required');
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final codec = await ui.instantiateImageCodecWithSize(
    buffer,
    getTargetSize: (width, height) {
      if (width <= maxSide && height <= maxSide) {
        return const ui.TargetImageSize();
      }
      return width >= height
          ? ui.TargetImageSize(width: maxSide)
          : ui.TargetImageSize(height: maxSide);
    },
  );
  try {
    if (codec.frameCount != 1) {
      throw const FormatException('static avatar required');
    }
    return (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
  }
}
