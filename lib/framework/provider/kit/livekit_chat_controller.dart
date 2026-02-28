import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../logs/talker.dart';
import '../../domain/RoomState.dart';
import 'room_controller.dart';

/// LiveKit 聊天消息模型
class LiveKitMessage {
  final String id;
  final String message;
  final int timestamp;
  final bool isSender;
  final String senderId;
  final String senderName;

  LiveKitMessage({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.isSender,
    required this.senderId,
    required this.senderName,
  });
}

/// LiveKit 聊天状态
class LiveKitChatState {
  final List<LiveKitMessage> messages;
  final bool isEnabled;
  final String? error;

  const LiveKitChatState({
    this.messages = const [],
    this.isEnabled = false,
    this.error,
  });

  LiveKitChatState copyWith({
    List<LiveKitMessage>? messages,
    bool? isEnabled,
    String? error,
  }) {
    return LiveKitChatState(
      messages: messages ?? this.messages,
      isEnabled: isEnabled ?? this.isEnabled,
      error: error,
    );
  }
}

/// LiveKit 聊天控制器
class LiveKitChatController extends Notifier<LiveKitChatState> {
  @override
  LiveKitChatState build() {
    _setupDataListener();
    return const LiveKitChatState();
  }

  StreamSubscription? _dataSubscription;

  void _setupDataListener() {
    final token = ref.params['token'];
    if (token == null) return;

    final roomState = ref.read(roomControllerProvider(token)).value;
    if (roomState == null) return;

    final room = roomState.room;
    _dataSubscription = room.on<RoomEvent>().listen((event) {
      if (event is DataReceivedEvent) {
        if (event.topic == 'lk-chat-topic') {
          _handleDataReceived(event);
        }
      }
    });
  }

  void _handleDataReceived(DataReceivedEvent event) {
    try {
      final messageStr = utf8.decode(event.data);
      final map = jsonDecode(messageStr) as Map<String, dynamic>;
      final senderId = event.participant?.identity ?? 'unknown';
      final senderName = event.participant?.name ?? senderId;

      final message = LiveKitMessage(
        id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        message: map['message'] ?? '',
        timestamp: map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
        isSender: false,
        senderId: senderId,
        senderName: senderName,
      );

      state = state.copyWith(
        messages: [...state.messages, message],
      );
    } catch (e) {
      log.error('解析聊天消息失败: $e');
    }
  }

  void toggleChat(bool enabled) {
    state = state.copyWith(isEnabled: enabled);
  }

  Future<void> sendMessage(String text) async {
    final token = ref.params['token'];
    if (token == null) return;

    final roomState = ref.read(roomControllerProvider(token)).value;
    if (roomState == null) return;

    final localParticipant = roomState.room.localParticipant;
    if (localParticipant == null) return;

    final message = LiveKitMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      isSender: true,
      senderId: localParticipant.identity,
      senderName: localParticipant.name ?? localParticipant.identity,
    );

    state = state.copyWith(
      messages: [...state.messages, message],
    );

    try {
      final data = jsonEncode({
        'id': message.id,
        'message': message.message,
        'timestamp': message.timestamp,
      });
      await localParticipant.publishData(
        utf8.encode(data),
        topic: 'lk-chat-topic',
      );
    } catch (e) {
      log.error('发送聊天消息失败: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }
}

/// LiveKit 聊天 Provider
final liveKitChatProvider = NotifierProvider.autoDispose
    .withParams<LiveKitChatController, LiveKitChatState, ({String token})>(
  LiveKitChatController.new,
  paramName: 'token',
  paramFrom: (token) => (token: token),
);
