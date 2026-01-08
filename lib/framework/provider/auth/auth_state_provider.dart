import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_state_provider.g.dart';

/// 登录状态枚举
enum AuthStatus {
  initial, //初始化/检查中
  authenticated,
  unauthenticated,
  error,//登录出错
}

/// Riverpod 状态管理
@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {

  @override
  AuthStateData build() {
    return AuthStateData.initial();
  }

  void login() {
    state = AuthStateData(status: AuthStatus.authenticated);
  }

  void logout() {
    state = AuthStateData(status: AuthStatus.unauthenticated);
  }

  void setError(String message) {
    state = AuthStateData(
      status: AuthStatus.error,
      errorMessage: message,
    );
  }
}

class AuthStateData {
  final AuthStatus status;
  final String? errorMessage; // 💡 错误信息

  AuthStateData({
    required this.status,
    this.errorMessage,
  });

  // 初始状态工厂
  factory AuthStateData.initial() => AuthStateData(status: AuthStatus.initial);
}