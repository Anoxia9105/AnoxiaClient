import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/domain/repositories/message_repository.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/message_search_result.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:anoxia/framework/domain/forward_message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 消息仓库实现
///
/// 通过远程数据源（HTTP API）提供消息相关操作。
/// 实现 [MessageRepository] 抽象接口，供 UI 层 Provider 使用。
class MessageRepositoryImpl implements MessageRepository {
  @override
  Future<ForwardResult> forwardMessages(ForwardRequest request) async {
    final res = await DioClient().post(API.chatForward, data: request.toJson());
    _checkForwardResponse(res.data);
    return ForwardResult.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  @override
  Future<ForwardResult> forwardStatus(String operationId) async {
    final res = await DioClient().get('${API.chatForward}/$operationId');
    _checkForwardResponse(res.data);
    return ForwardResult.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  @override
  Future<ForwardRecordPage> forwardRecord(
    String recordId,
    String targetMessageId,
    String targetRoomId, {
    int offset = 0,
  }) async {
    final res = await DioClient().get(
      '${API.chatForward}/records/$recordId',
      queryParameters: {
        'targetMessageId': targetMessageId,
        'targetRoomId': targetRoomId,
        'offset': offset,
      },
    );
    _checkForwardResponse(res.data);
    return ForwardRecordPage.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  @override
  Future<ForwardRequest?> pendingForward(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('forward_pending_$userId');
    if (raw == null) return null;
    try {
      return ForwardRequest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePendingForward(int userId, ForwardRequest? request) async {
    final prefs = await SharedPreferences.getInstance();
    if (request == null) {
      await prefs.remove('forward_pending_$userId');
    } else {
      final saved = await prefs.setString(
        'forward_pending_$userId',
        jsonEncode(request.toJson()),
      );
      if (!saved) throw StateError('Cannot persist forward request');
    }
  }

  static void _checkForwardResponse(dynamic data) {
    if (data is! Map || data['code'] is! num) {
      throw const FormatException('Invalid forward response');
    }
    final code = (data['code'] as num).toInt();
    if (code != 200) throw ForwardRejectedException(code);
    if (data['data'] is! Map) {
      throw const FormatException('Invalid forward response');
    }
  }

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
