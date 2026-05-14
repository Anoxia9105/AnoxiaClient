import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 工具类
///
/// 提供类型安全的键值对存储封装，支持常用数据类型的读写。
class SPUtil {
  SPUtil._();

  static final SPUtil _instance = SPUtil._();
  static SPUtil get instance => _instance;

  SharedPreferences? _prefs;

  /// 初始化 SharedPreferences 实例
  ///
  /// 必须在使用其他方法前调用
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 读取字符串
  String? get(String key, {String? defValue}) {
    return _prefs?.getString(key) ?? defValue;
  }

  /// 写入字符串
  Future<bool> set(String key, String value) {
    return _prefs?.setString(key, value) ?? Future.value(false);
  }

  /// 读取布尔值
  bool? getBool(String key, {bool? defValue}) {
    return _prefs?.getBool(key) ?? defValue;
  }

  /// 写入布尔值
  Future<bool> setBool(String key, bool value) {
    return _prefs?.setBool(key, value) ?? Future.value(false);
  }

  /// 读取整数
  int? getInt(String key, {int? defValue}) {
    return _prefs?.getInt(key) ?? defValue;
  }

  /// 写入整数
  Future<bool> setInt(String key, int value) {
    return _prefs?.setInt(key, value) ?? Future.value(false);
  }

  /// 读取双精度浮点数
  double? getDouble(String key, {double? defValue}) {
    return _prefs?.getDouble(key) ?? defValue;
  }

  /// 写入双精度浮点数
  Future<bool> setDouble(String key, double value) {
    return _prefs?.setDouble(key, value) ?? Future.value(false);
  }

  /// 读取字符串列表
  List<String>? getStringList(String key, {List<String>? defValue}) {
    return _prefs?.getStringList(key) ?? defValue;
  }

  /// 写入字符串列表
  Future<bool> setStringList(String key, List<String> value) {
    return _prefs?.setStringList(key, value) ?? Future.value(false);
  }

  /// 删除指定键
  Future<bool> delete(String key) {
    return _prefs?.remove(key) ?? Future.value(false);
  }

  /// 判断键是否存在
  bool contains(String key) {
    return _prefs?.containsKey(key) ?? false;
  }

  /// 清空所有数据
  Future<bool> clear() {
    return _prefs?.clear() ?? Future.value(false);
  }

  /// 批量写入多个值
  Future<void> setMulti(Map<String, dynamic> values) async {
    if (_prefs == null) return;
    for (final entry in values.entries) {
      final value = entry.value;
      if (value is String) {
        await _prefs!.setString(entry.key, value);
      } else if (value is int) {
        await _prefs!.setInt(entry.key, value);
      } else if (value is double) {
        await _prefs!.setDouble(entry.key, value);
      } else if (value is bool) {
        await _prefs!.setBool(entry.key, value);
      } else if (value is List<String>) {
        await _prefs!.setStringList(entry.key, value);
      }
    }
  }

  /// 批量删除多个键
  Future<void> deleteMulti(List<String> keys) async {
    if (_prefs == null) return;
    for (final key in keys) {
      await _prefs!.remove(key);
    }
  }
}

/// 存储键名常量
class StorageKeys {
  StorageKeys._();

  static const String accessToken = 'access_token';
  static const String locale = 'locale';
  static const String theme = 'theme';
  static const String chatHistory = 'chat_history';
  static const String userId = 'userId';
  static const String lastLoginTime = 'last_login_time';
}
