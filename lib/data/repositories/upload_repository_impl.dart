import 'package:anoxia/domain/repositories/upload_repository.dart';
import 'package:anoxia/framework/logs/talker.dart';
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
      final res = await DioClient().uploadFiles(
        '/file/uploadBatch',
        files: files,
      );

      final rawList = res.data is Map ? res.data['data'] : res.data;
      if (rawList is! List) {
        log.warning('[Upload] uploadFiles: empty/invalid response');
        return [];
      }
      return rawList.map((e) => e.toString()).toList();
    } catch (e, st) {
      log.error('[Upload] uploadFiles failed', e, st);
      return [];
    }
  }
}
