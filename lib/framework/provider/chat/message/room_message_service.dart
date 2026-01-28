import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/ChatMessage.dart';
import '../../../logs/talker.dart';
import '../../../protocol/PacketType.dart';
import '../../../protocol/message/RoomMessage.dart';
import '../../ws/ws_controller.dart';

part 'room_message_service.g.dart';

/// 存储每个房间的消息列表
/// key = roomId, value = List<ChatMessage>
@riverpod
class ChatMessages extends _$ChatMessages {
  //跟后端同步 分页大小
  final int _pageSize = 50;

  bool _isFetchingHistory = false;

  // 定义一个内部变量记录已同步的房间
  final Set<String> _syncedRoomIds = {};

  @override
  Map<String, List<ChatMessage>> build() {
    // 1️⃣ 获取 WebSocket 消息流
    final stream = ref.watch(wsControllerProvider.notifier).messageStream;

    // 2️⃣ 订阅消息流，只关注 PacketType.message 类型
    final subscription = stream
        .where((frame) => frame.topic == PacketType.message)
        .map((frame) => frame.data as RoomMessage)
        .listen(_handleRoomMessage);

    // 3️⃣ 当 Provider 销毁时取消订阅，防止内存泄漏
    ref.onDispose(() {
      log.info("聊天消息服务销毁，取消订阅");
      subscription.cancel();
    });

    return {}; // 初始状态为空 Map
  }

  /// 内部处理 RoomMessage 并转换为 ChatMessage
  void _handleRoomMessage(RoomMessage msg) {
    final chatMessage = ChatMessage(
      messageId: msg.messageId,
      roomId: msg.roomId,
      senderId: msg.senderId.toInt(),
      messageType: msg.type,
      content: msg.payload?.content ?? '',
      payload: msg.payload,
      attachments: msg.attachments,
      extra: msg.extra,
      messageStatus: msg.state,
      timestamp: msg.timestamp.toInt(),
      seq: msg.seq.toInt(),
    );

    _addMessage(chatMessage);

    // 2. 【新增逻辑】同步更新房间列表的 VO 状态
    // 获取当前是否正在这个房间里，如果是，未读数不增加
    final activeId = ref.read(activeRoomIdProvider);
    final isCurrentRoom = activeId == chatMessage.roomId;

    ref
        .read(roomListServiceProvider.notifier)
        .updateRoomPosition(chatMessage, isCurrentRoom: isCurrentRoom);
  }

  /// 核心：加载或同步房间消息
  Future<void> syncRoomMessages(String roomId, int? serverLastSeq) async {
    // 获取当前内存中的消息
    final currentList = state[roomId] ?? [];
    int localMaxSeq = currentList.isEmpty ? 0 : (currentList.last.seq ?? 0);

    // ---  拦截逻辑 ---
    // 如果已经同步过，且本地消息已经是最新的（或者服务端没给新 seq），直接返回
    if (_syncedRoomIds.contains(roomId)) {
      if (serverLastSeq == null || localMaxSeq >= serverLastSeq) {
        // 只有当服务端明确给出了更大的 seq 时才继续往下跑拉取逻辑
        return;
      }
    }

    log.info("房间 $roomId 开始同步历史数据 (Local Max Seq: $localMaxSeq)...");

    try {
      final res = await DioClient().get(
        "/chat/history",
        queryParameters: {
          "roomId": roomId,
          "lastSeq": null,
          "pageSize": _pageSize,
          "direction": 0,
        },
      );

      final data = res.data["data"];

      // --- 修复点 2: 无论数据是否为空，只要请求成功就标记为已同步 ---
      _syncedRoomIds.add(roomId);

      if (data is! List) return;

      final List<ChatMessage> history = data
          .map((e) => ChatMessage.fromJson(e))
          .toList();

      // 如果第一次拿到的数据就少于一页，说明根本没有历史消息了
      if (history.length < _pageSize) {
        ref.read(chatHasMoreProvider.notifier).setHasMore(roomId, false);
      } else {
        ref.read(chatHasMoreProvider.notifier).setHasMore(roomId, true);
      }
      // 3. 合并与去重
      final Map<int, ChatMessage> mergeMap = {
        for (var m in currentList)
          if (m.seq != null) m.seq!: m,
        for (var m in history)
          if (m.seq != null) m.seq!: m,
      };

      // 4. 排序
      final sortedList = mergeMap.values.toList()
        ..sort((a, b) => a.seq!.compareTo(b.seq!));

      // 5. 更新状态
      state = {...state, roomId: sortedList};
      log.info("房间 $roomId 同步完成，当前消息数: ${sortedList.length}");
    } catch (e) {
      log.error("同步房间 $roomId 失败: $e");
      // 注意：如果失败了，不需要 add 到 _syncedRoomIds，这样下次切换还能重试
    }
  }

