import 'dart:async';

import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/common/utils/NotificationHelper.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/ChatMessage.dart';
import '../../../domain/ChatRoomVO.dart';
import '../../../logs/talker.dart';

part 'room_list_service.g.dart';

/// 聊天室列表服务
///
/// 负责管理聊天室列表的获取、刷新、排序和本地状态维护。
/// 采用 keepAlive 模式，确保列表数据全局共享。
@Riverpod(keepAlive: true)
class RoomListService extends _$RoomListService {
  /// 已读上报防抖定时器（按房间维度）
  final Map<String, Timer> _readDebounceTimers = {};

  /// 待上报的最新 seq（按房间维度）
  final Map<String, int> _pendingReadSeqs = {};

  @override
  FutureOr<List<ChatRoomVO>> build() async {
    ref.onDispose(() {
      // 销毁时：将所有待上报的 seq 立即上报，然后取消定时器
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

  /// 切换当前房间的搜索栏展开状态
  void toggleSearch() {
    state.whenData((rooms) {
      final List<ChatRoomVO> updatedList = rooms.map((room) {
        if (room.roomId == ref.read(activeRoomIdProvider)) {
          return room.copyWith(isOpenSearch: !(room.isOpenSearch ?? false));
        }
        return room;
      }).toList();
      state = AsyncValue.data(updatedList);
    });
  }

  /// 获取聊天室列表
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
                // 单条解析失败记录日志，防止整个页面崩溃
                log.warning("ChatRoomVO 解析异常: $e");
                return null;
              }
            })
            .whereType<ChatRoomVO>()
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// 刷新聊天室列表
  ///
  /// [silent] 为 true 时静默刷新，不触发 loading 状态（避免 UI 闪烁）
  /// 刷新后自动将当前活跃房间的未读数归零，防止服务端数据覆盖本地已读状态
  Future<void> refresh({bool silent = false}) async {
    if (!silent) state = const AsyncValue.loading();
    final newState = await AsyncValue.guard(() => fetchRoomList());

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

  /// 实时更新房间位置和未读数
  ///
  /// [newMessage] 新收到的消息
  /// [activeRoom] 当前正在查看的房间
  ///
  /// 处理逻辑：
  /// - 当前房间：未读数不增加
  /// - 自己发送的消息：不增加未读数、不发送通知
  /// - 通话系统消息：不发送通知
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

        // 发送桌面通知（窗口是否聚焦由 NotificationHelper 内部判断）
        if (!isSelfMessage && !isCallSystemMessage) {
          NotificationHelper().show(
            id: newMessage.roomId.hashCode,
            title: oldRoom.roomName ?? tr('chat_new_message'),
            body: newMessage.content,
            payload: newMessage.roomId,
            avatarUrl: newMessage.senderAvatar ?? oldRoom.roomAvatar,
          );
        }

        // 当前房间收到新消息时，防抖上报已读 seq
        if (isCurrentRoom &&
            !isSelfMessage &&
            newMessage.seq != null &&
            newMessage.seq! > 0) {
          _debouncedReportReadSeq(newMessage.roomId!, newMessage.seq!);
        }

        final newRoom = oldRoom.copyWith(
          lastMessage: newMessage,
          unreadCount: newUnread,
        );

        updatedList.insert(0, newRoom);
        state = AsyncValue.data(updatedList);
      }
    });
  }

  /// 标记房间为已读
  ///
  /// 立即冲刷防抖定时器，确保 seq 被上报
  void markAsRead(String roomId) {
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

  /// 防抖上报已读 seq
  ///
  /// 2 秒内连续收到消息只上报最后一次（取最大值）
  void _debouncedReportReadSeq(String roomId, int seq) {
    final currentPending = _pendingReadSeqs[roomId] ?? 0;
    if (seq > currentPending) {
      _pendingReadSeqs[roomId] = seq;
    }

    _readDebounceTimers[roomId]?.cancel();
    _readDebounceTimers[roomId] = Timer(const Duration(seconds: 2), () {
      final pendingSeq = _pendingReadSeqs.remove(roomId);
      _readDebounceTimers.remove(roomId);
      if (pendingSeq != null && pendingSeq > 0) {
        _reportReadSeq(roomId, pendingSeq);
      }
    });
  }

  /// 上报已读 seq 到服务器
  Future<void> _reportReadSeq(String roomId, int seq) async {
    try {
      log.info("🚀 上报已读状态: 房间 $roomId, Seq $seq");
      await DioClient().get(
        API.chatReadReport,
        queryParameters: {"roomId": roomId, "seq": seq},
      );
    } catch (e) {
      log.warning("上报已读失败: $e");
    }
  }

  /// 获取或创建私聊房间
  ///
  /// [targetUserId] 目标用户ID
  ///
  /// 优先从本地列表查找已存在的私聊房间，找不到时请求后端创建
  Future<String?> getOrCreateRoom(int targetUserId) async {
    final rooms = state.value ?? [];

    ChatRoomVO? existingRoom;
    try {
      existingRoom = rooms.firstWhere(
        (r) => r.roomType == 0 && r.peerId == targetUserId,
      );
    } catch (_) {
      existingRoom = null;
    }

    if (existingRoom != null && existingRoom.roomId != null) {
      log.info("✅ 找到现有房间: ${existingRoom.roomId}");
      return existingRoom.roomId;
    }

    try {
      log.info("🚀 正在请求后端创建私聊房间，目标用户: $targetUserId");
      final res = await DioClient().get(
        API.chatCreatePrivate,
        queryParameters: {"targetId": targetUserId},
      );

      if (res.data["data"] == null) {
        return null;
      }
      final newRoom = ChatRoomVO.fromJson(res.data["data"]);

      // 静默刷新房间列表，确保 UI 侧边栏能同步看到新房间
      await refresh(silent: true);

      return newRoom.roomId;
    } catch (e) {
      log.error("❌ 获取/创建房间接口调用失败", e);
      return null;
    }
  }

  /// 退出聊天室
  Future<void> leaveRoom(String roomId) async {
    try {
      log.info("🚀 正在请求后端删除会话，房间 ID: $roomId");
      final res = await DioClient().get(
        API.chatRoomLeave,
        queryParameters: {"roomId": roomId},
      );

      if (res.data["code"] == 200) {
        log.info("删除会话成功");
        await refresh(silent: true);

        // 删除对应房间缓存的消息
        ref.read(chatMessagesProvider.notifier).clearRoom(roomId);

        // 清理加载更多状态
        ref.read(chatHasMoreProvider.notifier).setHasMore(roomId, false);

        log.info("✅ 已删除房间 $roomId 的本地消息缓存和状态");
      }
    } catch (e) {
      log.error("❌ 删除会话失败", e);
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
      await refresh(silent: true);
    } catch (e) {
      log.error("❌ 解散群聊失败", e);
      rethrow;
    }
  }

  /// 房间禁言/解除禁言
  ///
  /// [roomId] 房间ID
  /// [isMute] true=禁言，false=解除禁言
  Future<bool> muteRoom(String roomId, bool isMute) async {
    try {
      log.info("🚀 正在${isMute ? '禁言' : '解除禁言'}房间 $roomId");

      final res = await DioClient().get(
        API.chatRoomMute,
        queryParameters: {"roomId": roomId, "isMute": isMute},
      );

      if (res.data["code"] == 200) {
        log.info("✅ ${isMute ? '禁言' : '解除禁言'}房间成功");
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

/// 当前选中的聊天室 ID
@Riverpod(keepAlive: true)
class ActiveRoomId extends _$ActiveRoomId {
  @override
  String? build() => null;

  /// 设置当前活跃的房间
  ///
  /// 离开旧房间时会自动调用 [RoomListService.markAsRead] 上报已读
  void setActive(String? roomId) {
    if (state == roomId) return;

    final oldRoomId = state;
    if (oldRoomId != null) {
      ref.read(roomListServiceProvider.notifier).markAsRead(oldRoomId);
    }

    state = roomId;
  }
}

/// 当前选中的聊天室对象
@riverpod
ChatRoomVO? activeRoom(Ref ref) {
  final activeId = ref.watch(activeRoomIdProvider);
  if (activeId == null) return null;

  final roomListAsync = ref.watch(roomListServiceProvider);

  return roomListAsync.maybeWhen(
    data: (rooms) {
      try {
        return rooms.firstWhere((r) => r.roomId == activeId);
      } catch (_) {
        return null;
      }
    },
    orElse: () => null,
  );
}

/// 进入房间时的初始化任务
///
/// 确保消息和成员数据已同步到本地
@riverpod
Future<void> roomEntryTask(Ref ref, String roomId) async {
  final roomListAsync = ref.read(roomListServiceProvider);
  final rooms = roomListAsync.value ?? [];

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

/// 群聊房间列表（房间类型为 GROUP）
@riverpod
List<ChatRoomVO> groupRoomList(Ref ref) {
  final roomListAsync = ref.watch(roomListServiceProvider);

  return roomListAsync.maybeWhen(
    data: (rooms) => rooms
        .where((r) => r.roomType == 1)
        .toList(),
    orElse: () => const [],
  );
}

/// 房间搜索关键词
@riverpod
class RoomSearchQuery extends _$RoomSearchQuery {
  @override
  String build() => "";

  void update(String query) => state = query;
}

/// 根据关键词过滤后的聊天室列表
///
/// 匹配规则：房间名称 或 最后一条消息内容
@riverpod
List<ChatRoomVO> filteredRoomList(Ref ref) {
  final roomListAsync = ref.watch(roomListServiceProvider);
  final query = ref.watch(roomSearchQueryProvider).trim().toLowerCase();

  return roomListAsync.maybeWhen(
    data: (rooms) {
      if (query.isEmpty) return rooms;

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

/// 总未读消息数
///
/// 排除当前正在查看的房间
@riverpod
int totalUnreadCount(Ref ref) {
  final roomList = ref.watch(roomListServiceProvider);
  final activeId = ref.watch(activeRoomIdProvider);

  if (roomList.value != null) {
    return roomList.value!.fold(0, (sum, room) {
      if (room.roomId == activeId) return sum;
      return sum + (room.unreadCount ?? 0);
    });
  }
  return 0;
}
