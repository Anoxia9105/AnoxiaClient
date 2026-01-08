import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_state_provider.g.dart';

/// 登录状态枚举
enum AuthStatus {
  initial, //初始化/检查中
  authenticated,
  unauthenticated,
}

/// Riverpod 状态管理
@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {

  @override
  AuthStatus build() {
    return AuthStatus.initial;
  }

  void login() {
    state = AuthStatus.authenticated;
  }

  void logout() {
    state = AuthStatus.unauthenticated;
  }
}
