import 'dart:async';

import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/common/utils/NotificationHelper.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/ChatMessage.dart';
import '../../../domain/ChatRoomVO.dart';
import '../../../logs/talker.dart';

part 'room_list_service.g.dart';

@Riverpod(keepAlive: true)
class RoomListService extends _$RoomListService {
  /// 已读上报防抖定时器（按房间维度）
  final Map<String, Timer> _readDebounceTimers = {};

  /// 待上报的最新 seq（按房间维度）
  final Map<String, int> _pendingReadSeqs = {};

  @override
  FutureOr<List<ChatRoomVO>> build() async {
    ref.onDispose(() {
      // 销毁时：把所有待上报的 seq 立即上报，然后取消定时器
      for (final entry in _pendingReadSeqs.entries) {
        _reportReadSeq(entry.key, entry.value);
      }
      for (final timer in _readDebounceTimers.values) {
        timer.cancel();
      }
      _readDebounceTimers.clear();
      _pendingReadSeqs.clear();
    });
    return await fetchRoomList();
  }


  
  void toggleSearch(){
    state.whenData((rooms) {
      final List<ChatRoomVO> updatedList = rooms.map((room) {
        if(room.roomId == ref.read(activeRoomIdProvider)){
          return room.copyWith(isOpenSearch: !(room.isOpenSearch ?? false));
        }
        return room;
      }).toList();
      state = AsyncValue.data(updatedList);
    });
  }


