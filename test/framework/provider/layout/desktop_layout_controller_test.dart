import 'package:anoxia/framework/provider/layout/desktop_layout_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DesktopLayoutPreference', () {
    test('未知的持久化值回退为自动布局', () {
      expect(
        parseDesktopLayoutPreference('unknown'),
        DesktopLayoutPreference.automatic,
      );
    });

    test('可以解析卡片和平铺布局', () {
      expect(
        parseDesktopLayoutPreference('card'),
        DesktopLayoutPreference.card,
      );
      expect(
        parseDesktopLayoutPreference('flat'),
        DesktopLayoutPreference.flat,
      );
    });
  });

  group('resolveDesktopLayoutStyle', () {
    test('自动布局在宽屏使用卡片模式', () {
      expect(
        resolveDesktopLayoutStyle(
          DesktopLayoutPreference.automatic,
          availableWidth: desktopCardLayoutBreakpoint,
        ),
        DesktopLayoutStyle.card,
      );
    });

    test('自动布局在较窄窗口使用平铺模式', () {
      expect(
        resolveDesktopLayoutStyle(
          DesktopLayoutPreference.automatic,
          availableWidth: desktopCardLayoutBreakpoint - 1,
        ),
        DesktopLayoutStyle.flat,
      );
    });

    test('手动选择不会被窗口宽度覆盖', () {
      expect(
        resolveDesktopLayoutStyle(
          DesktopLayoutPreference.card,
          availableWidth: 1024,
        ),
        DesktopLayoutStyle.card,
      );
      expect(
        resolveDesktopLayoutStyle(
          DesktopLayoutPreference.flat,
          availableWidth: 1920,
        ),
        DesktopLayoutStyle.flat,
      );
    });
  });
}
