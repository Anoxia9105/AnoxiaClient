class AppUpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;
  final String minSupportVersion; // 最低支持版本，低于此版本强制更新

  AppUpdateInfo({
    this.hasUpdate = false,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    this.forceUpdate = false,
    this.minSupportVersion = '',
  });

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

