enum UploadStatus { uploading, success, failed }

class UploadEntry {
  final UploadStatus status;
  final String? serverUrl; // 仅 success 时有值

  const UploadEntry({required this.status, this.serverUrl});

  static const uploading = UploadEntry(status: UploadStatus.uploading);
  static const failed = UploadEntry(status: UploadStatus.failed);
  static UploadEntry success(String url) =>
      UploadEntry(status: UploadStatus.success, serverUrl: url);

  bool get isUploading => status == UploadStatus.uploading;
  bool get isSuccess => status == UploadStatus.success;
  bool get isFailed => status == UploadStatus.failed;
}