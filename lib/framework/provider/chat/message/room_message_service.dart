import 'dart:async';

import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/protocol/message/MessageEunm.dart';
import 'package:anoxia/framework/provider/chat/call/call_status_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/ChatMessage.dart';
import '../../../logs/talker.dart';
import '../../../protocol/PacketType.dart';
import '../../../protocol/message/RoomMessage.dart';
import '../../ws/ws_controller.dart';

part 'room_message_service.g.dart';

@riverpod
Stream<List<ChatMessage>> roomMessages(Ref ref, String roomId) {
  return ref.read(syncRepositoryProvider).watchMessages(roomId, limit: null);
}

@Riverpod(keepAlive: true)
class ChatMessages extends _$ChatMessages {
  static const int _pageSize = 50;

  bool _isFetchingHistory = false;
  final Set<String> _syncedRoomIds = {};
  final Map<String, int> _syncedSeqByRoom = {};

  @override
  void build() {
    final stream = ref.read(wsControllerProvider.notifier).messageStream;
    final subscription = stream
        .where((frame) => frame.topic == PacketType.message)
        .map((frame) => frame.data as RoomMessage)
        .listen(_handleIncomingMessage);

    ref.onDispose(subscription.cancel);
  }

  void _handleIncomingMessage(RoomMessage msg) {
    final chatMessage = ChatMessage.fromRoomMessage(msg);
    upsertMessage(chatMessage);
    _handleSystemMessageSideEffects(chatMessage);

    final activeRoomId = ref.read(activeRoomIdProvider);
    ref
        .read(roomListServiceProvider.notifier)
        .updateRoomPosition(chatMessage, activeRoomId);
  }

  void _handleSystemMessageSideEffects(ChatMessage msg) {
    if (msg.messageType != MessageType.system) return;
    final roomId = msg.roomId;
    if (roomId == null || roomId.isEmpty) return;

    final action = (msg.properties['action'] ?? msg.content).toUpperCase();
    switch (action) {
      case 'CALL_STARTED':
      case 'CALL_START':
      case 'CALLING':
        ref
            .read(callStatusControllerProvider.notifier)
            .markStarted(roomId, startTime: msg.timestamp);
        break;
      case 'CALL_ENDED':
      case 'CALL_END':
        ref.read(callStatusControllerProvider.notifier).markEnded(roomId);
        break;
      default:
        break;
    }
  }

  void upsertMessage(ChatMessage msg) {
    if (msg.roomId?.isNotEmpty != true) return;
    if (msg.messageId?.isNotEmpty != true &&
        msg.clientMsgId?.isNotEmpty != true) {
      return;
    }
    unawaited(ref.read(syncRepositoryProvider).cacheLocalMessage(msg));
  }

  Future<void> handleTimeout(String roomId, String clientMsgId) async {
    final local = ref.read(localDataSourceProvider);
    final message = await local.getMessageByClientMsgId(clientMsgId);
    if (message == null || message.deliveryStatus != DeliveryStatus.sending) {
      return;
    }
    await local.upsertMessage(
      message.copyWith(deliveryStatus: DeliveryStatus.failed),
    );
  }

  Future<void> markAcked({
    required String clientMsgId,
    String? roomId,
    String? messageId,
    int? seq,
    int? timestamp,
  }) async {
    final local = ref.read(localDataSourceProvider);
    final message = await local.getMessageByClientMsgId(clientMsgId);
    if (message == null) return;

    await local.upsertMessage(
      message.copyWith(
        messageId: messageId,
        seq: seq,
        timestamp: timestamp,
        deliveryStatus: DeliveryStatus.sent,
      ),
    );
  }

  Future<void> markFailedByClientMsgId(String clientMsgId) async {
    final local = ref.read(localDataSourceProvider);
    final message = await local.getMessageByClientMsgId(clientMsgId);
    if (message == null) return;
    await local.upsertMessage(
      message.copyWith(deliveryStatus: DeliveryStatus.failed),
    );
  }

