/// 转录字幕数据模型
class TranscriptionSegment {
  /// 分段ID
  final String id;

  /// 发言者ID
  final String speakerId;

  /// 发言者名称
  final String speakerName;

  /// 转录文本
  final String text;

  /// 语言代码
  final String language;

  /// 开始时间（毫秒）
  final int startTime;

  /// 结束时间（毫秒）
  final int endTime;

  /// 置信度 (0-1)
  final double confidence;

  /// 是否是最终版本
  final bool isFinal;

  TranscriptionSegment({
    required this.id,
    required this.speakerId,
    required this.speakerName,
    required this.text,
    this.language = 'en',
    required this.startTime,
    required this.endTime,
    this.confidence = 1.0,
    this.isFinal = true,
  });

  /// 从JSON反序列化
  factory TranscriptionSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptionSegment(
      id: json['id'] as String? ?? '',
      speakerId: json['speakerId'] as String? ?? '',
      speakerName: json['speakerName'] as String? ?? 'Unknown',
      text: json['text'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      startTime: json['startTime'] as int? ?? 0,
      endTime: json['endTime'] as int? ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      isFinal: json['isFinal'] as bool? ?? true,
    );
  }

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'speakerId': speakerId,
      'speakerName': speakerName,
      'text': text,
      'language': language,
      'startTime': startTime,
      'endTime': endTime,
      'confidence': confidence,
      'isFinal': isFinal,
    };
  }

  /// 复制方法
  TranscriptionSegment copyWith({
    String? id,
    String? speakerId,
    String? speakerName,
    String? text,
    String? language,
    int? startTime,
    int? endTime,
    double? confidence,
    bool? isFinal,
  }) {
    return TranscriptionSegment(
      id: id ?? this.id,
      speakerId: speakerId ?? this.speakerId,
      speakerName: speakerName ?? this.speakerName,
      text: text ?? this.text,
      language: language ?? this.language,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      confidence: confidence ?? this.confidence,
      isFinal: isFinal ?? this.isFinal,
    );
  }

  @override
  String toString() => 'TranscriptionSegment(speaker: $speakerName, text: $text)';
}
