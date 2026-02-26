import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/protocol/message/MessageEunm.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/ChatMessage.dart';
import '../../../logs/talker.dart';
import '../../../protocol/PacketType.dart';
import '../../../protocol/message/RoomMessage.dart';
import '../../ws/ws_controller.dart';

part 'room_message_service.g.dart';

/// 存储每个房间的消息列表
/// key = roomId, value = List<ChatMessage>
@Riverpod(keepAlive: true)
class ChatMessages extends _$ChatMessages {
  final int _pageSize = 50;
  // 是否正在拉取历史消息
  bool _isFetchingHistory = false;
  // 定义一个内部变量记录已同步的房间
  final Set<String> _syncedRoomIds = {};
  // 生成 UUID 的工具
  final _uuid = const Uuid();

  @override
  Map<String, List<ChatMessage>> build() {
    // 1️ 获取 WebSocket 消息流
    final stream = ref.watch(wsControllerProvider.notifier).messageStream;

    // 2️ 订阅消息流，只关注 PacketType.message 类型
    final subscription = stream
        .where((frame) => frame.topic == PacketType.message)
        .map((frame) => frame.data as RoomMessage)
        .listen(_handleRoomMessage);

    // 3️ 当 Provider 销毁时取消订阅，防止内存泄漏
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
      clientMsgId: msg.clientMsgId,
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
    upsertMessage(chatMessage);
    ref
        .read(roomListServiceProvider.notifier)
        .updateRoomPosition(chatMessage, ref.read(activeRoomProvider));
  }

  /// 核心：通过 clientMsgId 找到本地消息并替换
  void upsertMessage(ChatMessage msg) {
    final roomId = msg.roomId ?? "system";
    final currentList = state[roomId] ?? [];
    List<ChatMessage> newList = [...currentList];

    // 找“暗号”
    int index = -1;
    if (msg.clientMsgId != null) {
      index = newList.indexWhere((m) => m.clientMsgId == msg.clientMsgId);
    }
    //  补丁：如果 clientMsgId 没找到，尝试用真正的 messageId 找（防止 WS 跑得比本地快）
    if (index == -1 && msg.messageId != null) {
      index = newList.indexWhere((m) => m.messageId == msg.messageId);
    }

    if (index != -1) {
      // 【替换逻辑】用服务器回传的真数据（messageId, seq）覆盖本地假数据
      newList[index] = msg;
    } else {
      // 【新增逻辑】如果是别人发的，或者没匹配到，去重后插入
      if (newList.any((m) => m.messageId == msg.messageId)) return;
      newList.add(msg);
    }

    // 排序：保证发送中的(seq=0)在最后，其他的按 seq 排
    newList.sort((a, b) {
      if ((a.seq ?? 0) == 0 || (b.seq ?? 0) == 0) {
        return (a.timestamp ?? 0).compareTo(b.timestamp ?? 0);
      }
      return a.seq!.compareTo(b.seq!);
    });

    state = {...state, roomId: newList};
  }

  void handleTimeout(String roomId, String clientMsgId) {
    final list = state[roomId] ?? [];
    final idx = list.indexWhere((m) => m.clientMsgId == clientMsgId);
    // 如果还在转圈，就变红感叹号
    if (idx != -1 && list[idx].deliveryStatus == DeliveryStatus.sending) {
      final newList = [...list];
      newList[idx] = newList[idx].copyWith(
        deliveryStatus: DeliveryStatus.failed,
      );
      state = {...state, roomId: newList};
    }
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
        API.chatHistory,
        queryParameters: {
          "roomId": roomId,
          "lastSeq": null,
          "pageSize": _pageSize,
          "direction": 0,
        },
      );

      final data = res.data["data"];

      // 无论数据是否为空，只要请求成功就标记为已同步
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
      final Map<String, ChatMessage> mergeMap = {};

      for (var m in currentList) {
        // 正在发送的消息没有 seq，用 clientMsgId 或 messageId 当 key
        final key = (m.seq != null && m.seq != 0)
            ? m.seq.toString()
            : m.messageId;
        if (key != null) mergeMap[key] = m;
      }

      for (var m in history) {
        final key = m.seq?.toString() ?? m.messageId;
        if (key != null) mergeMap[key] = m;
      }
      // 排序
      final sortedList = mergeMap.values.toList()
        ..sort((a, b) => a.seq!.compareTo(b.seq!));

      // 更新状态
      state = {...state, roomId: sortedList};
      log.info("房间 $roomId 同步完成，当前消息数: ${sortedList.length}");
    } catch (e) {
      log.error("同步房间 $roomId 失败: $e");
      // 如果失败了，不需要 add 到 _syncedRoomIds，这样下次切换还能重试
    }
  }

  Future<void> loadMoreHistory(String roomId) async {
    if (_isFetchingHistory) return;

    // 先检查一下是否还有更多，如果没有，直接返回
    final hasMore = ref.read(chatHasMoreProvider)[roomId] ?? true;
    if (!hasMore) return;

    final currentList = state[roomId] ?? [];
    if (currentList.isEmpty) return;

    // 找到当前本地最早的一条消息的 seq
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
        API.chatHistory,
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
