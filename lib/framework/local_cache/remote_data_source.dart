import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/domain/ChatMessage.dart';
import 'package:anoxia/framework/domain/ChatRoomVO.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/protocol/message/MessageEunm.dart';

class RemoteSendResult {
  const RemoteSendResult({
    required this.messageId,
    this.seq,
    this.sentAt,
    this.message,
  });

  final String messageId;
  final int? seq;
  final DateTime? sentAt;
  final ChatMessage? message;
}

class RemoteDataSource {
  RemoteDataSource({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

  Future<List<ChatRoomVO>> fetchConversations({DateTime? since}) async {
    final res = await _client.get(
      API.chatRooms,
      queryParameters: {
        if (since != null) 'updatedAfter': since.toIso8601String(),
      },
    );
    final data = res.data['data'];
    if (data is! List) return const [];
    return data
        .map((e) => ChatRoomVO.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

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
