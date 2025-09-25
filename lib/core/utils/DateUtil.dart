import 'package:intl/intl.dart';

class DateUtil {
  static String formatIso8601(DateTime dt) => dt.toIso8601String();
  static DateTime parseIso8601(String s) => DateTime.parse(s);

  static String formatMessageTimestamp(DateTime timestamp) {
    final now = DateTime.now(); // 获取当前时间
    final today = DateTime(now.year, now.month, now.day); // 获取今天的日期（不含时间部分）
    final yesterday = DateTime(now.year, now.month, now.day - 1); // 获取昨天的日期

    if (isSameDay(timestamp, today)) {
      // 如果是今天，显示“今天 HH:mm”
      return '今天 ${formatTime(timestamp)}';
    } else if (isSameDay(timestamp, yesterday)) {
      // 如果是昨天，显示“昨天 HH:mm”
      return '昨天 ${formatTime(timestamp)}';
    } else if (timestamp.year == now.year) {
      // 如果是本年内的消息（但不是今天也不是昨天），显示“MM月dd日 HH:mm”
      return DateFormat('MM月dd日 HH:mm').format(timestamp);
    } else {
      // 如果是跨年消息，显示“yyyy年MM月dd日 HH:mm”
      return DateFormat('yyyy年MM月dd日 HH:mm').format(timestamp);
    }
  }

  static bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  /// 只返回时间：HH:mm
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }


  static String formatTimestampToTime(num ts) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(ts.toInt());
    return DateFormat('HH:mm').format(date);
  }
}
