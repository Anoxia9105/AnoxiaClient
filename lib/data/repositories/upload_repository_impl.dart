import 'package:anoxia/domain/repositories/upload_repository.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:cross_file/cross_file.dart';

/// 文件上传仓库实现
///
/// 通过远程数据源（HTTP API）提供文件上传操作。
/// 实现 [UploadRepository] 抽象接口，供 UI 层 Provider 使用。
class UploadRepositoryImpl implements UploadRepository {
  @override
  Future<List<String>> uploadFiles(List<XFile> files) async {
    try {
      final fileNames = files.map((f) => f.name).join(', ');
      debugLog('[Upload] uploadFiles 开始上传: $fileNames');

      final res = await DioClient().uploadFiles(
        '/file/uploadBatch',
        files: files,
      );

      final rawList = res.data is Map ? res.data['data'] : res.data;
      if (rawList is! List) {
        debugLog('[Upload] uploadFiles: 服务器返回空/无效响应 -> ${res.data}');
        return [];
      }

      final urls = rawList.map((e) => e.toString()).toList();
      debugLog('[Upload] uploadFiles 上传成功: ${urls.length} 个文件');
      return urls;
    } catch (e, st) {
      debugLog('[Upload] uploadFiles 上传异常: $e', st);
      return [];
    }
  }
}
