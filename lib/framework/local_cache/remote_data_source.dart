// 远程数据源
//
// 通过 HTTP API 与后端交互，获取会话列表、消息历史和发送消息，
// 为同步仓库提供远程数据。同时定义远程发送结果的数据类。
import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';

/// 远程发送结果
class RemoteSendResult {
  /// 创建远程发送结果实例
  ///
  /// [messageId] 消息 ID；[seq] 服务端序号；[sentAt] 发送时间；[message] 远程消息对象。
  const RemoteSendResult({
    required this.messageId,
    this.seq,
    this.sentAt,
    this.message,
  });

  /// 消息 ID
  final String messageId;

  /// 服务端消息序号
  final int? seq;

  /// 服务端发送时间
  final DateTime? sentAt;

  /// 远程消息对象
  final ChatMessage? message;
}

/// 远程数据源
///
/// 封装所有 IM 相关的 HTTP API 调用，提供会话、消息的获取和发送能力。
class RemoteDataSource {
  RemoteDataSource({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

  /// 获取会话列表
  ///
  /// [since] 可选，获取该时间之后更新的会话，用于增量同步。
  ///
  /// 返回 null 表示服务端响应异常（data 字段缺失/类型不符），
  /// 调用方不应把 null 当作「用户没有房间」，避免据此清空本地缓存。
  Future<List<ChatRoomVO>?> fetchConversations({DateTime? since}) async {
    final res = await _client.get(
      API.chatRooms,
      queryParameters: {
        if (since != null) 'updatedAfter': since.toIso8601String(),
      },
    );
    final data = res.data['data'];
    if (data is! List) return null;
    return data
        .map((e) => ChatRoomVO.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// 获取消息历史
  ///
  /// [convId] 会话 ID；[since] 获取该时间之后的消息；[lastSeq] 获取该序号之后的消息；
  /// [beforeSeq] 获取该序号之前的消息（分页向前加载）；[pageSize] 每页数量。
  Future<List<ChatMessage>> fetchMessages(
    String convId, {
    DateTime? since,
    int? lastSeq,
    int? beforeSeq,
    int pageSize = 100,
  }) async {
    final res = await _client.get(
      API.chatHistory,
      queryParameters: {
        'roomId': convId,
        if (beforeSeq != null && beforeSeq > 0) 'before_seq': beforeSeq,
        if (lastSeq != null && lastSeq > 0) 'lastSeq': lastSeq,
        if (since != null) 'since': since.toIso8601String(),
        'pageSize': pageSize,
        'direction': beforeSeq == null ? 1 : 0,
      },
    );
    final data = res.data['data'];
    if (data is! List) return const [];
    return data
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// 发送消息
  ///
  /// [message] 要发送的消息对象，返回包含服务端 ID 和序号的发送结果。
  Future<RemoteSendResult> sendMessage(ChatMessage message) async {
    final res = await _client.post(
      API.chatSendMessage,
      data: {
        'clientMsgId': message.clientMsgId,
        'roomId': message.roomId,
        'messageType': MessageType.toCode(message.messageType),
        'content': message.content,
        'payload': message.payload?.toTypedJson(
          message.messageType ?? MessageType.text,
        ),
        'clientTimestamp': message.timestamp,
      },
    );

    final data = res.data['data'];
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final remoteMessage = map.containsKey('roomId')
          ? ChatMessage.fromJson(map)
          : null;
      return RemoteSendResult(
        messageId:
            (map['messageId'] ?? remoteMessage?.messageId ?? message.messageId)
                .toString(),
        seq: int.tryParse((map['seq'] ?? remoteMessage?.seq ?? '').toString()),
        sentAt:
            _parseServerTime(map['sentAt'] ?? map['timestamp']) ??
            (remoteMessage?.timestamp == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(
                    remoteMessage!.timestamp!,
                  )),
        message: remoteMessage,
      );
    }

    return RemoteSendResult(
      messageId: message.messageId ?? message.clientMsgId!,
    );
  }

  /// 标记会话已读
  ///
  /// [seq] 可选，已读到的最大消息序号。
  Future<void> markAsRead(String conversationId, {int? seq}) {
    final queryParameters = <String, dynamic>{'roomId': conversationId};
    if (seq != null) queryParameters['seq'] = seq;

    return _client
        .get(API.chatReadReport, queryParameters: queryParameters)
        .then((_) {});
  }

  DateTime? _parseServerTime(dynamic value) {
    if (value == null) return null;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    final asInt = int.tryParse(value.toString());
    if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
    return DateTime.tryParse(value.toString());
  }
}
