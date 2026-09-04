import 'package:anoxia/framework/core/device_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WS 连接设备标识（上下线事件根因回归）', () {
    test('不同连接后缀组装出不同的设备标识（模拟两个 Web 标签页）', () {
      const stable = 'web:11111111-2222-4333-8444-555555555555';
      final first = DeviceIdentity.buildWsConnectionDeviceId(
        stable,
        'aaaaaaaa',
      );
      final second = DeviceIdentity.buildWsConnectionDeviceId(
        stable,
        'bbbbbbbb',
      );

      expect(first, isNot(second));
      expect(first.startsWith('$stable:'), isTrue);
      expect(second.startsWith('$stable:'), isTrue);
    });

    test('组装结果符合服务端 deviceId 规范（8~128 位）', () {
      const stable = 'web:11111111-2222-4333-8444-555555555555';
      final id = DeviceIdentity.buildWsConnectionDeviceId(stable, 'a1b2c3d4');

      expect(id.length, greaterThanOrEqualTo(8));
      expect(id.length, lessThanOrEqualTo(128));
      expect(DeviceIdentity.wsDeviceIdPattern.hasMatch(id), isTrue);
    });

    test('同页内连接后缀稳定（避免重连抖动）', () {
      final first = DeviceIdentity.instance.wsConnectionSuffix();
      final second = DeviceIdentity.instance.wsConnectionSuffix();

      expect(first, second);
      expect(first.length, DeviceIdentity.wsConnectionSuffixLength);
      expect(RegExp(r'^[A-Za-z0-9]+$').hasMatch(first), isTrue);
    });
  });
}
