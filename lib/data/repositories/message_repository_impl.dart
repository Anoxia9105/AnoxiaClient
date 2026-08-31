import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/domain/repositories/message_repository.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/message_search_result.dart';
import 'package:anoxia/framework/network/dio_client.dart';

/// 消息仓库实现
///
/// 通过远程数据源（HTTP API）提供消息相关操作。
/// 实现 [MessageRepository] 抽象接口，供 UI 层 Provider 使用。
class MessageRepositoryImpl implements MessageRepository {
  @override
  Future<List<ChatMessage>> fetchHistory(
    String roomId, {
    required int beforeSeq,
    required int pageSize,
  }) async {
    final res = await DioClient().get(
      API.chatHistory,
      queryParameters: {
        'roomId': roomId,
        'before_seq': beforeSeq,
        'lastSeq': beforeSeq,
        'pageSize': pageSize,
        'direction': 0,
      },
    );
    final data = res.data['data'];
    if (data is! List) return [];
    return data
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MessageSearchResult> searchMessages(
    String roomId,
    String keyword, {
    required int contextSize,
  }) async {
    final res = await DioClient().get(
      API.chatSearch,
      queryParameters: {
        'roomId': roomId,
        'keyword': keyword,
        'contextSize': contextSize,
      },
    );

    final data = res.data['data'];
    if (data is! Map) {
      return const MessageSearchResult(
        messages: [],
        firstMatchIndex: -1,
        lastMatchIndex: -1,
        hasMoreBefore: false,
        hasMoreAfter: false,
        minSeq: 0,
        maxSeq: 0,
        totalMatches: 0,
      );
    }
    return MessageSearchResult.fromJson(Map<String, dynamic>.from(data));
  }
}
