import 'package:cross_file/cross_file.dart';

/// 文件上传仓库抽象接口
///
/// 定义文件上传相关的数据操作契约。
/// 数据层通过实现此接口提供具体实现，UI 层 Provider 仅依赖此接口。
abstract interface class UploadRepository {
  /// 批量上传文件
  ///
  /// [files] 要上传的文件列表（全平台兼容，Web 端使用 XFile.fromData 传 bytes）
  ///
  /// 返回上传成功后的文件 URL 列表；响应异常时返回空列表。
  Future<List<String>> uploadFiles(List<XFile> files);
}
