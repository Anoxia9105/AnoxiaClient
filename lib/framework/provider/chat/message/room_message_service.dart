import 'dart:async';
import 'dart:collection';
import 'dart:math' show max;

import 'package:anoxia/common/utils/media_url_util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:anoxia/framework/local_cache/session_epoch.dart';
import 'package:anoxia/framework/codec/v6/im_packet_v6.dart';
import 'package:anoxia/framework/provider/core/favorite_repository_provider.dart';
import 'package:anoxia/framework/provider/core/message_repository_provider.dart';
import 'package:anoxia/framework/provider/core/chat_repository_provider.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/auth/token_provider.dart';
import 'package:anoxia/framework/provider/chat/call/call_status_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/effect/chat_effect_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/chat_message.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
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

final optimisticRoomMessagesProvider =
    NotifierProvider<OptimisticRoomMessages, Map<String, List<ChatMessage>>>(
      OptimisticRoomMessages.new,
    );

class OptimisticRoomMessages extends Notifier<Map<String, List<ChatMessage>>> {
  static const int _maximumPerRoom = 100;

  @override
  Map<String, List<ChatMessage>> build() => const {};

  void upsert(ChatMessage message) {
    final roomId = message.roomId;
    final key = message.clientMsgId ?? message.messageId;
    if (roomId == null || roomId.isEmpty || key == null || key.isEmpty) return;

    final messages = [...?state[roomId]];
    final index = messages.indexWhere(
      (item) =>
          item.clientMsgId == key ||
          item.messageId == key ||
          (message.messageId != null &&
              (item.messageId == message.messageId ||
                  item.clientMsgId == message.messageId)),
    );
    if (index >= 0) {
      messages[index] = message;
    } else {
      messages.add(message);
    }
    if (messages.length > _maximumPerRoom) {
      messages.removeRange(0, messages.length - _maximumPerRoom);
    }
    state = {...state, roomId: messages};
  }

  void remove(ChatMessage message) {
    final roomId = message.roomId;
    if (roomId == null || !state.containsKey(roomId)) return;
    final ids = {message.messageId, message.clientMsgId}
      ..removeWhere((id) => id == null || id.isEmpty);
    final messages = state[roomId]!
        .where(
          (item) =>
              !ids.contains(item.messageId) && !ids.contains(item.clientMsgId),
        )
        .toList();
    final next = {...state};
    if (messages.isEmpty) {
      next.remove(roomId);
    } else {
      next[roomId] = messages;
    }
    state = next;
  }

  void markFailed(ChatMessage message) {
    upsert(message.copyWith(deliveryStatus: DeliveryStatus.failed));
  }

  void removePersisted(Iterable<ChatMessage> persisted) {
    final persistedIdsByRoom = <String, Set<String>>{};
    for (final message in persisted) {
      final roomId = message.roomId;
      if (roomId == null || roomId.isEmpty) continue;
      final ids = persistedIdsByRoom.putIfAbsent(roomId, () => <String>{});
      final messageId = message.messageId;
      final clientMsgId = message.clientMsgId;
      if (messageId != null && messageId.isNotEmpty) ids.add(messageId);
      if (clientMsgId != null && clientMsgId.isNotEmpty) ids.add(clientMsgId);
    }
    if (persistedIdsByRoom.isEmpty) return;

    final next = {...state};
    var changed = false;
    for (final entry in persistedIdsByRoom.entries) {
      final optimistic = next[entry.key];
      if (optimistic == null || optimistic.isEmpty) continue;
      final remaining = optimistic
          .where(
            (message) =>
                !entry.value.contains(message.messageId) &&
                !entry.value.contains(message.clientMsgId),
          )
          .toList();
      if (remaining.length == optimistic.length) continue;
      changed = true;
      if (remaining.isEmpty) {
        next.remove(entry.key);
      } else {
        next[entry.key] = remaining;
      }
    }
    if (changed) state = next;
  }
}

