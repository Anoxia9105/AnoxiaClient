import 'package:intl/intl.dart';

class DateUtil {
  static String formatIso8601(DateTime dt) => dt.toIso8601String();

  static DateTime parseIso8601(String s) => DateTime.parse(s);

  static bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  static String formatTimestampToTime(int? timestamp) {
    if (timestamp == null) return "";
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('HH:mm').format(date);
  }

  static String formatTime(int? timestamp) {
    if (timestamp == null) return "";
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    if (date.day == now.day) return DateFormat('HH:mm').format(date);
    if (date.year == now.year) return DateFormat('MM-dd').format(date);
    return DateFormat('yyyy/MM/dd').format(date);
  }

  /// 将字符串日期转为指定格式
  /// [dateStr] 输入的日期字符串，例如 "2025-09-28 16:45:00"
  /// [inputPattern] 输入字符串的格式，例如 "yyyy-MM-dd HH:mm:ss"
  /// [outputPattern] 输出想要的格式，例如 "yyyy/MM/dd HH:mm"
  static String formatIsoDate(
    String isoString, {
    String pattern = "yyyy-MM-dd HH:mm:ss",
  }) {
    try {
      final dateTime = DateTime.parse(isoString); // 直接解析 ISO 8601
      return DateFormat(pattern).format(dateTime);
    } catch (e) {
      return isoString; // 解析失败时返回原字符串
    }
  }
}
