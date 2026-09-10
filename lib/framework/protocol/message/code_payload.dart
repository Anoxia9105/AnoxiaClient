class CodePayload {
  final String code;
  final String? language;
  final String? title;

  const CodePayload({
    required this.code,
    this.language,
    this.title,
  });

  factory CodePayload.fromJson(Map<String, dynamic> json) => CodePayload(
        code: json['code'] as String? ?? '',
        language: json['language'] as String?,
        title: json['title'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        if (language != null) 'language': language,
        if (title != null) 'title': title,
      };

  String get displayLanguage {
    final lang = language?.trim();
    if (lang != null && lang.isNotEmpty) return lang;
    return 'plaintext';
  }

  bool get hasTitle => title != null && title!.trim().isNotEmpty;

  bool get isValid => code.trim().isNotEmpty;

  /// 会话列表/本地预览用的摘要：优先标题，其次代码首个非空行。
  ///
  /// 无有效文本时返回空字符串，由展示层按当前语言渲染本地化占位
  /// （如 `[代码]`/`[Code]`），避免把 `plaintext` 等技术原文展示给用户。
  String get previewSnippet {
    if (hasTitle) return title!.trim();
    for (final line in code.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }
}
