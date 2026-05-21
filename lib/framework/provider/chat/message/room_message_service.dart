import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/protocol/message/MessageEunm.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/ChatMessage.dart';
import '../../../logs/talker.dart';
import '../../../protocol/PacketType.dart';
import '../../../protocol/message/RoomMessage.dart';
import '../../ws/ws_controller.dart';

part 'room_message_service.g.dart';

/// 聊天消息存储器
///
/// 维护所有房间的消息列表（按 roomId 分组），支持消息同步、加载历史、撤回等操作。
/// 采用 keepAlive 模式，确保消息缓存在全局共享。
@Riverpod(keepAlive: true)
class ChatMessages extends _$ChatMessages {
  /// 每次加载历史的页大小
  final int _pageSize = 50;

  /// 是否正在拉取历史消息（防止并发请求）
  bool _isFetchingHistory = false;

  /// 已同步过的房间 ID 集合，用于判断是否需要增量拉取
  final Set<String> _syncedRoomIds = {};

  @override
  Map<String, List<ChatMessage>> build() {
    // 订阅 WebSocket 消息流，只处理普通消息类型
    final stream = ref.watch(wsControllerProvider.notifier).messageStream;

    final subscription = stream
        .where((frame) => frame.topic == PacketType.message)
        .map((frame) => frame.data as RoomMessage)
        .listen(_handleIncomingMessage);

    // Provider 销毁时取消订阅，防止内存泄漏
    ref.onDispose(() => subscription.cancel());

    return {};
  }

  /// 纯粹的协议层向领域层数据转换与分发
  void _handleIncomingMessage(RoomMessage msg) {
    final chatMessage = ChatMessage.fromRoomMessage(msg);

    // 1. 更新当前缓存状态
    upsertMessage(chatMessage);

    // 2. 拿到当前最干净、最轻量的活跃房间 ID 指针
    final activeRoomId = ref.read(activeRoomIdProvider);

    // 3. 触发房间列表的位置更新（不越权管房间内部状态）
    ref
        .read(roomListServiceProvider.notifier)
        .updateRoomPosition(chatMessage, activeRoomId);
  }

  /// 插入或更新消息（状态机核心）
  void upsertMessage(ChatMessage msg) {
    final roomId = msg.roomId ?? 'system';
    final currentList = state[roomId] ?? [];
    List<ChatMessage> newList = [...currentList];

    int index = -1;
    if (msg.clientMsgId != null) {
      index = newList.indexWhere((m) => m.clientMsgId == msg.clientMsgId);
    }
    if (index == -1 && msg.messageId != null) {
      index = newList.indexWhere((m) => m.messageId == msg.messageId);
    }

    if (index != -1) {
      newList[index] = msg;
    } else {
      if (newList.any((m) => m.messageId == msg.messageId)) return;
      newList.add(msg);
    }

    // 排序逻辑：发送中(seq=0)在最后，其余按 seq 升序
    newList.sort((a, b) {
      if ((a.seq ?? 0) == 0 || (b.seq ?? 0) == 0) {
        return (a.timestamp ?? 0).compareTo(b.timestamp ?? 0);
      }
      return a.seq!.compareTo(b.seq!);
    });

    state = {...state, roomId: newList};
  }

  /// 处理消息发送超时
  void handleTimeout(String roomId, String clientMsgId) {
    final list = state[roomId] ?? [];
    final idx = list.indexWhere((m) => m.clientMsgId == clientMsgId);
    if (idx != -1 && list[idx].deliveryStatus == DeliveryStatus.sending) {
      final newList = [...list];
      newList[idx] = newList[idx].copyWith(
        deliveryStatus: DeliveryStatus.failed,
      );
      state = {...state, roomId: newList};
    }
  }

