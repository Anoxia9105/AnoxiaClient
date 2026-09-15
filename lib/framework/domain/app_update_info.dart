/// 应用更新信息数据模型
///
/// 封装应用版本更新相关信息，支持强制更新和最低版本检查。
///
/// [hasUpdate] 是否有新版本可用
/// [latestVersion] 最新版本号
/// [currentVersion] 当前版本号
/// [downloadUrl] 安装包下载地址
/// [releaseNotes] 更新说明/发行日志
/// [forceUpdate] 是否强制更新（用户无法跳过）
/// [minSupportVersion] 最低支持版本，低于此版本的客户端将强制更新
/// [fileSize] 安装包字节数（服务端上传时计算，用于下载完整性校验）
/// [fileHash] 安装包 SHA-256（十六进制，服务端上传时计算，用于下载完整性校验）
class AppUpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final String currentVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;
  final String minSupportVersion;
  final int fileSize;
  final String fileHash;

  const AppUpdateInfo({
    this.hasUpdate = false,
    required this.latestVersion,
    this.currentVersion = '',
    required this.downloadUrl,
    required this.releaseNotes,
    this.forceUpdate = false,
    this.minSupportVersion = '',
    this.fileSize = 0,
    this.fileHash = '',
  });

  /// 从 JSON 解析更新信息
  ///
  /// 支持两种字段命名风格：驼峰式（hasUpdate）和下划线式（has_update）
  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    final forceRaw = json['forceUpdate'] ?? json['force_update'];
    final hasUpdateRaw = json['hasUpdate'] ?? json['has_update'];
    return AppUpdateInfo(
      hasUpdate: _parseBool(hasUpdateRaw),
      latestVersion: (json['latestVersion'] ?? json['latest_version'] ?? '')
          .toString(),
      currentVersion: (json['currentVersion'] ?? '').toString(),
      downloadUrl: (json['downloadUrl'] ?? json['download_url'] ?? '')
          .toString(),
      releaseNotes: (json['releaseNotes'] ?? json['release_notes'] ?? '')
          .toString(),
      forceUpdate: _parseBool(forceRaw),
      minSupportVersion:
          (json['minSupportVersion'] ?? json['min_support_version'] ?? '')
              .toString(),
      fileSize: _parseInt(json['fileSize'] ?? json['file_size']),
      fileHash: (json['fileHash'] ?? json['file_hash'] ?? '').toString().trim(),
    );
  }

  static bool _parseBool(Object? value) {
    if (value == true || value == 1) return true;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  static int _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }
}