List<ChatMessage> mergeOptimisticMessages(
  List<ChatMessage> persisted,
  List<ChatMessage> optimistic,
) {
  if (optimistic.isEmpty) return persisted;
  final knownIds = <String>{};
  for (final message in persisted) {
    final messageId = message.messageId;
    final clientMsgId = message.clientMsgId;
    if (messageId != null && messageId.isNotEmpty) knownIds.add(messageId);
    if (clientMsgId != null && clientMsgId.isNotEmpty) {
      knownIds.add(clientMsgId);
    }
  }

  final merged = [...persisted];
  for (final message in optimistic) {
    final duplicate =
        (message.messageId?.isNotEmpty == true &&
            knownIds.contains(message.messageId)) ||
        (message.clientMsgId?.isNotEmpty == true &&
            knownIds.contains(message.clientMsgId));
    if (!duplicate) merged.add(message);
  }
  merged.sort((a, b) => (a.timestamp ?? 0).compareTo(b.timestamp ?? 0));
  return merged;
}

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
  // 已加载房间保留五分钟，切回时同步读取上一批数据；账号切换立即重建。
  if (ref.watch(tokenCacheProvider) == null) return Stream.value(const []);
  final cache = ref.keepAlive();
  Timer? expiry;
  ref.onCancel(() {
    expiry = Timer(const Duration(minutes: 5), cache.close);
  });
  ref.onResume(() {
    expiry?.cancel();
  });
  ref.onDispose(() => expiry?.cancel());
  final limit = ref.watch(
    chatMessageWindowLimitsProvider.select(
      (limits) => limits[roomId] ?? _initialMessageWindowSize,
    ),
  );
  return ref
      .read(chatRepositoryProvider)
      .watchMessages(roomId, limit: limit)
      .map((messages) {
        scheduleMicrotask(() {
          if (!ref.mounted) return;
          ref
              .read(optimisticRoomMessagesProvider.notifier)
              .removePersisted(messages);
        });
        return messages;
      });
}

final roomMessageIndexProvider =
    Provider.family<Map<String, ChatMessage>, String>((ref, roomId) {
      final messages =
          ref.watch(roomMessagesProvider(roomId)).value ?? const [];
      final optimistic =
          ref.watch(optimisticRoomMessagesProvider)[roomId] ?? const [];
      final index = <String, ChatMessage>{};
      for (final message in mergeOptimisticMessages(messages, optimistic)) {
        final messageId = message.messageId;
        final clientMsgId = message.clientMsgId;
        if (messageId != null) index[messageId] = message;
        if (clientMsgId != null) index[clientMsgId] = message;
      }
      return index;
    });

/// 引用消息查询参数
typedef QuotedMessageLookupArgs = ({String roomId, String messageId});