  Future<List<ChatRoomVO>> fetchRoomList() async {
    try {
      final res = await DioClient().get(API.chatRooms);

      final data = res.data["data"];
      if (data is List) {
        return data
            .map((e) {
              try {
                return ChatRoomVO.fromJson(e);
              } catch (e) {
                // 单条解析失败，记录日志并返回空，防止整个页面崩溃
                print("ChatRoomVO 解析异常: $e");
                return null;
              }
            })
            .whereType<ChatRoomVO>()
            .toList(); // 过滤掉解析失败的空值
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// 改进的刷新：支持静默刷新，不闪烁
  /// 刷新后自动将当前活跃房间的未读数归零，防止服务端数据覆盖本地已读状态
  Future<void> refresh({bool silent = false}) async {
    if (!silent) state = const AsyncValue.loading();
    final newState = await AsyncValue.guard(() => fetchRoomList());

    // 刷新后：将当前活跃房间的未读数归零
    final activeId = ref.read(activeRoomIdProvider);
    if (activeId != null && newState is AsyncData<List<ChatRoomVO>>) {
      final rooms = newState.value;
      final index = rooms.indexWhere((r) => r.roomId == activeId);
      if (index != -1 && (rooms[index].unreadCount ?? 0) > 0) {
        final updatedList = List<ChatRoomVO>.from(rooms);
        updatedList[index] = updatedList[index].copyWith(unreadCount: 0);
        state = AsyncValue.data(updatedList);
        return;
      }
    }

    state = newState;
  }

  /// 实时更新：计算未读数的逻辑
  void updateRoomPosition(ChatMessage newMessage, ChatRoomVO? activeRoom) {
    final isCurrentRoom = activeRoom?.roomId == newMessage.roomId;
    final currentUser = ref.read(authControllerProvider).value;
    final isSelfMessage = newMessage.senderId == currentUser?.userId;

    final action = newMessage.extra['action']?.toString().toUpperCase();
    final isCallSystemMessage = action == 'CALL_STARTED' || action == 'CALL_ENDED';

    state.whenData((rooms) {
      final List<ChatRoomVO> updatedList = List.from(rooms);
      final index = updatedList.indexWhere(
        (r) => r.roomId == newMessage.roomId,
      );

      if (index != -1) {
        final oldRoom = updatedList.removeAt(index);

        // 当前正在看的房间不增加未读数
        int newUnread = isCurrentRoom ? 0 : (oldRoom.unreadCount ?? 0) + 1;
        // 普通消息：只要不是自己发的、且不是通话系统消息，就尝试发系统通知。
        // 窗口是否聚焦由 NotificationHelper 内部判断。
        if (!isSelfMessage && !isCallSystemMessage) {
          NotificationHelper().show(
            id: newMessage.roomId.hashCode,
            title: oldRoom.roomName ?? '新消息',
            body: newMessage.content,
            payload: newMessage.roomId,
            avatarUrl: newMessage.senderAvatar ?? oldRoom.roomAvatar,
          );
        }

        // 当前房间收到新消息时，防抖上报已读 seq
        // 连续收到多条消息只会在最后一条后 2 秒上报一次
        if (isCurrentRoom && newMessage.seq != null && newMessage.seq! > 0) {
          _debouncedReportReadSeq(newMessage.roomId!, newMessage.seq!);
        }

        final newRoom = oldRoom.copyWith(
          lastMessage: newMessage,
          unreadCount: newUnread,
        );

        updatedList.insert(0, newRoom);
        state = AsyncValue.data(updatedList);
      }
      // 注意：这里不再对未知房间自动 refresh，由系统事件服务统一处理
      // 避免与 system_event_service 中的 refresh 重复调用
    });
  }

  void markAsRead(String roomId) {
    // 立即冲刷该房间的防抖定时器，确保 seq 被上报
    _readDebounceTimers[roomId]?.cancel();
    _readDebounceTimers.remove(roomId);
    final pendingSeq = _pendingReadSeqs.remove(roomId);

    state.whenData((rooms) {
      final index = rooms.indexWhere((r) => r.roomId == roomId);
      if (index != -1) {
        // 上报已读 seq：优先用待上报的 seq（更大），否则用 lastMessage 的 seq
        final int? lastSeq = rooms[index].lastMessage?.seq;
        final int? seqToReport = (pendingSeq != null && pendingSeq > 0)
            ? pendingSeq
            : lastSeq;
        if (seqToReport != null && seqToReport > 0) {
          _reportReadSeq(roomId, seqToReport);
        }

        // 本地未读数归零
        if ((rooms[index].unreadCount ?? 0) > 0) {
          final List<ChatRoomVO> updatedList = List.from(rooms);
          updatedList[index] = updatedList[index].copyWith(unreadCount: 0);
          state = AsyncValue.data(updatedList);
        }
      }
    });
  }

  /// 本地移除房间（被踢/房间关闭等场景）
  void removeRoomLocally(String roomId) {
    state.whenData((rooms) {
      final updatedList = rooms.where((r) => r.roomId != roomId).toList();
      if (updatedList.length != rooms.length) {
        state = AsyncValue.data(updatedList);
      }
    });
  }

  /// 本地更新房间状态（禁言/解禁等场景）
  void updateRoomStatus(String roomId, int newStatus) {
    state.whenData((rooms) {
      final index = rooms.indexWhere((r) => r.roomId == roomId);
      if (index != -1) {
        final List<ChatRoomVO> updatedList = List.from(rooms);
        updatedList[index] = updatedList[index].copyWith(roomStatus: newStatus);
        state = AsyncValue.data(updatedList);
      }
    });
  }

  /// 防抖上报已读 seq：2 秒内连续收到消息只上报最后一次
  void _debouncedReportReadSeq(String roomId, int seq) {
    // 记录最新的 seq（总是取最大值）
    final currentPending = _pendingReadSeqs[roomId] ?? 0;
    if (seq > currentPending) {
      _pendingReadSeqs[roomId] = seq;
    }

    // 取消旧的定时器，重新计时
    _readDebounceTimers[roomId]?.cancel();
    _readDebounceTimers[roomId] = Timer(const Duration(seconds: 2), () {
      final pendingSeq = _pendingReadSeqs.remove(roomId);
      _readDebounceTimers.remove(roomId);
      if (pendingSeq != null && pendingSeq > 0) {
        _reportReadSeq(roomId, pendingSeq);
      }
    });
  }

  // 上报最新 seq 的接口调用
  Future<void> _reportReadSeq(String roomId, int seq) async {
    try {
      print("🚀 上报已读状态: 房间 $roomId, Seq $seq");
      await DioClient().get(
        API.chatReadReport,
        queryParameters: {"roomId": roomId, "seq": seq},
      );
    } catch (e) {
      print("上报已读失败: $e");
    }
  }

  Future<String?> getOrCreateRoom(int targetUserId) async {
    final rooms = state.value ?? [];

    // 1. 尝试从本地列表中寻找已存在的私聊房间
    // 使用 cast().firstWhereOrNull 需要导入 collection 库，或者用 try-catch 包装
    ChatRoomVO? existingRoom;
    try {
      existingRoom = rooms.firstWhere(
        (r) => r.roomType == 0 && r.peerId == targetUserId,
      );
    } catch (_) {
      existingRoom = null;
    }

    // 2. 如果本地找到了，直接返回 roomId
    if (existingRoom != null && existingRoom.roomId != null) {
      print("✅ 找到现有房间: ${existingRoom.roomId}");
      return existingRoom.roomId;
    }

    // 3. 本地没找到，请求后端创建/获取
    try {
      print("🚀 正在请求后端创建私聊房间，目标用户: $targetUserId");
      final res = await DioClient().get(
        API.chatCreatePrivate,
        queryParameters: {"targetId": targetUserId},
      );

      if (res.data["data"] == null) {
        return null;
      }
      final newRoom = ChatRoomVO.fromJson(res.data["data"]);

      // 4. 静默刷新房间列表，确保 UI 侧边栏能同步看到新房间
      await refresh(silent: true);

      return newRoom.roomId;
    } catch (e) {
      print("❌ 获取/创建房间接口调用失败: $e");
      return null;
    }
  }

  /// 退出房间
  Future<void> leaveRoom(String roomId) async {
    try {
      print("🚀 正在请求后端删除会话，房间 ID: $roomId");
      final res = await DioClient().get(
        API.chatRoomLeave,
        queryParameters: {"roomId": roomId},
      );

      if (res.data["code"] == 200) {
        log.info("删除会话成功");
        // 刷新房间列表
        await refresh(silent: true);

        // 删除对应房间缓存的消息
        ref.read(chatMessagesProvider.notifier).clearRoom(roomId);

        // 清理加载更多状态
        ref.read(chatHasMoreProvider.notifier).setHasMore(roomId, false);

        log.info("✅ 已删除房间 $roomId 的本地消息缓存和状态");
      }
    } catch (e) {
      print("❌ 删除会话失败: $e");
      rethrow;
    }
  }

  /// 解散群聊
  Future<void> dissolveGroup(String roomId) async {
    try {
      final res = await DioClient().get(
        API.chatRoomDisband,
        queryParameters: {"roomId": roomId},
      );

      log.info("$res");

      // 刷新房间列表
      await refresh(silent: true);
    } catch (e) {
      print("❌ 解散群聊失败: $e");
      rethrow;
    }
  }

  /// 房间禁言/解除禁言
  Future<bool> muteRoom(String roomId, bool isMute) async {
    try {
      log.info("🚀 正在${isMute ? '禁言' : '解除禁言'}房间 $roomId");

      final res = await DioClient().get(
        API.chatRoomMute,
        queryParameters: {"roomId": roomId, "isMute": isMute},
      );

      if (res.data["code"] == 200) {
        log.info("✅ ${isMute ? '禁言' : '解除禁言'}房间成功");
        // 刷新房间列表以更新 roomStatus
        await refresh(silent: true);
        return true;
      }
      return false;
    } catch (e, st) {
      log.error("❌ ${isMute ? '禁言' : '解除禁言'}房间失败", e, st);
      return false;
    }
  }
}

//当前选中房间
@Riverpod(keepAlive: true)
class ActiveRoomId extends _$ActiveRoomId {
  @override
  String? build() => null; // 初始没有选中的房间

  void setActive(String? roomId) {
    if (state == roomId) return;

    // 离开旧房间时：冲刷防抖队列，确保已读 seq 被上报
    final oldRoomId = state;
    if (oldRoomId != null) {
      ref.read(roomListServiceProvider.notifier).markAsRead(oldRoomId);
    }

    state = roomId;
  }
}

@riverpod
ChatRoomVO? activeRoom(Ref ref) {
  // 1. 监听当前选中的 ID
  final activeId = ref.watch(activeRoomIdProvider);
  if (activeId == null) return null;

  // 2. 监听 房间列表 的数据变化
  final roomListAsync = ref.watch(roomListServiceProvider);

  // 3. 自动关联：当列表更新时，这里也会自动返回最新的房间对象
  return roomListAsync.maybeWhen(
    data: (rooms) => rooms.firstWhere((r) => r.roomId == activeId),
    orElse: () => null,
  );
}

@riverpod
Future<void> roomEntryTask(Ref ref, String roomId) async {
  // 1. 确保房间列表已经存在
  final roomListAsync = ref.read(roomListServiceProvider);
  final rooms = roomListAsync.value ?? [];

  // 使用 findFirst 的安全版本
  final room = rooms.firstWhere(
    (r) => r.roomId == roomId,
    orElse: () => throw Exception("尚未加载房间信息"),
  );

  await Future.wait([
    ref
        .read(chatMessagesProvider.notifier)
        .syncRoomMessages(roomId, room.lastMessage?.seq),
    ref.read(roomMemberServiceProvider.notifier).syncMembers(roomId),
  ]);

  ref.read(roomListServiceProvider.notifier).markAsRead(roomId);
}

@riverpod
List<ChatRoomVO> groupRoomList(Ref ref) {
  final roomListAsync = ref.watch(roomListServiceProvider);

  return roomListAsync.maybeWhen(
    data: (rooms) => rooms
        .where((r) => r.roomType == 1) // GROUP
        .toList(),
    orElse: () => const [],
  );
}

@riverpod
class RoomSearchQuery extends _$RoomSearchQuery {
  @override
  String build() => "";

  void update(String query) => state = query;
}

// 2. 核心：根据关键词过滤房间列表
@riverpod
List<ChatRoomVO> filteredRoomList(Ref ref) {
  // 监听原始列表
  final roomListAsync = ref.watch(roomListServiceProvider);
  // 监听搜索词
  final query = ref.watch(roomSearchQueryProvider).trim().toLowerCase();

  return roomListAsync.maybeWhen(
    data: (rooms) {
      if (query.isEmpty) return rooms;

      // 搜索规则：匹配房间名 或 最后一条消息内容
      return rooms.where((room) {
        final nameMatch = (room.roomName ?? "").toLowerCase().contains(query);
        final msgMatch = (room.lastMessage?.content ?? "")
            .toLowerCase()
            .contains(query);
        return nameMatch || msgMatch;
      }).toList();
    },
    orElse: () => const [],
  );
}

@riverpod
int totalUnreadCount(Ref ref) {
  //  监听房间列表的状态变化
  final roomList = ref.watch(roomListServiceProvider);
  //  排除当前正在查看的房间
  final activeId = ref.watch(activeRoomIdProvider);

  if (roomList.value != null) {
    //  累加所有房间的未读数（排除当前活跃房间）
    return roomList.value!.fold(0, (sum, room) {
      if (room.roomId == activeId) return sum;
      return sum + (room.unreadCount ?? 0);
    });
  }
  return 0;
}
