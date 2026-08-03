import 'package:anoxia/data/repositories/upload_repository_impl.dart';
import 'package:anoxia/domain/repositories/upload_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 文件上传仓库 Provider
///
/// 提供 [UploadRepository] 接口的实现，供 UI 层 Provider 使用。
final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  return UploadRepositoryImpl();
});
