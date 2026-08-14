/// 单个文件的上传结果，以客户端文件 ID 作为稳定关联键。
class UploadFileResult {
  const UploadFileResult({
    required this.clientFileId,
    required this.isSuccess,
    this.url,
    this.errorCode,
  });

  final String clientFileId;
  final bool isSuccess;
  final String? url;
  final String? errorCode;
}
