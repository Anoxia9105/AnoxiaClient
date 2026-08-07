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

  String get displayLanguage => language ?? 'plaintext';

  bool get hasTitle => title != null && title!.trim().isNotEmpty;

  bool get isValid => code.trim().isNotEmpty;
}