  Future<void> loadMoreHistory(String roomId) async {
    if (_isFetchingHistory) return;

    // 💡 先检查一下是否还有更多，如果没有，直接返回
    final hasMore = ref.read(chatHasMoreProvider)[roomId] ?? true;
    if (!hasMore) return;

    final currentList = state[roomId] ?? [];
    if (currentList.isEmpty) return;

    // 1. 找到当前本地最早的一条消息的 seq
    // 你的列表是按 seq 从小到大排的，所以第一条就是最早的
    final int? oldestSeq = currentList.first.seq;
    if (oldestSeq == null || oldestSeq <= 1) {
      log.info("已经到头了 不请求了");
      return;
    } // 已经到头了

    _isFetchingHistory = true;
    log.info("开始拉取房间 $roomId 的历史消息，起始 seq: $oldestSeq");

    try {
      final res = await DioClient().get(
        "/chat/history",
        queryParameters: {
          "roomId": roomId,
          "lastSeq": oldestSeq, // 告诉服务器从哪条开始往前找
          "pageSize": _pageSize, // 分页大小
          "direction": 0, // 0 通常代表向旧的消息方向（向上）拉取
        },
      );
      final data = res.data["data"];
      if (data is! List || data.isEmpty) {
        log.info("没有更多历史消息了");
        return;
      }
      //模拟加载
      await Future.delayed(Duration(seconds: 4));

      final List<ChatMessage> history = data
          .map((e) => ChatMessage.fromJson(e))
          .toList();

      if (history.length < _pageSize) {
        ref.read(chatHasMoreProvider.notifier).setHasMore(roomId, false);
      } else {
        // 也可以显式设为 true，防止之前被误设为 false
        ref.read(chatHasMoreProvider.notifier).setHasMore(roomId, true);
      }

      if (history.isNotEmpty) {
        // 2. 合并数据并去重
        final Map<int, ChatMessage> mergeMap = {
          for (var m in history)
            if (m.seq != null) m.seq!: m,
          for (var m in currentList)
            if (m.seq != null) m.seq!: m,
        };

        // 3. 排序（保持 seq 从小到大）
        final sortedList = mergeMap.values.toList()
          ..sort((a, b) => a.seq!.compareTo(b.seq!));

        // 4. 更新状态
        state = {...state, roomId: sortedList};
        log.info("历史消息加载成功，新增 ${history.length} 条");
      }
    } catch (e) {
      log.error("加载历史消息失败: $e");
    } finally {
      _isFetchingHistory = false;
    }
  }

  ///添加消息到房间
  void _addMessage(ChatMessage msg) {
    final roomId = msg.roomId ?? "system";
    final currentList = state[roomId] ?? [];

    //去重检查
    if (currentList.any((m) => m.seq == msg.seq)) return;

    //插入新消息
    List<ChatMessage> newList = [...currentList, msg];

    // 只有当新消息 seq 小于最后一条时（乱序到达），才需要排序
    if (currentList.isNotEmpty &&
        (msg.seq ?? 0) < (currentList.last.seq ?? 0)) {
      newList.sort((a, b) => (a.seq ?? 0).compareTo(b.seq ?? 0));
    }
    state = {...state, roomId: newList};
  }

  /// 清空某个房间消息
  void clearRoom(String roomId) {
    state = {...state, roomId: []};
  }

  /// 获取总消息数量，用于调试或内存监控
  int get totalMessageCount {
    return state.values.fold(0, (sum, list) => sum + list.length);
  }
}

// 存储每个房间的“加载更多”状态
// key: roomId, value: 是否还有更多
@riverpod
class ChatHasMore extends _$ChatHasMore {
  @override
  Map<String, bool> build() {
    return {}; // 默认不确定，或者可以在 syncRoomMessages 时初始化
  }

  // 设置某个房间的状态
  void setHasMore(String roomId, bool hasMore) {
    state = {...state, roomId: hasMore};
  }
}
