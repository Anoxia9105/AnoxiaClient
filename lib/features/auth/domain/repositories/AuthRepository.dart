import '../entities/User.dart';

/// TODO 描述
///
/// 作者: anoxia
///
/// 版本: 1.0.0
///
/// 创建时间: 2025-09-16  10:40

abstract class AuthRepository {
  Future<User> login(String email, String password);
}
