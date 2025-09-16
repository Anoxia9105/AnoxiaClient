class DateUtil {
  static String formatIso8601(DateTime dt) => dt.toIso8601String();
  static DateTime parseIso8601(String s) => DateTime.parse(s);
}
