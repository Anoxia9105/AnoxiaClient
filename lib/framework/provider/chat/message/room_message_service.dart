import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/common/utils/NotificationHelper.dart';
import 'package:anoxia/framework/domain/ChatRoomVO.dart';
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
        .listen(_handleRoomMessage);

    // Provider 销毁时取消订阅，防止内存泄漏
    ref.onDispose(() {
      log.info("聊天消息服务销毁，取消订阅");
      subscription.cancel();
    });

    return {};
  }

  /// 处理 WebSocket 推送的房间消息
  ///
  /// 将协议层的 [RoomMessage] 转换为领域层的 [ChatMessage]，
  /// 并同步更新通话状态、房间状态和房间列表。
  void _handleRoomMessage(RoomMessage msg) {
    final chatMessage = ChatMessage(
      messageId: msg.messageId,
      clientMsgId: msg.clientMsgId,
      roomId: msg.roomId,
      senderId: msg.senderId.toInt(),
      senderName: msg.senderName,
      senderAvatar: msg.senderAvatar,
      messageType: msg.type,
      content: msg.payload?.content ?? '',
      payload: msg.payload,
      attachments: msg.attachments,
      extra: msg.extra,
      messageStatus: msg.state,
      deliveryStatus: msg.status,
      timestamp: msg.timestamp.toInt(),
      seq: msg.seq.toInt(),
    );

    _syncCallStatusBySystemMessage(chatMessage);
    _syncRoomStatusBySystemMessage(chatMessage);

    upsertMessage(chatMessage);
    ref
        .read(roomListServiceProvider.notifier)
        .updateRoomPosition(chatMessage, ref.read(activeRoomProvider));
  }

  /// 根据系统消息同步房间状态
  ///
  /// 处理禁言、解散等房间级别的系统消息
  void _syncRoomStatusBySystemMessage(ChatMessage msg) {
    if (msg.messageType != MessageType.system) return;

    final roomId = msg.roomId;
    final action = msg.extra['action']?.toString().toUpperCase();
    if (roomId == null || roomId.isEmpty || action == null || action.isEmpty) {
      return;
    }

    int? nextStatus;
    switch (action) {
      case 'ROOM_MUTED':
        final isMute = msg.extra['isMute'] == true;
        nextStatus = isMute ? 1 : 0;
        break;
      case 'ROOM_DISSOLVED':
        final dissolveType = msg.extra['type']?.toString().toLowerCase();
        nextStatus = dissolveType == 'ban' ? 2 : 3;
        break;
      case 'ROOM_CREATED':
        final createdType = msg.extra['type']?.toString().toLowerCase();
        if (createdType == 'unban') {
          nextStatus = 0;
        }
        break;
      default:
        break;
    }

    if (nextStatus != null) {
      ref
          .read(roomListServiceProvider.notifier)
          .updateRoomStatus(roomId, nextStatus);
      log.info('房间 $roomId 根据系统消息[$action]更新状态为 $nextStatus');
    }
  }

  /// 根据系统消息同步通话状态
  ///
  /// 处理通话开始、通话结束等事件
  void _syncCallStatusBySystemMessage(ChatMessage msg) {
    if (msg.messageType != MessageType.system) return;

    final roomId = msg.roomId;
    final action = msg.extra['action']?.toString().toUpperCase();
    if (roomId == null || roomId.isEmpty || action == null || action.isEmpty) {
      return;
    }

    final callStatus = ref.read(callStatusControllerProvider.notifier);

    if (action == 'CALL_STARTED') {
      final startTime =
          (msg.extra['startTime'] as num?)?.toInt() ?? msg.timestamp ?? 0;
      callStatus.markStarted(roomId, startTime: startTime);
      _notifyCallEvent(msg, roomId, action);
      return;
    }

    if (action == 'CALL_ENDED') {
      callStatus.markEnded(roomId);
      _notifyCallEvent(msg, roomId, action);
    }
  }

  /// 发送通话事件的桌面通知
  void _notifyCallEvent(ChatMessage msg, String roomId, String action) {
    final rooms =
        ref.read(roomListServiceProvider).value ?? const <ChatRoomVO>[];
    String roomName = '通话通知';
    for (final r in rooms) {
      if (r.roomId == roomId) {
        roomName = (r.roomName != null && r.roomName!.isNotEmpty)
            ? r.roomName!
            : roomName;
        break;
      }
    }

    String body;
    if (action == 'CALL_STARTED') {
      final nickName = msg.extra['nickName']?.toString();
      body = (nickName != null && nickName.isNotEmpty)
          ? '$nickName 发起了通话'
          : '房间通话已开始';
    } else {
      final durationText = msg.extra['durationText']?.toString();
      body = (durationText != null && durationText.isNotEmpty)
          ? '房间通话已结束（$durationText）'
          : '房间通话已结束';
    }

    NotificationHelper().show(
      id: roomId.hashCode ^ action.hashCode,
      title: roomName,
      body: body,
      payload: roomId,
      avatarUrl: msg.senderAvatar,
      force: true,
    );
  }

  /// 插入或更新消息
  ///
  /// 优先通过 clientMsgId 匹配（本地发送中的消息），
  /// 匹配失败则通过 messageId 匹配（服务端推送的消息），
  /// 都找不到则作为新消息追加。
  void upsertMessage(ChatMessage msg) {
    final roomId = msg.roomId ?? "system";
    final currentList = state[roomId] ?? [];
    List<ChatMessage> newList = [...currentList];

    int index = -1;
    if (msg.clientMsgId != null) {
      index = newList.indexWhere((m) => m.clientMsgId == msg.clientMsgId);
    }
    // 兼容 WebSocket 消息比本地发送回调更快到达的场景
    if (index == -1 && msg.messageId != null) {
      index = newList.indexWhere((m) => m.messageId == msg.messageId);
    }

    if (index != -1) {
      // 用服务器回传的真数据（messageId, seq）覆盖本地假数据
      newList[index] = msg;
    } else {
      // 去重后插入新消息
      if (newList.any((m) => m.messageId == msg.messageId)) return;
      newList.add(msg);
    }

    // 排序：发送中的消息(seq=0)在最后，其他按 seq 升序
    newList.sort((a, b) {
      if ((a.seq ?? 0) == 0 || (b.seq ?? 0) == 0) {
        return (a.timestamp ?? 0).compareTo(b.timestamp ?? 0);
      }
      return a.seq!.compareTo(b.seq!);
    });

    state = {...state, roomId: newList};
  }

  /// 处理消息发送超时
  ///
  /// 将发送状态从 sending 改为 failed（UI 显示红色感叹号）
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

  /// 同步/加载房间消息
  ///
  /// [roomId] 目标房间
  /// [serverLastSeq] 服务端记录的最新消息 seq，用于判断增量
  ///
  /// 已同步过的房间在 seq 未增加时会跳过拉取
  Future<void> syncRoomMessages(String roomId, int? serverLastSeq) async {
    final currentList = state[roomId] ?? [];
    int localMaxSeq = currentList.isEmpty ? 0 : (currentList.last.seq ?? 0);

    // 已同步且本地已是最新，直接返回
    if (_syncedRoomIds.contains(roomId)) {
      if (serverLastSeq == null || localMaxSeq >= serverLastSeq) {
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

      // 请求成功即标记为已同步（即使数据为空）
      _syncedRoomIds.add(roomId);

      if (data is! List) return;

      final List<ChatMessage> history = data
          .map((e) => ChatMessage.fromJson(e))
          .toList();

      // 数据少于页大小时，说明没有更多历史了
      if (history.length < _pageSize) {
        ref.read(chatHasMoreProvider.notifier).setHasMore(roomId, false);
      } else {
        ref.read(chatHasMoreProvider.notifier).setHasMore(roomId, true);
      }

      // 合并与去重：正在发送的消息用 clientMsgId/messageId 做 key
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
      log.info("房间 $roomId 同步完成，当前消息数: ${sortedList.length}");
    } catch (e) {
      log.error("同步房间 $roomId 失败: $e");
    }
  }

  /// 加载更多历史消息
  ///
  /// 从当前列表最旧的消息向前分页拉取
  Future<void> loadMoreHistory(String roomId) async {
    if (_isFetchingHistory) return;

    final hasMore = ref.read(chatHasMoreProvider)[roomId] ?? true;
    if (!hasMore) return;

    final currentList = state[roomId] ?? [];
    if (currentList.isEmpty) return;

    // 列表按 seq 升序排列，第一条是最早的消息
    final int? oldestSeq = currentList.first.seq;
    if (oldestSeq == null || oldestSeq <= 1) {
      log.info("已经到头了 不请求了");
      return;
    }

    _isFetchingHistory = true;
    log.info("开始拉取房间 $roomId 的历史消息，起始 seq: $oldestSeq");

    try {
      final res = await DioClient().get(
        API.chatHistory,
        queryParameters: {
          "roomId": roomId,
          "lastSeq": oldestSeq,
          "pageSize": _pageSize,
          "direction": 0,
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
        ref.read(chatHasMoreProvider.notifier).setHasMore(roomId, true);
      }

      if (history.isNotEmpty) {
        // 按 seq 去重合并
        final Map<int, ChatMessage> mergeMap = {
          for (var m in history)
            if (m.seq != null) m.seq!: m,
          for (var m in currentList)
            if (m.seq != null) m.seq!: m,
        };

        final sortedList = mergeMap.values.toList()
          ..sort((a, b) => a.seq!.compareTo(b.seq!));

        state = {...state, roomId: sortedList};
        log.info("历史消息加载成功，新增 ${history.length} 条");
      }
    } catch (e) {
      log.error("加载历史消息失败: $e");
    } finally {
      _isFetchingHistory = false;
    }
  }

  /// 清空某个房间的消息（退出会话时调用）
  void clearRoom(String roomId) {
    _syncedRoomIds.remove(roomId);
    state = {...state, roomId: []};
  }

  /// 标记房间需要重新同步（断线重连后调用）
  void markNeedResync(String roomId) {
    _syncedRoomIds.remove(roomId);
  }

  /// 标记所有房间需要重新同步
  void markAllNeedResync() {
    _syncedRoomIds.clear();
  }

  /// 撤回消息
  Future<bool> recallMessage(String messageId, String roomId) async {
    try {
      final res = await DioClient().get(
        API.chatRecall,
        queryParameters: {"messageId": messageId},
      );

      if (res.data["code"] == 200) {
        removeMessage(messageId, roomId);
        return true;
      } else {
        log.error("撤回消息失败: ${res.data['msg']}");
        return false;
      }
    } catch (e) {
      log.error("撤回消息请求失败: $e");
      return false;
    }
  }

  /// 收藏消息
  Future<bool> addFavorite(String messageId) async {
    try {
      final res = await DioClient().post('${API.chatFavoriteAdd}/$messageId');
      return res.data["code"] == 200;
    } catch (e) {
      log.error("收藏消息失败: $e");
      return false;
    }
  }

  /// 从消息列表中移除消息（撤回时使用）
  void removeMessage(String messageId, String roomId) {
    final currentList = state[roomId] ?? [];
    final newList = currentList
        .where((msg) => msg.messageId != messageId)
        .toList();

    if (newList.length != currentList.length) {
      state = {...state, roomId: newList};
      log.info("消息 $messageId 已从房间 $roomId 中移除");
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
