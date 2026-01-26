class AppUpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate; // 是否强制更新

  AppUpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    this.forceUpdate = false,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      latestVersion: json['latest_version'],
      downloadUrl: json['download_url'],
      releaseNotes: json['release_notes'],
      forceUpdate: json['force_update'] ?? false,
    );
  }
}
