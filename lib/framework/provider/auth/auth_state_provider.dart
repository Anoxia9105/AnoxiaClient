import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/UserInfo.dart';
import '../../logs/talker.dart';

part 'auth_state_provider.g.dart';

/// 认证状态
enum AuthStatus {
  initial, // 初始状态
  checking, // 正在检查登录状态
  authenticated, // 已认证
  unauthenticated, // 未认证
  error, // 错误
}

/// 认证状态数据
@immutable
class AuthStateData {
  final AuthStatus status;
  final String? errorMessage;
  final UserInfo? user;

  const AuthStateData({required this.status, this.errorMessage, this.user});

  // 便捷构造函数
  factory AuthStateData.initial() =>
      const AuthStateData(status: AuthStatus.initial);

  factory AuthStateData.checking() =>
      const AuthStateData(status: AuthStatus.checking);

  factory AuthStateData.authenticated(UserInfo user) =>
      AuthStateData(status: AuthStatus.authenticated, user: user);

  factory AuthStateData.unauthenticated() =>
      const AuthStateData(status: AuthStatus.unauthenticated);

  factory AuthStateData.error(String message) =>
      AuthStateData(status: AuthStatus.error, errorMessage: message);

  // 复制方法
  AuthStateData copyWith({
    AuthStatus? status,
    String? errorMessage,
    UserInfo? user,
  }) {
    return AuthStateData(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
    );
  }

  @override
  String toString() =>
      'AuthStateData(status: $status, error: $errorMessage, user: ${user?.nickName})';
}

@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {
  @override
  AuthStateData build() {
    return AuthStateData.initial();
  }

  // 设置为检查状态
  void setChecking() {
    log.info("[AuthState] 设置为检查状态");
    state = state.copyWith(status: AuthStatus.checking);
  }

  // 登录成功
  void login(UserInfo info) {
    log.info("[AuthState] 设置为已认证状态");
    state = state.copyWith(
      status: AuthStatus.authenticated,
      errorMessage: null,
      user: info,
    );
  }

  // 登出
  void logout() {
    log.info("[AuthState] 设置为未认证状态");
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      errorMessage: null,
      user: null,
    );
  }

  // 设置错误
  void setError(String message) {
    log.info("[AuthState] 设置为错误状态: $message");
    state = state.copyWith(status: AuthStatus.error, errorMessage: message);
  }
}