/// 查询被引用消息：优先返回当前加载窗口内的消息（同步可读，无闪烁）；
/// 窗口外则查本地库——本地库也查不到说明消息已被撤回/删除（或从未同步）。
final quotedMessageLookupProvider = FutureProvider.autoDispose
    .family<ChatMessage?, QuotedMessageLookupArgs>((ref, args) {
      final inWindow = ref.watch(
        roomMessageIndexProvider(args.roomId),
      )[args.messageId];
      if (inWindow != null) return inWindow;
      return ref.read(localDataSourceProvider).getMessageById(args.messageId);
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
  Future<void> _messageWriteQueue = Future<void>.value();

  Future<T> _enqueueMessageWrite<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    final epoch = SessionEpoch.instance.value;
    _messageWriteQueue = _messageWriteQueue.then((_) async {
      try {
        if (!ref.mounted || epoch != SessionEpoch.instance.value) {
          throw StateError('stale session message task');
        }
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  /// 暴露当前正在加载历史消息的房间集合，供 UI 层读取
  Set<String> get fetchingHistoryRoomIds =>
      UnmodifiableSetView(_fetchingHistoryRoomIds);

  @override
  void build() {
    final stream = ref.read(wsControllerProvider.notifier).messageStream;
    final subscription = stream
        .where(
          (frame) =>
              frame.topic == PacketType.message && frame.data is RoomMessage,
        )
        .map((frame) => frame.data as RoomMessage)
        .listen(_handleIncomingMessage);

    ref.onDispose(subscription.cancel);
  }

  void _handleIncomingMessage(RoomMessage msg) {
    final chatMessage = ChatMessage.fromRoomMessage(msg);
    unawaited(_processIncomingMessage(chatMessage, DateTime.now()));
  }

  Future<void> _processIncomingMessage(
    ChatMessage chatMessage,
    DateTime observedAt,
  ) async {
    final epoch = SessionEpoch.instance.value;
    final currentUser = ref.read(authControllerProvider).value;
    var effectMessage = chatMessage;
    try {
      final inserted = await _enqueueMessageWrite(() async {
        final local = ref.read(localDataSourceProvider);
        // 排队期间窗口可能已经最小化，落库前重新判断真正的阅读状态。
        final isReading =
            ref.read(activelyViewedRoomIdProvider) == chatMessage.roomId;
        if (currentUser != null &&
            chatMessage.senderId == currentUser.userId &&
            chatMessage.clientMsgId?.isNotEmpty == true) {
          final original = await local.getMessageByClientMsgId(
            chatMessage.clientMsgId!,
          );
          // 回显先到时也沿用本地原发送时间，避免离线旧消息用新时间补播。
          if (original != null) {
            effectMessage = chatMessage.copyWith(timestamp: original.timestamp);
          }
        }
        return local.applyIncomingMessage(
          chatMessage,
          incrementUnread:
              !isReading && currentUser?.userId != chatMessage.senderId,
          clearUnread: isReading,
        );
      });
      if (!ref.mounted || epoch != SessionEpoch.instance.value) return;
      // 自己的回显可能已经按 clientMsgId 落过库，仍需与 ACK 归一去重。
      if (inserted ||
          (currentUser != null && chatMessage.senderId == currentUser.userId)) {
        ref
            .read(chatEffectDispatcherProvider)
            .offer(effectMessage, observedAt: observedAt);
      }
      if (!inserted) return;
    } catch (error, stackTrace) {
      debugLog('缓存入站消息失败', error, stackTrace);
      return;
    }
    _handleSystemMessageSideEffects(chatMessage);

    ref
        .read(roomListServiceProvider.notifier)
        .updateRoomPosition(chatMessage, ref.read(activeRoomIdProvider));
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
    ref.read(optimisticRoomMessagesProvider.notifier).upsert(msg);
    // 附件还是本地路径（乐观发送中、尚未拿到服务器 URL）的消息**只活在内存里**。
    // 一旦落库，ws_controller 的 _resendCachedOutbounds 在重连时会把 SENDING
    // 的行原样重放，本地路径就被当成 URL 发给了服务端。
    // 上传完成后发送侧会用服务器 URL 再 upsert 一次，那时才真正持久化。
    if (_hasPendingLocalMedia(msg)) return;
    final epoch = SessionEpoch.instance.value;
    unawaited(
      _enqueueMessageWrite(
        () => ref.read(chatRepositoryProvider).cacheLocalMessage(msg),
      ).catchError((Object error, StackTrace stackTrace) {
        if (!ref.mounted || epoch != SessionEpoch.instance.value) return;
        ref.read(optimisticRoomMessagesProvider.notifier).markFailed(msg);
        debugLog('缓存本地发送消息失败', error, stackTrace);
      }),
    );
  }

  /// 消息的媒体附件里是否还有未上传完成的本地路径
  bool _hasPendingLocalMedia(ChatMessage msg) {
    final attachments = msg.payload?.mediaAttachments;
    if (attachments == null || attachments.isEmpty) return false;
    return attachments.any(
      (attachment) => isPendingLocalMediaUrl(attachment.url),
    );
  }

  Future<void> handleTimeout(String roomId, String clientMsgId) async {
    await _enqueueMessageWrite(() async {
      final local = ref.read(localDataSourceProvider);
      final message = await local.getMessageByClientMsgId(clientMsgId);
      if (message == null || message.deliveryStatus != DeliveryStatus.sending) {
        return;
      }
      await local.upsertMessage(
        message.copyWith(deliveryStatus: DeliveryStatus.failed),
      );
    });
  }

  Future<void> markAcked({
    required String clientMsgId,
    String? roomId,
    String? messageId,
    int? seq,
    int? timestamp,
  }) async {
    final observedAt = DateTime.now();
    final epoch = SessionEpoch.instance.value;
    ChatMessage? effectMessage;
    await _enqueueMessageWrite(() async {
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
      // 新鲜度沿用原发送时间，防止离线重试的旧祝福因新 ACK 时间补播。
      effectMessage = message.copyWith(
        messageId: messageId,
        deliveryStatus: DeliveryStatus.sent,
      );
    });
    if (!ref.mounted || epoch != SessionEpoch.instance.value) return;
    if (effectMessage case final message?) {
      ref
          .read(chatEffectDispatcherProvider)
          .offer(message, observedAt: observedAt);
    }
  }

  Future<void> markFailedByClientMsgId(
    String clientMsgId, {
    bool retryable = true,
  }) async {
    await _enqueueMessageWrite(() async {
      final local = ref.read(localDataSourceProvider);
      final message = await local.getMessageByClientMsgId(clientMsgId);
      if (message == null || message.deliveryStatus == DeliveryStatus.sent) {
        return;
      }
      await local.upsertMessage(
        message.copyWith(deliveryStatus: DeliveryStatus.failed),
      );
      if (!retryable) await local.markOutgoingTerminal(message.messageId!);
    });
  }

  Future<void> syncRoomMessages(String roomId, int? serverLastSeq) async {
    final syncRepo = ref.read(chatRepositoryProvider);
    final localMessages = await syncRepo.getMessagesForConversation(
      roomId,
      limit: _pageSize,
      sync: false,
    );
    final localMaxSeq = _maxSeq(localMessages);
    final watermark = await ref
        .read(localDataSourceProvider)
        .messageSyncWatermark(roomId);

    ref
        .read(chatHasMoreProvider.notifier)
        .setHasMore(roomId, localMessages.length >= _pageSize);

    final targetSeq = max(localMaxSeq, serverLastSeq ?? 0);
    if (watermark >= targetSeq) {
      await syncRepo.syncMessages(roomId);
      _syncedRoomIds.add(roomId);
      _syncedSeqByRoom[roomId] = localMaxSeq;
      return;
    }

    try {
      await syncRepo.syncMessages(roomId);
      // 进度按实际落库的 max seq 记录，而非服务端最新 seq：
      // 单批最多拉 100 条，若积压超过一批，本次只追了一部分，
      // 下次进入房间仍会继续拉取，直到追平服务端最新 seq。
      final refreshed = await syncRepo.getMessagesForConversation(
        roomId,
        limit: _pageSize,
        sync: false,
      );
      final actualMaxSeq = _maxSeq(refreshed);
      _syncedRoomIds.add(roomId);
      _syncedSeqByRoom[roomId] = actualMaxSeq;

      ref
          .read(chatHasMoreProvider.notifier)
          .setHasMore(roomId, refreshed.length >= _pageSize);
    } catch (e) {
      debugLog('同步房间 $roomId 失败: $e');
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
      final syncRepo = ref.read(chatRepositoryProvider);
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
        history = await ref
            .read(messageRepositoryProvider)
            .fetchHistory(roomId, beforeSeq: oldestSeq, pageSize: _pageSize);
        if (history.isEmpty) {
          _lastLoadedHistoryBoundary[roomId] = oldestSeq;
          ref.read(chatHasMoreProvider.notifier).setHasMore(roomId, false);
          return;
        }
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
      debugLog('加载历史消息失败: $e');
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
    // 乐观缓存只活在内存里，不随 DB 删除自动消失；不清理会导致已撤回的
    // 待发送消息仍通过 mergeOptimisticMessages 显示在气泡列表里。
    ref
        .read(optimisticRoomMessagesProvider.notifier)
        .remove(
          ChatMessage(
            messageId: messageId,
            clientMsgId: messageId,
            roomId: roomId,
          ),
        );
    await ref.read(localDataSourceProvider).deleteMessage(messageId);
  }

  Future<bool> recallMessage(String messageId, String roomId) async {
    try {
      final requestId = 'recall_${DateTime.now().microsecondsSinceEpoch}';
      final ack = await ref
          .read(wsControllerProvider.notifier)
          .sendCommand(
            ImPacketV6.encodeRecallFrame(
              roomId,
              messageId,
              requestId: requestId,
            ),
            requestId: requestId,
          );
      final ok = ack.isSuccess;

      if (ok) {
        await removeMessage(messageId, roomId);
        return true;
      }
      return false;
    } catch (e) {
      debugLog('撤回消息请求失败: $e');
      return false;
    }
  }

  Future<bool> addFavorite(String messageId) async {
    return ref.read(favoriteRepositoryProvider).addFavorite(messageId);
  }

  int _maxSeq(List<ChatMessage> messages) {
    return messages.fold<int>(
      0,
      (max, msg) => (msg.seq ?? 0) > max ? msg.seq! : max,
    );
  }
}

@Riverpod(keepAlive: true)
class ChatHasMore extends _$ChatHasMore {
  @override
  Map<String, bool> build() => {};

  void setHasMore(String roomId, bool hasMore) {
    state = {...state, roomId: hasMore};
  }
}
