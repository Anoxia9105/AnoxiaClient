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

  /// =========================
  /// 微信风格时间分隔格式化
  /// =========================
  /// [timestamp] 毫秒级时间戳
  /// [locale] 当前语言环境的 languageCode，如 'zh', 'en', 'ja'
  ///
  /// 规则（与微信一致）:
  /// - 今天：HH:mm
  /// - 昨天：昨天 HH:mm
  /// - 本周（2~6天前）：星期X HH:mm
  /// - 今年（超过本周）：M月D日 HH:mm
  /// - 跨年：YYYY年M月D日 HH:mm
  static String formatWeChatTimeDivider(int timestamp, String locale) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(date.year, date.month, date.day);
    final diffDays = today.difference(msgDay).inDays;
    final time = DateFormat('HH:mm').format(date);

    // 今天
    if (diffDays == 0 && msgDay == today) {
      return time;
    }

    // 昨天
    if (diffDays == 1) {
      return '${_yesterdayLabel(locale)} $time';
    }

    // 本周内（2~6天前）且不跨年
    if (diffDays >= 2 && diffDays <= 6 && date.year == now.year) {
      return '${_weekdayLabel(date.weekday, locale)} $time';
    }

    // 今年
    if (date.year == now.year) {
      return '${_monthDayLabel(date, locale)} $time';
    }

    // 跨年
    return '${_fullDateLabel(date, locale)} $time';
  }

  /// "昨天" 的国际化标签
  static String _yesterdayLabel(String locale) {
    switch (locale) {
      case 'ja':
        return '昨日';
      case 'zh':
        return '昨天';
      default:
        return 'Yesterday';
    }
  }

  /// 星期几的国际化标签
  static String _weekdayLabel(int weekday, String locale) {
    const zh = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    const en = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const ja = ['月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日'];

    final index = weekday - 1; // DateTime.weekday: 1=Monday ... 7=Sunday
    switch (locale) {
      case 'ja':
        return ja[index];
      case 'zh':
        return zh[index];
      default:
        return en[index];
    }
  }

  /// "M月D日" 的国际化标签
  static String _monthDayLabel(DateTime date, String locale) {
    switch (locale) {
      case 'ja':
        return '${date.month}月${date.day}日';
      case 'zh':
        return '${date.month}月${date.day}日';
      default:
        return DateFormat('MMM d').format(date); // "Apr 10"
    }
  }

  /// "YYYY年M月D日" 的国际化标签
  static String _fullDateLabel(DateTime date, String locale) {
    switch (locale) {
      case 'ja':
        return '${date.year}年${date.month}月${date.day}日';
      case 'zh':
        return '${date.year}年${date.month}月${date.day}日';
      default:
        return DateFormat('MMM d, yyyy').format(date); // "Apr 10, 2025"
    }
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
