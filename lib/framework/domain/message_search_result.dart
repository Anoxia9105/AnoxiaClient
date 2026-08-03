import 'chat_message.dart';

/// 消息搜索结果模型
///
/// 封装搜索消息接口的返回数据，包含匹配消息列表、
/// 首次/末次匹配索引、分页标记和匹配总数。
class MessageSearchResult {
  /// 匹配的消息列表
  final List<ChatMessage> messages;

  /// 首次匹配消息在列表中的索引
  final int firstMatchIndex;

  /// 末次匹配消息在列表中的索引
  final int lastMatchIndex;

  /// 是否还有更早的匹配
  final bool hasMoreBefore;

  /// 是否还有更新的匹配
  final bool hasMoreAfter;

  /// 结果中的最小消息序号
  final int minSeq;

  /// 结果中的最大消息序号
  final int maxSeq;

  /// 匹配消息总数
  final int totalMatches;

  const MessageSearchResult({
    required this.messages,
    required this.firstMatchIndex,
    required this.lastMatchIndex,
    required this.hasMoreBefore,
    required this.hasMoreAfter,
    required this.minSeq,
    required this.maxSeq,
    required this.totalMatches,
  });

  /// 从 JSON 数据构造 [MessageSearchResult] 实例
  factory MessageSearchResult.fromJson(Map<String, dynamic> json) {
    final messagesData = json['messages'] ?? [];
    final List<ChatMessage> messages = [];
    if (messagesData is List) {
      for (final item in messagesData) {
        if (item is Map) {
          final Map<String, dynamic> stringKeyMap = item.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          messages.add(ChatMessage.fromJson(stringKeyMap));
        }
      }
    }

    return MessageSearchResult(
      messages: messages,
      firstMatchIndex: json['firstMatchIndex'] ?? -1,
      lastMatchIndex: json['lastMatchIndex'] ?? -1,
      hasMoreBefore: json['hasMoreBefore'] ?? false,
      hasMoreAfter: json['hasMoreAfter'] ?? false,
      minSeq: json['minSeq'] ?? 0,
      maxSeq: json['maxSeq'] ?? 0,
      totalMatches: json['totalMatches'] ?? 0,
    );
  }
}
