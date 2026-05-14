import 'package:intl/intl.dart';

/// 日期时间工具类
///
/// 提供常用的日期时间格式化和解析方法。
/// 支持微信风格的聊天气泡时间分隔显示。
class DateUtil {
  /// 将 DateTime 转为 ISO 8601 字符串
  static String formatIso8601(DateTime dt) => dt.toIso8601String();

  /// 解析 ISO 8601 字符串为 DateTime
  static DateTime parseIso8601(String s) => DateTime.parse(s);

  /// 判断两个日期是否为同一天
  static bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  /// 将时间戳格式化为 HH:mm
  static String formatTimestampToTime(int? timestamp) {
    if (timestamp == null) return "";
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('HH:mm').format(date);
  }

  /// 格式化时间戳
  ///
  /// 规则：
  /// - 今天：HH:mm
  /// - 今年：MM-dd
  /// - 跨年：yyyy/MM/dd
  static String formatTime(int? timestamp) {
    if (timestamp == null) return "";
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    if (date.day == now.day) return DateFormat('HH:mm').format(date);
    if (date.year == now.year) return DateFormat('MM-dd').format(date);
    return DateFormat('yyyy/MM/dd').format(date);
  }

  /// 微信风格时间分隔格式化
  ///
  /// [timestamp] 毫秒级时间戳
  /// [locale] 当前语言环境的 languageCode，如 'zh', 'en', 'ja'
  ///
  /// 规则：
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

    if (diffDays == 0 && msgDay == today) {
      return time;
    }

    if (diffDays == 1) {
      return '${_yesterdayLabel(locale)} $time';
    }

    if (diffDays >= 2 && diffDays <= 6 && date.year == now.year) {
      return '${_weekdayLabel(date.weekday, locale)} $time';
    }

    if (date.year == now.year) {
      return '${_monthDayLabel(date, locale)} $time';
    }

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

    final index = weekday - 1;
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
        return DateFormat('MMM d').format(date);
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
        return DateFormat('MMM d, yyyy').format(date);
    }
  }

  /// 将字符串日期转为指定格式
  ///
  /// [isoString] 输入的 ISO 8601 日期字符串
  /// [pattern] 输出格式，默认 "yyyy-MM-dd HH:mm:ss"
  static String formatIsoDate(
    String isoString, {
    String pattern = "yyyy-MM-dd HH:mm:ss",
  }) {
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat(pattern).format(dateTime);
    } catch (e) {
      return isoString;
    }
  }
}
