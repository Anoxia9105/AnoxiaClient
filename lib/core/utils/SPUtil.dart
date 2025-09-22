import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// SPUtil - SharedPreferences 工具（企业风格封装）
/// 特点：单例、显式初始化、泛型读写、支持对象序列化/反序列化、默认值
class SPUtil {
  static SPUtil? _instance;
  static SharedPreferences? _prefs;

  SPUtil._();

  /// 必须在 app 启动时先调用： await SPUtil.init();
  static Future<SPUtil> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _instance ??= SPUtil._();
    return _instance!;
  }

  /// 获取单例（已初始化时使用）
  static SPUtil get instance {
    if (_prefs == null) {
      throw Exception('SPUtil 尚未初始化，请先调用 await SPUtil.init()');
    }
    return _instance!;
  }

  /// 是否包含 key
  bool containsKey(String key) {
    return _prefs!.containsKey(key);
  }

  /// 通用存储方法
  /// - 支持基础类型 (String/int/double/bool/List<String>)
  /// - 支持 Map/List/对象 -> JSON 存储
  /// - 可选 toEncodable: 用于复杂对象的自定义序列化 (返回可以 jsonEncode 的对象)
  Future<bool> set<T>(String key, T value, {Object? Function(T value)? toEncodable}) async {
    if (_prefs == null) throw Exception('SPUtil 尚未初始化');

    if (value is String) return _prefs!.setString(key, value);
    if (value is int) return _prefs!.setInt(key, value);
    if (value is double) return _prefs!.setDouble(key, value);
    if (value is bool) return _prefs!.setBool(key, value);
    if (value is List<String>) return _prefs!.setStringList(key, value);

    // 其它类型统一用 JSON 存储
    try {
      Object? raw;
      if (toEncodable != null) {
        raw = toEncodable(value);
      } else {
        if (value is Map || value is List) {
          raw = value;
        } else {
          // 尝试调用对象的 toJson()
          try {
            final dyn = value as dynamic;
            raw = dyn.toJson != null ? dyn.toJson() : value.toString();
          } catch (_) {
            raw = value.toString();
          }
        }
      }
      String jsonStr = jsonEncode(raw);
      return _prefs!.setString(key, jsonStr);
    } catch (e) {
      // 兜底：转 string 存储
      return _prefs!.setString(key, value.toString());
    }
  }

  /// 通用读取方法
  /// - defValue: 默认值（key 不存在或反序列化失败时返回）
  /// - fromJson: 当读取到 JSON（Map 或 List）时，可提供反序列化函数：
  ///     - 若存的是单个对象 -> fromJson(Map) => T
  ///     - 若存的是对象数组 -> fromJson(dynamic) => T （函数会被 map 到每个元素）
  T? get<T>(String key, {T? defValue, T Function(dynamic json)? fromJson}) {
    if (_prefs == null) throw Exception('SPUtil 尚未初始化');

    if (!_prefs!.containsKey(key)) return defValue;

    final dynamic result = _prefs!.get(key);
    if (result == null) return defValue;

    // 直接基础类型返回
    if (T == String || T == dynamic) return result as T;
    if (T == int) return result as T;
    if (T == double) return result as T;
    if (T == bool) return result as T;
    if (T == List<String>) return result as T;

    // 处理 JSON 字符串（对象 / 数组）
    if (result is String) {
      try {
        final decoded = jsonDecode(result);
        if (decoded is List) {
          // List 情况：如果提供了 fromJson 则映射，否则直接返回 List<dynamic>
          if (fromJson != null) {
            final list = decoded.map((e) => fromJson(e)).toList();
            return list as T;
          } else {
            return decoded as T;
          }
        } else if (decoded is Map) {
          if (fromJson != null) {
            return fromJson(decoded);
          } else {
            return decoded as T;
          }
        } else {
          // 既不是 Map 也不是 List，可能是基础值
          return decoded as T;
        }
      } catch (e) {
        // 不是 JSON（普通字符串）
        return result as T;
      }
    }

    // 其它情况直接尝试 cast
    return result as T;
  }

  /// 移除 key
  Future<bool> remove(String key) async {
    if (_prefs == null) throw Exception('SPUtil 尚未初始化');
    return _prefs!.remove(key);
  }

  /// 清空全部
  Future<bool> clear() async {
    if (_prefs == null) throw Exception('SPUtil 尚未初始化');
    return _prefs!.clear();
  }

  /// 获取所有 key
  Set<String> getKeys() {
    if (_prefs == null) throw Exception('SPUtil 尚未初始化');
    return _prefs!.getKeys();
  }
}
