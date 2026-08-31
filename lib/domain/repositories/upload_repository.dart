import 'package:anoxia/domain/models/upload_file_result.dart';
import 'package:cross_file/cross_file.dart';

typedef UploadProgressCallback =
    void Function(String clientFileId, int sent, int total);
typedef UploadCompletedCallback = void Function(UploadFileResult result);

/// 文件上传仓库抽象接口
///
/// 定义文件上传相关的数据操作契约。
/// 数据层通过实现此接口提供具体实现，UI 层 Provider 仅依赖此接口。
abstract interface class UploadRepository {
  /// 批量上传文件
  ///
  /// [files] 要上传的文件列表（全平台兼容，Web 端使用 XFile.fromData 传 bytes）
  ///
  /// 返回与 [clientFileIds] 一一对应的逐文件结果。
  ///
  /// 实现最多并发上传两个文件；单个失败不会改变其他文件的关联关系。
  Future<List<UploadFileResult>> uploadFiles(
    List<XFile> files, {
    required List<String> clientFileIds,
    UploadProgressCallback? onProgress,
    UploadCompletedCallback? onCompleted,
    int? noteId,
  });

  /// 取消指定客户端文件 ID 对应的在途上传。
  void cancelUpload(String clientFileId);
}
