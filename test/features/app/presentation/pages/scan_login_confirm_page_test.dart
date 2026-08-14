import 'package:anoxia/features/app/presentation/pages/scan_login_confirm_page.dart';
import 'package:anoxia/framework/domain/user_info.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

class _FakeAuthController extends AuthController {
  @override
  Future<UserInfo?> build() async => null;
}

void main() {
  testWidgets('扫码登录确认页使用紧凑的电脑图标', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuthController.new),
        ],
        child: const MaterialApp(
          home: ScanLoginConfirmPage(ticket: 'test-ticket'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final iconBox = find.byKey(const ValueKey('scan-login-computer-icon-box'));
    expect(tester.getSize(iconBox), const Size.square(40));

    final icon = tester.widget<HugeIcon>(
      find.descendant(of: iconBox, matching: find.byType(HugeIcon)),
    );
    expect(icon.size, 40);
    expect(tester.takeException(), isNull);
  });
}
