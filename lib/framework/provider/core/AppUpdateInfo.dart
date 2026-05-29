/// 应用更新信息数据模型
///
/// 封装应用版本更新相关信息，支持强制更新和最低版本检查。
/// 
/// [hasUpdate] 是否有新版本可用
/// [latestVersion] 最新版本号
/// [downloadUrl] 安装包下载地址
/// [releaseNotes] 更新说明/发行日志
/// [forceUpdate] 是否强制更新（用户无法跳过）
/// [minSupportVersion] 最低支持版本，低于此版本的客户端将强制更新
class AppUpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;
  final String minSupportVersion;

  AppUpdateInfo({
    this.hasUpdate = false,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    this.forceUpdate = false,
    this.minSupportVersion = '',
  });

  /// 从 JSON 解析更新信息
  ///
  /// 支持两种字段命名风格：驼峰式（hasUpdate）和下划线式（has_update）
  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    final forceRaw = json['forceUpdate'] ?? json['force_update'];
    return AppUpdateInfo(
      hasUpdate: json['hasUpdate'] == true,
      latestVersion: (json['latestVersion'] ?? json['latest_version'] ?? '')
          .toString(),
      downloadUrl: (json['downloadUrl'] ?? json['download_url'] ?? '')
          .toString(),
      releaseNotes: (json['releaseNotes'] ?? json['release_notes'] ?? '')
          .toString(),
      forceUpdate: forceRaw == true || forceRaw == 1,
      minSupportVersion:
          (json['minSupportVersion'] ?? json['min_support_version'] ?? '')
              .toString(),
    );
  }
}

