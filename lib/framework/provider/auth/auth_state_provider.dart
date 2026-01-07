import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_state_provider.g.dart';

/// 登录状态枚举
enum AuthStatus {
  authenticated,
  unauthenticated,
}

/// Riverpod 状态管理
@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {

  @override
  AuthStatus build() {
    return AuthStatus.unauthenticated;
  }

  void login() {
    state = AuthStatus.authenticated;
  }

  void logout() {
    state = AuthStatus.unauthenticated;
  }
}
