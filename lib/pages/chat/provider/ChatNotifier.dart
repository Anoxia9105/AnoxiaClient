import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart' hide ChatMessage;
import '../model/ChatMessage.dart';

/// Chat状态
class ChatState {
  /// 消息列表
  final List<ChatMessage> messages;

  /// 是否加载中
  final bool isLoading;

  /// 错误信息
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  /// 复制方法
  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Chat管理器 - 简单的数据模型，通过mixin处理事件
class ChatManager {
  final List<ChatMessage> messages = [];
  final LocalParticipant? localParticipant;
  final EventsListener<RoomEvent>? listener;

  ChatManager({
    required this.localParticipant,
    required this.listener,
  }) {
    _setupChatListener();
  }

  /// 设置聊天监听器
  void _setupChatListener() {
    if (listener == null) return;

    try {
      // 监听DataReceivedEvent
      listener!.on<DataReceivedEvent>((event) {
        if (event.topic == 'lk-chat-topic') {
          _handleChatMessage(event);
        }
      });
    } catch (e) {
      print('Failed to setup chat listener: $e');
    }
  }

  /// 处理接收到的聊天消息
  void _handleChatMessage(DataReceivedEvent event) {
    try {
      // 解析JSON数据
      final jsonString = const Utf8Decoder().convert(event.data);
      final json = const JsonDecoder().convert(jsonString) as Map<String, dynamic>;

      // 创建聊天消息
      final message = ChatMessage(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: event.participant?.identity ?? 'unknown',
        senderName: event.participant?.name ?? 'Unknown User',
        content: json['message'] as String? ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int? ?? 0),
        isLocal: false,
      );

      // 添加消息到列表
      messages.add(message);
    } catch (e) {
      print('Error parsing chat message: $e');
    }
  }

  /// 发送消息
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    if (localParticipant == null) {
      return;
    }

    try {
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 创建本地消息
      final message = ChatMessage(
        id: messageId,
        senderId: localParticipant?.identity ?? 'unknown',
        senderName: localParticipant?.name ?? 'You',
        content: content.trim(),
        timestamp: DateTime.now(),
        isLocal: true,
      );

      // 立即添加本地消息到列表
      messages.add(message);

      // 发送消息到其他参与者
      final jsonData = {
        'message': content.trim(),
        'timestamp': timestamp,
        'id': messageId,
      };
      final jsonString = const JsonEncoder().convert(jsonData);
      final jsonBytes = const Utf8Encoder().convert(jsonString);

      await localParticipant?.publishData(
        jsonBytes,
        topic: 'lk-chat-topic',
      );
    } catch (e) {
      print('Failed to send message: $e');
    }
  }

  /// 清空消息
  void clearMessages() {
    messages.clear();
  }
}

/// Chat管理器提供者
final chatManagerProvider = Provider.family<ChatManager, ({LocalParticipant? localParticipant, EventsListener<RoomEvent>? listener})>((ref, params) {
  return ChatManager(
    localParticipant: params.localParticipant,
    listener: params.listener,
  );
});
