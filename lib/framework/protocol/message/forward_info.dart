/// 服务端生成的转发展示信息，不参与用户上行载荷。
class ForwardInfo {
  final String authorName;
  final int originalTimestampMs;
  const ForwardInfo({
    required this.authorName,
    required this.originalTimestampMs,
  });
  factory ForwardInfo.fromJson(Map<String, dynamic> json) => ForwardInfo(
    authorName: json['authorName']?.toString() ?? '',
    originalTimestampMs: int.tryParse('${json['originalTimestampMs']}') ?? 0,
  );
  Map<String, dynamic> toJson() => {
    'authorName': authorName,
    'originalTimestampMs': originalTimestampMs,
  };
}
