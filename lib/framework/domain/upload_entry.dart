/// 文件上传状态枚举
enum UploadStatus { uploading, success, failed }

/// 文件上传条目
///
/// 表示单个文件的上传结果，包含状态和成功后的服务器 URL。
class UploadEntry {
  /// 当前上传状态
  final UploadStatus status;

  /// 服务器返回的文件访问地址（仅 [status] 为 [UploadStatus.success] 时有值）
  final String? serverUrl;

  const UploadEntry({required this.status, this.serverUrl});

  /// 上传中状态的常量实例
  static const uploading = UploadEntry(status: UploadStatus.uploading);

  /// 上传失败状态的常量实例
  static const failed = UploadEntry(status: UploadStatus.failed);

  /// 创建一个表示上传成功的实例
  static UploadEntry success(String url) =>
      UploadEntry(status: UploadStatus.success, serverUrl: url);

  /// 是否处于上传中
  bool get isUploading => status == UploadStatus.uploading;

  /// 是否上传成功
  bool get isSuccess => status == UploadStatus.success;

  /// 是否上传失败
  bool get isFailed => status == UploadStatus.failed;
}
