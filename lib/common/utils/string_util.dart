/// 字符串工具类
///
/// 提供常用的字符串处理方法，包括判空、截断、格式化和转换。
class StringUtil {
  StringUtil._();

  /// 判断字符串是否为空
  static bool isEmpty(String? s) => s == null || s.trim().isEmpty;

  /// 判断字符串是否非空
  static bool isNotEmpty(String? s) => !isEmpty(s);

  /// 安全截取字符串
  ///
  /// [s] 源字符串
  /// [start] 起始索引（负数表示从末尾计算）
  /// [end] 结束索引（负数表示从末尾计算）
  static String safeSlice(String s, int start, [int? end]) {
    if (s.isEmpty) return '';
    if (start >= s.length) return '';
    final actualStart = start < 0 ? s.length + start : start;
    if (actualStart >= s.length) return '';
    final actualEnd = end == null
        ? s.length
        : (end < 0 ? s.length + end : (end > s.length ? s.length : end));
    if (actualStart >= actualEnd) return '';
    return s.substring(actualStart, actualEnd);
  }

  /// 截断字符串并添加省略号
  ///
  /// [s] 源字符串
  /// [maxLength] 最大长度，超过则截断并添加 "..."
  static String truncate(String s, int maxLength) {
    if (s.length <= maxLength) return s;
    return '${s.substring(0, maxLength)}...';
  }

  /// 限制字符串长度（不添加省略号）
  static String limit(String s, int maxLength) {
    return s.length <= maxLength ? s : s.substring(0, maxLength);
  }

  /// 字符串首字母大写
  static String capitalize(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  /// 格式化文件大小
  ///
  /// [bytes] 字节数
  /// 返回如 "1.5 MB" 的字符串
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 生成带高亮的搜索结果文本
  ///
  /// [text] 原文
  /// [query] 搜索关键词
  /// 返回高亮区间列表（起始位置，长度）
  static List<(int, int)> highlightRanges(String text, String query) {
    if (isEmpty(query)) return [];
    final List<(int, int)> ranges = [];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) break;
      ranges.add((index, query.length));
      start = index + 1;
    }

    return ranges;
  }
}