  /// 同步房间增量消息
  Future<void> syncRoomMessages(String roomId, int? serverLastSeq) async {
    final currentList = state[roomId] ?? [];
    int localMaxSeq = currentList.isEmpty ? 0 : (currentList.last.seq ?? 0);

    if (_syncedRoomIds.contains(roomId) &&
        (serverLastSeq == null || localMaxSeq >= serverLastSeq)) {
      return;
    }

    try {
      final res = await DioClient().get(
        API.chatHistory,
        queryParameters: {
          'roomId': roomId,
          'lastSeq': null,
          'pageSize': _pageSize,
          'direction': 0,
        },
      );

      _syncedRoomIds.add(roomId);
      final data = res.data['data'];
      if (data is! List) return;

      final List<ChatMessage> history = data
          .map((e) => ChatMessage.fromJson(e))
          .toList();
      ref
          .read(chatHasMoreProvider.notifier)
          .setHasMore(roomId, history.length >= _pageSize);

      final Map<String, ChatMessage> mergeMap = {};
      for (var m in currentList) {
        final key = (m.seq != null && m.seq != 0)
            ? m.seq.toString()
            : m.messageId;
        if (key != null) mergeMap[key] = m;
      }
      for (var m in history) {
        final key = m.seq?.toString() ?? m.messageId;
        if (key != null) mergeMap[key] = m;
      }

      final sortedList = mergeMap.values.toList()
        ..sort((a, b) => a.seq!.compareTo(b.seq!));
      state = {...state, roomId: sortedList};
    } catch (e) {
      log.error('同步房间 $roomId 失败: $e');
    }
  }

  /// 向前加载更多历史记录
  Future<void> loadMoreHistory(String roomId) async {
    if (_isFetchingHistory) return;
    if (!(ref.read(chatHasMoreProvider)[roomId] ?? true)) return;

    final currentList = state[roomId] ?? [];
    if (currentList.isEmpty) return;

    final int? oldestSeq = currentList.first.seq;
    if (oldestSeq == null || oldestSeq <= 1) return;

    _isFetchingHistory = true;
    try {
      final res = await DioClient().get(
        API.chatHistory,
        queryParameters: {
          'roomId': roomId,
          'lastSeq': oldestSeq,
          'pageSize': _pageSize,
          'direction': 0,
        },
      );

      final data = res.data["data"];
      if (data is! List || data.isEmpty) return;

      final List<ChatMessage> history = data
          .map((e) => ChatMessage.fromJson(e))
          .toList();
      ref
          .read(chatHasMoreProvider.notifier)
          .setHasMore(roomId, history.length >= _pageSize);

      final Map<int, ChatMessage> mergeMap = {
        for (var m in history)
          if (m.seq != null) m.seq!: m,
        for (var m in currentList)
          if (m.seq != null) m.seq!: m,
      };

      final sortedList = mergeMap.values.toList()
        ..sort((a, b) => a.seq!.compareTo(b.seq!));
      state = {...state, roomId: sortedList};
    } catch (e) {
      log.error('加载历史消息失败: $e');
    } finally {
      _isFetchingHistory = false;
    }
  }

  /// 撤回消息
  void clearRoom(String roomId) =>
      (_syncedRoomIds.remove(roomId), state = {...state, roomId: []});

  /// 标记房间需要重新同步（如收到系统消息导致状态变化时调用）
  void markNeedResync(String roomId) => _syncedRoomIds.remove(roomId);

  /// 全局标记所有房间需要重新同步（如网络重连时调用）
  void markAllNeedResync() => _syncedRoomIds.clear();

  /// 删除消息（如撤回成功后从列表移除）
  void removeMessage(String messageId, String roomId) {
    final currentList = state[roomId] ?? [];
    final newList = currentList
        .where((msg) => msg.messageId != messageId)
        .toList();
    if (newList.length != currentList.length) {
      state = {...state, roomId: newList};
    }
  }

  /// 撤回消息
  Future<bool> recallMessage(String messageId, String roomId) async {
    try {
      final res = await DioClient().get(
        API.chatRecall,
        queryParameters: {'messageId': messageId},
      );

      if (res.data['code'] == 200) {
        removeMessage(messageId, roomId);
        return true;
      } else {
        log.error("撤回消息失败: ${res.data['msg']}");
        return false;
      }
    } catch (e) {
      log.error('撤回消息请求失败: $e');
      return false;
    }
  }

  /// 收藏消息
  Future<bool> addFavorite(String messageId) async {
    try {
      final res = await DioClient().post('${API.chatFavoriteAdd}/$messageId');
      return res.data['code'] == 200;
    } catch (e) {
      log.error('收藏消息失败: $e');
      return false;
    }
  }
}

/// 房间是否还有更多历史消息的状态
@riverpod
class ChatHasMore extends _$ChatHasMore {
  @override
  Map<String, bool> build() => {};

  /// 设置某个房间的加载更多状态
  void setHasMore(String roomId, bool hasMore) {
    state = {...state, roomId: hasMore};
  }
}
