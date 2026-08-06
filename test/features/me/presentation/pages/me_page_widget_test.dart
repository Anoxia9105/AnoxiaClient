import 'package:anoxia/framework/domain/user_info.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/features/me/presentation/pages/me_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthController extends AuthController {
  final UserInfo? _user;

  _FakeAuthController(this._user);

  @override
  Future<UserInfo?> build() async => _user;
}

void main() {
  final user = UserInfo(
    userId: 42,
    userName: 'test_user',
    nickName: '测试用户',
    email: '',
    phoneNumber: '',
    sex: '2',
    avatar: '',
  );

  testWidgets('avatar camera badge and tile leading icon render', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _FakeAuthController(user)),
        ],
        child: const MaterialApp(home: MyPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
    expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
