import 'package:anoxia/data/repositories/settings_repository_impl.dart';
import 'package:anoxia/domain/repositories/settings_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

// AppUpdateInfo is re-exported from domain/app_update_info.dart
export 'package:anoxia/framework/domain/app_update_info.dart' show AppUpdateInfo;

// FeedbackSubmitResult / SettingsRepository are re-exported from domain layer
export 'package:anoxia/domain/repositories/settings_repository.dart'
    show FeedbackSubmitResult, SettingsRepository;

/// 获取应用版本号
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  final version = info.version.trim();
  final buildNumber = info.buildNumber.trim();
  if (buildNumber.isEmpty) return version;
  return '$version+$buildNumber';
});

/// 设置仓库层 Provider
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(),
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
