import 'package:anoxia/common/utils/media_mime_type.dart';

/// 文件选择器选中项的媒体分类
///
/// 发送链路的唯一判据：消息类型（`MessageType`）、附件 `kind`、
/// 是否需要读取图片宽高/视频元数据，全部由它派生。
enum PickedMediaKind { image, video, file }

/// 判定选中文件的媒体类型
///
/// 判定优先级：**声明 mime → 文件名后缀 → 兜底为文件**。
/// [declaredType] 只在调用方确实拿到了 mime 时传（如 `FilePicker` 的
/// `PlatformFile` 不带 mime，`XFile` 带），否则留空由 [name] 的后缀推导。
///
/// 兜底永远走 `file`，不猜：宁可让用户看到文件卡片，也不要发出一个
/// 渲染必然失败的图片消息。
PickedMediaKind resolvePickedMediaKind({
  String? name,
  String? extension,
  String? declaredType,
}) {
  final mime = pickedMimeType(
    name: name,
    extension: extension,
    declaredType: declaredType,
  );
  if (mime.startsWith('video/')) return PickedMediaKind.video;
  if (mime.startsWith('image/') && !isNonRenderableImageMime(mime)) {
    return PickedMediaKind.image;
  }
  return PickedMediaKind.file;
}

/// 归一化选中文件的 MIME 类型
///
/// [extension] 仅在 [name] 缺失或无后缀时作为补充（`ImagePicker` 返回的
/// `XFile` 只有 path，调用方已取出 basename，一般不会走到这条路）。
String pickedMimeType({String? name, String? extension, String? declaredType}) {
  final trimmedName = name?.trim() ?? '';
  final hasExtension = _extensionOf(trimmedName).isNotEmpty;
  final fallbackName = hasExtension
      ? trimmedName
      : (extension?.trim().isNotEmpty == true
            ? 'picked.${extension!.trim()}'
            : trimmedName);
  return mediaMimeTypeForName(fallbackName, declaredType: declaredType);
}

/// Flutter 没有内建解码能力的图片格式
///
/// 按图片消息发出去只会得到渲染失败的破图，一律归为文件。
/// - `image/svg+xml`：矢量格式，需要额外的 svg 渲染库
/// - `image/tiff` / `image/avif`：移动端与 Web 的解码支持都不完整
const Set<String> nonRenderableImageMimes = {
  'image/svg+xml',
  'image/tiff',
  'image/avif',
};

/// 该 mime 是否属于「不能直接当图片渲染」的格式
bool isNonRenderableImageMime(String mime) =>
    nonRenderableImageMimes.contains(mime.trim().toLowerCase());

String _extensionOf(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot < 0 || dot >= fileName.length - 1) return '';
  return fileName.substring(dot + 1).toLowerCase();
}
