import 'dart:async';
import 'dart:collection';

import 'package:anoxia/common/constants/api.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/call/call_status_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/chat_message.dart';
import '../../../logs/talker.dart';
import '../../../protocol/packet_type.dart';
import '../../../protocol/message/room_message.dart';
import '../../ws/ws_controller.dart';

part 'room_message_service.g.dart';

const int _initialMessageWindowSize = 100;
const int _maximumMessageWindowSize = 1000;

final chatMessageWindowLimitsProvider =
    NotifierProvider<ChatMessageWindowLimits, Map<String, int>>(
      ChatMessageWindowLimits.new,
    );

class ChatMessageWindowLimits extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => const {};

  int limitFor(String roomId) => state[roomId] ?? _initialMessageWindowSize;

  bool expand(String roomId, [int amount = 50]) {
    final current = limitFor(roomId);
    if (current >= _maximumMessageWindowSize) return false;
    state = {
      ...state,
      roomId: (current + amount).clamp(1, _maximumMessageWindowSize),
    };
    return true;
  }

  void reset(String roomId) {
    if (!state.containsKey(roomId)) return;
    state = {...state}..remove(roomId);
  }
}

@riverpod
Stream<List<ChatMessage>> roomMessages(Ref ref, String roomId) {
  final limit = ref.watch(
    chatMessageWindowLimitsProvider.select(
      (limits) => limits[roomId] ?? _initialMessageWindowSize,
    ),
  );
  return ref.read(syncRepositoryProvider).watchMessages(roomId, limit: limit);
}

final roomMessageIndexProvider =
    Provider.family<Map<String, ChatMessage>, String>((ref, roomId) {
      final messages =
          ref.watch(roomMessagesProvider(roomId)).value ?? const [];
      final index = <String, ChatMessage>{};
      for (final message in messages) {
        final messageId = message.messageId;
        final clientMsgId = message.clientMsgId;
        if (messageId != null) index[messageId] = message;
        if (clientMsgId != null) index[clientMsgId] = message;
      }
      return index;
    });

/// 历史消息加载状态追踪
///
/// value 为 null 表示无错误，非 null 表示加载失败的错误信息
final historyLoadErrorProvider =
    NotifierProvider<HistoryLoadErrorNotifier, Map<String, String?>>(
      HistoryLoadErrorNotifier.new,
    );

class HistoryLoadErrorNotifier extends Notifier<Map<String, String?>> {
  @override
  Map<String, String?> build() => {};

  void setError(String roomId, String? error) {
    if (error == null) {
      if (!state.containsKey(roomId)) return;
      state = {...state}..remove(roomId);
    } else {
      state = {...state, roomId: error};
    }
  }
}

@Riverpod(keepAlive: true)
class ChatMessages extends _$ChatMessages {
  static const int _pageSize = 50;

  final Set<String> _fetchingHistoryRoomIds = {};
  final Map<String, int> _lastLoadedHistoryBoundary = {};
  final Set<String> _syncedRoomIds = {};
  final Map<String, int> _syncedSeqByRoom = {};

  /// 暴露当前正在加载历史消息的房间集合，供 UI 层读取
  Set<String> get fetchingHistoryRoomIds =>
      UnmodifiableSetView(_fetchingHistoryRoomIds);

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
    unawaited(_processIncomingMessage(chatMessage));
  }

  Future<void> _processIncomingMessage(ChatMessage chatMessage) async {
    final activeRoomId = ref.read(activeRoomIdProvider);
    final currentUser = ref.read(authControllerProvider).value;
    final incrementUnread =
        activeRoomId != chatMessage.roomId &&
        currentUser?.userId != chatMessage.senderId;
    try {
      final inserted = await ref
          .read(localDataSourceProvider)
          .applyIncomingMessage(
            chatMessage,
            incrementUnread: incrementUnread,
            clearUnread: activeRoomId == chatMessage.roomId,
          );
      if (!inserted) return;
    } catch (error, stackTrace) {
      log.error('缓存入站消息失败', error, stackTrace);
      return;
    }
    _handleSystemMessageSideEffects(chatMessage);

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
    // 先检查是否已同步到最新，避免不必要的 DB 查询
    if (_syncedRoomIds.contains(roomId) &&
        serverLastSeq != null &&
        (_syncedSeqByRoom[roomId] ?? 0) >= serverLastSeq) {
      return;
    }

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
    if (_fetchingHistoryRoomIds.contains(roomId)) return;
    if (!(ref.read(chatHasMoreProvider)[roomId] ?? true)) return;

    // 必须在第一个 await 前加锁；否则首次缓存尚未就绪时，同一帧的多次
    // onPaint 回调会同时进入分页，造成数据库写入和列表重建风暴。
    _fetchingHistoryRoomIds.add(roomId);
    // 清除之前的错误状态
    ref.read(historyLoadErrorProvider.notifier).setError(roomId, null);

    try {
      final syncRepo = ref.read(syncRepositoryProvider);
      final currentList =
          ref.read(roomMessagesProvider(roomId)).value ??
          await syncRepo.getMessagesForConversation(
            roomId,
            limit: ref
                .read(chatMessageWindowLimitsProvider.notifier)
                .limitFor(roomId),
            sync: false,
          );
      if (currentList.isEmpty) return;

      final int? oldestSeq = currentList.first.seq;
      if (oldestSeq == null || oldestSeq <= 1) {
        ref.read(chatHasMoreProvider.notifier).setHasMore(roomId, false);
        return;
      }
      // 扩大监听窗口到 UI 收到新快照之间存在一个短间隙。记录边界可阻止
      // 这段间隙内再次请求完全相同的一页。
      if (_lastLoadedHistoryBoundary[roomId] == oldestSeq) return;

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
          _lastLoadedHistoryBoundary[roomId] = oldestSeq;
          ref.read(chatHasMoreProvider.notifier).setHasMore(roomId, false);
          return;
        }
        history = data
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();
        await ref.read(localDataSourceProvider).upsertMessages(history);
      }

      final expanded = ref
          .read(chatMessageWindowLimitsProvider.notifier)
          .expand(roomId, history.length);
      _lastLoadedHistoryBoundary[roomId] = oldestSeq;

      ref
          .read(chatHasMoreProvider.notifier)
          .setHasMore(roomId, expanded && history.length >= _pageSize);
    } catch (e) {
      log.error('加载历史消息失败: $e');
      ref
          .read(historyLoadErrorProvider.notifier)
          .setError(roomId, 'chat_history_load_failed'.tr());
    } finally {
      _fetchingHistoryRoomIds.remove(roomId);
    }
  }

  /// 重试加载历史消息
  Future<void> retryHistoryLoad(String roomId) async {
    _lastLoadedHistoryBoundary.remove(roomId);
    await loadMoreHistory(roomId);
  }

  Future<void> clearRoom(String roomId) async {
    _syncedRoomIds.remove(roomId);
    _syncedSeqByRoom.remove(roomId);
    _lastLoadedHistoryBoundary.remove(roomId);
    ref.read(chatMessageWindowLimitsProvider.notifier).reset(roomId);
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