  Future<void> syncRoomMessages(String roomId, int? serverLastSeq) async {
    final syncRepo = ref.read(syncRepositoryProvider);
    final localMessages = await syncRepo.getMessagesForConversation(
      roomId,
      limit: _pageSize,
      sync: false,
    );
    final localMaxSeq = _maxSeq(localMessages);

    ref
        .read(chatHasMoreProvider.notifier)
        .setHasMore(roomId, localMessages.length >= _pageSize);

    if (_syncedRoomIds.contains(roomId) &&
        (serverLastSeq == null ||
            (_syncedSeqByRoom[roomId] ?? localMaxSeq) >= serverLastSeq)) {
      return;
    }

    if (serverLastSeq == null || localMaxSeq >= serverLastSeq) {
      _syncedRoomIds.add(roomId);
      _syncedSeqByRoom[roomId] = localMaxSeq;
      return;
    }

    try {
      await syncRepo.syncMessages(roomId);
      _syncedRoomIds.add(roomId);
      _syncedSeqByRoom[roomId] = serverLastSeq;

      final refreshed = await syncRepo.getMessagesForConversation(
        roomId,
        limit: _pageSize,
        sync: false,
      );
      ref
          .read(chatHasMoreProvider.notifier)
          .setHasMore(roomId, refreshed.length >= _pageSize);
    } catch (e) {
      log.error('同步房间 $roomId 失败: $e');
    }
  }

  Future<void> loadMoreHistory(String roomId) async {
    if (_isFetchingHistory) return;
    if (!(ref.read(chatHasMoreProvider)[roomId] ?? true)) return;

    final syncRepo = ref.read(syncRepositoryProvider);
    final currentList = await syncRepo.getMessagesForConversation(
      roomId,
      limit: 100000,
      sync: false,
    );
    if (currentList.isEmpty) return;

    final int? oldestSeq = currentList.first.seq;
    if (oldestSeq == null || oldestSeq <= 1) {
      ref.read(chatHasMoreProvider.notifier).setHasMore(roomId, false);
      return;
    }

    _isFetchingHistory = true;
    try {
      var history = await syncRepo.getMessagesForConversation(
        roomId,
        limit: _pageSize,
        beforeSeq: oldestSeq,
        sync: false,
      );

      if (history.isEmpty) {
        final res = await DioClient().get(
          API.chatHistory,
          queryParameters: {
            'roomId': roomId,
            'before_seq': oldestSeq,
            'lastSeq': oldestSeq,
            'pageSize': _pageSize,
            'direction': 0,
          },
        );
        final data = res.data['data'];
        if (data is! List || data.isEmpty) {
          ref.read(chatHasMoreProvider.notifier).setHasMore(roomId, false);
          return;
        }
        history = data
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();
        await ref.read(localDataSourceProvider).upsertMessages(history);
      }

      ref
          .read(chatHasMoreProvider.notifier)
          .setHasMore(roomId, history.length >= _pageSize);
    } catch (e) {
      log.error('加载历史消息失败: $e');
    } finally {
      _isFetchingHistory = false;
    }
  }

  Future<void> clearRoom(String roomId) async {
    _syncedRoomIds.remove(roomId);
    _syncedSeqByRoom.remove(roomId);
    await ref
        .read(localDataSourceProvider)
        .deleteMessagesForConversation(roomId);
  }

  void markNeedResync(String roomId) {
    _syncedRoomIds.remove(roomId);
    _syncedSeqByRoom.remove(roomId);
  }

  void markAllNeedResync() {
    _syncedRoomIds.clear();
    _syncedSeqByRoom.clear();
  }

  Future<void> removeMessage(String messageId, String roomId) async {
    await ref.read(localDataSourceProvider).deleteMessage(messageId);
  }

  Future<bool> recallMessage(String messageId, String roomId) async {
    try {
      final res = await DioClient().get(
        API.chatRecall,
        queryParameters: {'messageId': messageId},
      );

      if (res.data['code'] == 200) {
        await removeMessage(messageId, roomId);
        return true;
      }
      log.error("撤回消息失败: ${res.data['msg']}");
      return false;
    } catch (e) {
      log.error('撤回消息请求失败: $e');
      return false;
    }
  }

  Future<bool> addFavorite(String messageId) async {
    try {
      final res = await DioClient().post('${API.chatFavoriteAdd}/$messageId');
      return res.data['code'] == 200;
    } catch (e) {
      log.error('收藏消息失败: $e');
      return false;
    }
  }

  int _maxSeq(List<ChatMessage> messages) {
    return messages.fold<int>(
      0,
      (max, msg) => (msg.seq ?? 0) > max ? msg.seq! : max,
    );
  }
}

@riverpod
class ChatHasMore extends _$ChatHasMore {
  @override
  Map<String, bool> build() => {};

  void setHasMore(String roomId, bool hasMore) {
    state = {...state, roomId: hasMore};
  }
}
