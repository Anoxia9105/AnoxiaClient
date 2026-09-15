import 'package:anoxia/features/update/domain/update_download_target.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpdateDownloadTarget', () {
    test('从带查询参数的 HTTPS 地址提取安全文件名', () {
      final target = UpdateDownloadTarget.parse(
        'https://downloads.anoxia.cn/releases/Anoxia-windows-2.3.5.exe?token=abc',
      );

      expect(target.uri.scheme, 'https');
      expect(target.fileName, 'Anoxia-windows-2.3.5.exe');
    });

    test('下载地址没有文件名时使用平台回退名', () {
      final target = UpdateDownloadTarget.parse(
        'https://downloads.anoxia.cn/releases/',
        fallbackExtension: 'exe',
      );

      expect(target.fileName, 'Anoxia-update.exe');
    });

    test('拒绝非 HTTP 协议和缺少主机的地址', () {
      expect(
        () => UpdateDownloadTarget.parse('javascript:alert(1)'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => UpdateDownloadTarget.parse('/relative/update.exe'),
        throwsA(isA<FormatException>()),
      );
    });

    test('清理 Windows 文件名中的保留字符', () {
      final target = UpdateDownloadTarget.parse(
        'https://downloads.anoxia.cn/releases/setup%3A2.3.5.exe',
      );

      expect(target.fileName, 'setup_2.3.5.exe');
    });
  });
}
