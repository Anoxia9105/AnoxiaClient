import 'package:anoxia/framework/domain/saved_account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('快速登录凭据和游客类型可以持久化往返', () {
    final account = SavedAccount(
      userId: 7,
      userName: 'guest_a3f8',
      nickName: '游客_A3F8',
      avatar: '',
      token: 'access-token',
      quickLoginCredential: 'device-credential',
      userType: '02',
      lastUsedAt: DateTime.utc(2026, 9, 24),
    );

    final restored = SavedAccount.fromJson(account.toJson());

    expect(restored.userId, 7);
    expect(restored.userType, '02');
    expect(restored.quickLoginCredential, 'device-credential');
  });

  test('旧版保存账号缺少新字段时安全降级', () {
    final restored = SavedAccount.fromJson({
      'userId': 1,
      'userName': 'normal',
      'nickName': 'Normal',
      'avatar': '',
      'token': 'token',
      'lastUsedAt': '2026-09-24T00:00:00.000Z',
    });

    expect(restored.userType, '01');
    expect(restored.quickLoginCredential, isEmpty);
  });
}
