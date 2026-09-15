/// 已校验的更新下载目标。
class UpdateDownloadTarget {
  final Uri uri;
  final String fileName;

  const UpdateDownloadTarget({required this.uri, required this.fileName});

  factory UpdateDownloadTarget.parse(
    String rawUrl, {
    String fallbackExtension = 'bin',
  }) {
    final uri = Uri.tryParse(rawUrl.trim());
    final scheme = uri?.scheme.toLowerCase();
    if (uri == null ||
        (scheme != 'http' && scheme != 'https') ||
        uri.host.isEmpty) {
      throw const FormatException('invalid update download url');
    }

    final pathName = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    final decodedName = pathName.isEmpty ? '' : Uri.decodeComponent(pathName);
    final safeName = _sanitizeFileName(decodedName);
    final safeExtension = fallbackExtension.replaceAll(
      RegExp('[^A-Za-z0-9]'),
      '',
    );

    return UpdateDownloadTarget(
      uri: uri,
      fileName: safeName.isEmpty
          ? 'Anoxia-update.${safeExtension.isEmpty ? 'bin' : safeExtension}'
          : safeName,
    );
  }

  static String _sanitizeFileName(String value) {
    var result = value
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'[. ]+$'), '')
        .trim();
    if (result.length > 180) {
      result = result.substring(result.length - 180);
    }
    final stem = result.split('.').first.toUpperCase();
    const reserved = {
      'CON',
      'PRN',
      'AUX',
      'NUL',
      'COM1',
      'COM2',
      'COM3',
      'COM4',
      'COM5',
      'COM6',
      'COM7',
      'COM8',
      'COM9',
      'LPT1',
      'LPT2',
      'LPT3',
      'LPT4',
      'LPT5',
      'LPT6',
      'LPT7',
      'LPT8',
      'LPT9',
    };
    if (reserved.contains(stem)) result = '_$result';
    return result;
  }
}
