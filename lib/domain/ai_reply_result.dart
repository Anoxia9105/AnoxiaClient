import 'dart:convert';

/// 只接受完整、可发送的候选，不把断裂 JSON 降级成普通消息展示。
List<String> parseAiReplySuggestions(String raw) {
  var text = raw.trim();
  if (text.startsWith('```')) {
    text = text
        .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '');
  }
  try {
    final decoded = jsonDecode(text);
    if (decoded is! List || decoded.isEmpty || decoded.length > 3) {
      return const [];
    }
    final result = <String>[];
    for (final item in decoded) {
      if (item is! String || item.trim().isEmpty || item.length > 2000) {
        return const [];
      }
      final suggestion = item.trim();
      if (!result.contains(suggestion)) result.add(suggestion);
    }
    return result;
  } catch (_) {
    return const [];
  }
}
