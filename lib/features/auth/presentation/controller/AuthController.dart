/// TODO 描述
///
/// 作者: anoxia
///
/// 版本: 1.0.0
///
/// 创建时间: 2025-09-16  10:42
import 'package:flutter/material.dart';

import '../../domain/entities/User.dart';

class AuthController extends ChangeNotifier {
  User? _user;
  bool get isAuthenticated => _user != null;
  User? get user => _user;

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
