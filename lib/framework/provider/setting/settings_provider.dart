import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 反馈提交结果
class FeedbackSubmitResult {
  /// 是否提交成功
  final bool success;

  /// 结果消息
  final String? message;

  const FeedbackSubmitResult({required this.success, this.message});
}

/// 应用更新信息
class AppUpdateInfo {
  /// 是否有可用更新
  final bool hasUpdate;

  /// 是否为强制更新
  final bool forceUpdate;

  /// 最新版本号
  final String latestVersion;

  /// 当前版本号
  final String currentVersion;

  /// 下载链接
  final String downloadUrl;

  /// 更新日志
  final String releaseNotes;

  /// 最低支持版本
  final String minSupportVersion;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.forceUpdate,
    required this.latestVersion,
    required this.currentVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.minSupportVersion,
  });
}

/// 设置仓储层
///
/// 封装设置相关的网络请求，包括反馈提交和应用更新检查。
class SettingsRepository {
  /// 提交用户反馈
  Future<FeedbackSubmitResult> submitFeedback({
    required String title,
    required String content,
    required String contact,
    required String clientType,
    required String appVersion,
  }) async {
    try {
      final res = await DioClient().post(
        API.feedbackSubmit,
        data: {
          'title': title,
          'content': content,
          'contact': contact,
          'clientType': clientType,
          'appVersion': appVersion,
        },
      );

      final ok = res.data is Map && res.data['code'] == 200;
      final msg = res.data is Map ? res.data['msg']?.toString() : null;
      return FeedbackSubmitResult(success: ok, message: msg);
    } catch (_) {
      return const FeedbackSubmitResult(success: false);
    }
  }

  /// 检查应用更新
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

/// 获取应用版本号
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  final version = info.version.trim();
  final buildNumber = info.buildNumber.trim();
  if (buildNumber.isEmpty) return version;
  return '$version+$buildNumber';
});

/// 设置仓储层 Provider
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(),
);

/// 解析客户端类型标识
///
/// 根据当前运行平台返回对应的类型字符串
String resolveUpdateClientType() {
  if (kIsWeb) return 'web';
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'android';
    case TargetPlatform.iOS:
      return 'ios';
    case TargetPlatform.windows:
      return 'windows';
    case TargetPlatform.macOS:
      return 'macos';
    case TargetPlatform.linux:
      return 'linux';
    default:
      return 'all';
  }
}
