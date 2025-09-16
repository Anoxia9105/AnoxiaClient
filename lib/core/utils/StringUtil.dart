/// 字符串工具类
///
/// 作者: anoxia
///
/// 版本: 1.0.0
///
/// 创建时间: 2025-09-16  15:19
class StringUtil {
  /// 判断字符串是否为空（null 或 仅空格）
  static bool isNullOrEmpty(String? str) {
    return str == null || str.trim().isEmpty;
  }

  /// 判断字符串是否不为空
  static bool isNotEmpty(String? str) {
    return !isNullOrEmpty(str);
  }

  /// 去除首尾空格（null 安全）
  static String trim(String? str) {
    return str?.trim() ?? '';
  }

  /// 首字母大写
  static String capitalize(String? str) {
    if (isNullOrEmpty(str)) return '';
    return str!.substring(0, 1).toUpperCase() + str.substring(1);
  }

  /// 全部转小写
  static String toLowerCase(String? str) {
    return str?.toLowerCase() ?? '';
  }

  /// 全部转大写
  static String toUpperCase(String? str) {
    return str?.toUpperCase() ?? '';
  }

  /// 判断是否是数字
  static bool isNumeric(String? str) {
    if (isNullOrEmpty(str)) return false;
    return double.tryParse(str!) != null;
  }

  /// 判断是否是邮箱
  static bool isEmail(String? str) {
    if (isNullOrEmpty(str)) return false;
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    return regex.hasMatch(str!);
  }

  /// 判断是否是手机号（简单示例，可按地区调整）
  static bool isPhone(String? str) {
    if (isNullOrEmpty(str)) return false;
    final regex = RegExp(r'^\d{6,15}$');
    return regex.hasMatch(str!);
  }

  /// 截断字符串，超出部分用省略号
  static String truncate(String? str, int maxLength) {
    if (isNullOrEmpty(str)) return '';
    if (str!.length <= maxLength) return str;
    return str.substring(0, maxLength) + '...';
  }

  /// 安全地将对象转为字符串
  static String safeToString(Object? obj) {
    return obj?.toString() ?? '';
  }
}