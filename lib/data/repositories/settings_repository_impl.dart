import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/domain/repositories/settings_repository.dart';
import 'package:anoxia/framework/domain/app_update_info.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:dio/dio.dart';

/// 设置仓库实现
///
/// 通过远程数据源（HTTP API）提供设置相关操作。
/// 实现 [SettingsRepository] 抽象接口，供 UI 层 Provider 使用。
class SettingsRepositoryImpl implements SettingsRepository {
  @override
  Future<FeedbackSubmitResult> submitFeedback({
    required String title,
    required String content,
    required String contact,
    required String clientType,
    required String appVersion,
    List<FeedbackImageAttachment> images = const [],
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        'content': content,
        'contact': contact,
        'clientType': clientType,
        'appVersion': appVersion,
        if (images.isNotEmpty)
          'files': images
              .map(
                (image) =>
                    MultipartFile.fromBytes(image.bytes, filename: image.name),
              )
              .toList(),
      });
      final res = await DioClient().post(
        API.feedbackSubmitWithImages,
        data: formData,
      );

      final ok = res.data is Map && res.data['code'] == 200;
      final msg = res.data is Map ? res.data['msg']?.toString() : null;
      return FeedbackSubmitResult(success: ok, message: msg);
    } catch (_) {
      return const FeedbackSubmitResult(success: false);
    }
  }

  @override
  Future<AppUpdateInfo> checkForUpdate({
    required String currentVersion,
    required String clientType,
  }) async {
    final res = await DioClient().get(
      API.appUpdateLatest,
      auth: false,
      queryParameters: {
        'currentVersion': currentVersion,
        'clientType': clientType,
      },
    );

    final payload = res.data;
    if (payload is! Map) {
      throw Exception('invalid update response');
    }
    if (payload['code'] != 200) {
      throw Exception(payload['msg']?.toString() ?? 'update check failed');
    }

    final data = payload['data'];
    if (data is! Map) {
      return AppUpdateInfo(
        hasUpdate: false,
        forceUpdate: false,
        latestVersion: '',
        currentVersion: currentVersion,
        downloadUrl: '',
        releaseNotes: '',
        minSupportVersion: '',
      );
    }

    return AppUpdateInfo(
      hasUpdate: data['hasUpdate'] == true,
      forceUpdate: data['forceUpdate'] == true,
      latestVersion: (data['latestVersion'] ?? '').toString(),
      currentVersion: (data['currentVersion'] ?? currentVersion).toString(),
      downloadUrl: (data['downloadUrl'] ?? '').toString(),
      releaseNotes: (data['releaseNotes'] ?? '').toString(),
      minSupportVersion: (data['minSupportVersion'] ?? '').toString(),
    );
  }
}
