import 'package:anoxia/framework/domain/app_update_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('兼容下划线字段和常见布尔值编码', () {
    final info = AppUpdateInfo.fromJson({
      'has_update': 1,
      'latest_version': '2.4.0',
      'download_url': 'https://downloads.anoxia.cn/app.exe',
      'release_notes': '稳定性更新',
      'force_update': 'true',
      'min_support_version': '2.3.0',
    });

    expect(info.hasUpdate, isTrue);
    expect(info.forceUpdate, isTrue);
    expect(info.latestVersion, '2.4.0');
    expect(info.minSupportVersion, '2.3.0');
  });

  test('未知布尔值安全回退为 false', () {
    final info = AppUpdateInfo.fromJson({
      'hasUpdate': 'unexpected',
      'latestVersion': '2.4.0',
      'downloadUrl': 'https://downloads.anoxia.cn/app.exe',
      'releaseNotes': '',
      'forceUpdate': null,
    });

    expect(info.hasUpdate, isFalse);
    expect(info.forceUpdate, isFalse);
  });
}
