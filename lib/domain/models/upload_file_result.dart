/// 单个文件的上传结果，以客户端文件 ID 作为稳定关联键。
class UploadFileResult {
  const UploadFileResult({
    required this.clientFileId,
    required this.isSuccess,
    this.url,
    this.coverUrl,
    this.coverSizeBytes,
    this.durationMs,
    this.width,
    this.height,
    this.bitrate,
    this.errorCode,
  });

  final String clientFileId;
  final bool isSuccess;
  final String? url;
  final String? coverUrl;
  final int? coverSizeBytes;
  final int? durationMs;
  final int? width;
  final int? height;
  final int? bitrate;
  final String? errorCode;
}
