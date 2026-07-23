import 'dart:async';

import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/common/utils/NotificationHelper.dart';
import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/features/chat/presentation/formatters/system_message_formatter.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/room/do_not_disturb_rooms_provider.dart';
import 'package:anoxia/framework/provider/chat/room/pinned_rooms_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_lookup_helper.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/ChatMessage.dart';
import '../../../domain/ChatRoomVO.dart';
import '../../../logs/talker.dart';

part 'room_list_service.g.dart';

final chatRightPanelVisibleProvider = StateProvider<bool>((ref) => false);

/// 聊天室列表服务
///
/// 负责管理聊天室列表的获取、刷新、排序和本地状态维护。
/// 采用 keepAlive 模式，确保列表数据全局共享。
@Riverpod(keepAlive: true)
class RoomListService extends _$RoomListService {
  static const Duration _startupFetchTimeout = Duration(seconds: 12);

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
    final subscription = ref
        .read(syncRepositoryProvider)
        .watchConversations()
        .listen((rooms) => state = AsyncValue.data(rooms));
    ref.onDispose(subscription.cancel);
    return await _fetchRoomListForStartup();
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
    final currentUser = ref.read(authControllerProvider).value;
    if (currentUser == null) {
      log.info('用户未登录，跳过聊天室列表请求');
      return [];
    }

    try {
      return await ref.read(syncRepositoryProvider).getConversations();
    } on DioException catch (e) {
      // 处理 401 登录过期错误：在初始化时优雅地返回空列表而不是崩溃
      // DioClient 的拦截器已处理登出逻辑，此处仅需返回空列表
      if (e.error == '登录过期') {
        log.warning('登录已过期，返回空列表');
        return [];
      }
      rethrow;
    }
  }

  /// 刷新聊天室列表
  ///
  /// [silent] 为 true 时静默刷新，不触发 loading 状态（避免 UI 闪烁）
  /// 刷新后自动将当前活跃房间的未读数归零，防止服务端数据覆盖本地已读状态
  Future<void> refresh({bool silent = false}) async {
    if (!silent) state = const AsyncValue.loading();
    final newState = await AsyncValue.guard(_fetchRoomListForStartup);

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

  Future<List<ChatRoomVO>> _fetchRoomListForStartup() async {
    try {
      return await fetchRoomList().timeout(_startupFetchTimeout);
    } on TimeoutException catch (e, st) {
      log.warning('[RoomListService] 房间列表加载超时，使用空列表继续启动', e, st);
      return state.value ?? const <ChatRoomVO>[];
    }
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
  void updateRoomPosition(ChatMessage newMessage, String? roomId) {
    final isCurrentRoom = roomId == newMessage.roomId;
    final currentUser = ref.read(authControllerProvider).value;
    final isSelfMessage = newMessage.senderId == currentUser?.userId;

    final action = newMessage.properties['action']?.toString().toUpperCase();
    final isCallSystemMessage =
        action == 'CALL_STARTED' || action == 'CALL_ENDED';

    state.whenData((rooms) {
      final oldRoom = RoomLookupHelper.findByRoomId(rooms, newMessage.roomId);
      if (oldRoom != null) {
        final lifecycle = WidgetsBinding.instance.lifecycleState;
        final isAppForeground =
            lifecycle == null ||
            lifecycle == AppLifecycleState.resumed ||
            lifecycle == AppLifecycleState.inactive;
        final isMobile =
            defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS;
        final isDoNotDisturb = ref
            .read(doNotDisturbRoomsProvider)
            .contains(newMessage.roomId);
        final shouldShowLocalNotification =
            !isSelfMessage &&
            !isCallSystemMessage &&
            !isCurrentRoom &&
            !isDoNotDisturb &&
            !(isMobile && isAppForeground);

        // 发送桌面通知（窗口是否聚焦由 NotificationHelper 内部判断）
        if (shouldShowLocalNotification) {
          final notificationBody =
              SystemMessageFormatter.isSystemMessage(newMessage)
              ? SystemMessageFormatter.display(newMessage).text
              : newMessage.content;
          NotificationHelper().show(
            id: newMessage.roomId.hashCode,
            title: oldRoom.roomName ?? tr('chat_new_message'),
            body: notificationBody,
            payload: newMessage.roomId,
            avatarUrl: oldRoom.roomAvatar,
          );
        }

        // 当前房间收到新消息时，防抖上报已读 seq
        if (isCurrentRoom &&
            !isSelfMessage &&
            newMessage.seq != null &&
            newMessage.seq! > 0) {
          _debouncedReportReadSeq(newMessage.roomId!, newMessage.seq!);
        }

        // Persistence and unread projection are committed atomically by
        // ChatMessages. This method only owns presentation side effects.
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
        final unreadCount = rooms[index].unreadCount ?? 0;
        final hasPendingReadSeq = pendingSeq != null && pendingSeq > 0;

        // 只有存在未上报的已读 seq，或房间确实有未读时，才触发本地/远端已读同步。
        if (hasPendingReadSeq || unreadCount > 0) {
          final int? lastSeq = rooms[index].lastMessage?.seq;
          final int? seqToReport = hasPendingReadSeq ? pendingSeq : lastSeq;
          if (seqToReport != null && seqToReport > 0) {
            _reportReadSeq(roomId, seqToReport);
          }
        }

        // 本地未读数归零
        if (unreadCount > 0) {
          final List<ChatRoomVO> updatedList = List.from(rooms);
          updatedList[index] = updatedList[index].copyWith(unreadCount: 0);
          state = AsyncValue.data(updatedList);
        }
      }
    });
  }

  /// 本地移除房间（被踢/房间关闭等场景）
  void removeRoomLocally(String roomId) {
    unawaited(
      ref.read(localDataSourceProvider).markConversationDeleted(roomId),
    );
  }

  /// 本地更新房间状态（禁言/解禁等场景）
  void updateRoomStatus(String roomId, int newStatus) {
    unawaited(
      ref
          .read(localDataSourceProvider)
          .updateConversationStatus(roomId, newStatus),
    );
  }

  /// Applies announcement events immediately while the authoritative refresh runs.
  void updateRoomAnnouncementLocally(String roomId, String announcement) {
    state.whenData((rooms) {
      final index = rooms.indexWhere((room) => room.roomId == roomId);
      if (index == -1) return;

      final updated = List<ChatRoomVO>.from(rooms);
      updated[index] = updated[index].copyWith(roomDescription: announcement);
      state = AsyncValue.data(updated);
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

  /// 上报已读 seq 到服务器，同时更新本地 DB（last_read_seq / unread_count）
  Future<void> _reportReadSeq(String roomId, int seq) async {
    try {
      log.info('🚀 上报已读状态: 房间 $roomId, Seq $seq');
      await ref.read(syncRepositoryProvider).markAsRead(roomId, seq: seq);
    } catch (e) {
      log.warning('上报已读失败: $e');
    }
  }

  /// 获取或创建私聊房间
  ///
  /// [targetUserId] 目标用户ID
  ///
  /// 优先从本地列表查找已存在的私聊房间，找不到时请求后端创建
  Future<String?> getOrCreateRoom(int targetUserId) async {
    final rooms = state.value ?? [];

    final existingRoom = RoomLookupHelper.findPrivateByPeerId(
      rooms,
      targetUserId,
    );

    if (existingRoom != null && existingRoom.roomId != null) {
      log.info('✅ 找到现有房间: ${existingRoom.roomId}');
      return existingRoom.roomId;
    }

    try {
      log.info('🚀 正在请求后端创建私聊房间，目标用户: $targetUserId');
      final res = await DioClient().get(
        API.chatCreatePrivate,
        queryParameters: {'targetId': targetUserId},
      );

      if (res.data['data'] == null) {
        return null;
      }
      final newRoom = ChatRoomVO.fromJson(res.data['data']);

      // 静默刷新房间列表，确保 UI 侧边栏能同步看到新房间
      await refresh(silent: true);

      return newRoom.roomId;
    } catch (e) {
      log.error('❌ 获取/创建房间接口调用失败', e);
      return null;
    }
  }

  /// 退出聊天室
  Future<void> leaveRoom(String roomId) async {
    try {
      log.info('🚀 正在请求后端删除会话，房间 ID: $roomId');
      final res = await DioClient().get(
        API.chatRoomLeave,
        queryParameters: {'roomId': roomId},
      );

      if (res.data['code'] == 200) {
        log.info('删除会话成功');
        await ref.read(localDataSourceProvider).deleteConversationCache(roomId);

        // 删除对应房间缓存的消息
        ref.read(chatMessagesProvider.notifier).clearRoom(roomId);

        // 清理加载更多状态
        ref.read(chatHasMoreProvider.notifier).setHasMore(roomId, false);
        await ref.read(doNotDisturbRoomsProvider.notifier).remove(roomId);

        await refresh(silent: true);

        log.info('✅ 已删除房间 $roomId 的本地消息缓存和状态');
      }
    } catch (e) {
      log.error('❌ 删除会话失败', e);
      rethrow;
    }
  }

  /// 解散群聊
  Future<void> dissolveGroup(String roomId) async {
    try {
      final res = await DioClient().get(
        API.chatRoomDisband,
        queryParameters: {'roomId': roomId},
      );

      log.info('$res');
      await refresh(silent: true);
    } catch (e) {
      log.error('❌ 解散群聊失败', e);
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
        queryParameters: {'roomId': roomId, 'isMute': isMute},
      );

      if (res.data['code'] == 200) {
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

  /// 修改群聊名称
  Future<bool> updateGroupName(String roomId, String roomName) async {
    final safeName = roomName.trim();
    if (roomId.isEmpty || safeName.isEmpty) {
      return false;
    }

    try {
      final res = await DioClient().post(
        API.chatRoomUpdateName,
        data: {'roomId': roomId, 'roomName': safeName},
      );

      if (res.data['code'] == 200) {
        await refresh(silent: true);
        return true;
      }
      return false;
    } catch (e, st) {
      log.error('❌ 修改群聊名称失败', e, st);
      return false;
    }
  }

  /// 修改群公告
  Future<bool> updateGroupAnnouncement(
    String roomId,
    String roomAnnouncement,
  ) async {
    final safeAnnouncement = roomAnnouncement.trim();
    if (roomId.isEmpty) {
      return false;
    }

    try {
      final res = await DioClient().post(
        API.chatRoomUpdateAnnouncement,
        data: {'roomId': roomId, 'roomAnnouncement': safeAnnouncement},
      );

      if (res.data['code'] == 200) {
        await refresh(silent: true);
        return true;
      }
      return false;
    } catch (e, st) {
      log.error('❌ 修改群公告失败', e, st);
      return false;
    }
  }
}

/// 当前选中的聊天室 ID 全局指针
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

/// 进入房间时的初始化任务
///
/// 确保消息和成员数据已同步到本地
@riverpod
Future<void> roomEntryTask(Ref ref, String roomId) async {
  final roomListAsync = ref.read(roomListServiceProvider);
  final rooms = roomListAsync.value ?? [];

  final room = RoomLookupHelper.findByRoomId(rooms, roomId);

  await Future.wait([
    ref
        .read(chatMessagesProvider.notifier)
        .syncRoomMessages(roomId, room?.lastMessage?.seq),
    ref.read(roomMemberServiceProvider.notifier).syncMembers(roomId),
  ]);

  ref.read(roomListServiceProvider.notifier).markAsRead(roomId);
}

/// 群聊房间列表（房间类型为 GROUP）
@riverpod
List<ChatRoomVO> groupRoomList(Ref ref) {
  final roomListAsync = ref.watch(roomListServiceProvider);

  return roomListAsync.maybeWhen(
    data: (rooms) => rooms.where((r) => r.roomType == 1).toList(),
    orElse: () => const [],
  );
}

/// 房间搜索关键词
@riverpod
class RoomSearchQuery extends _$RoomSearchQuery {
  @override
  String build() => '';

  void update(String query) => state = query;
}

/// 根据关键词过滤后的聊天室列表
///
/// 匹配规则：房间名称 或 最后一条消息内容
///
/// 防御约束：查询型 Provider 返回空集合而非抛错/空引用。
@riverpod
List<ChatRoomVO> filteredRoomList(Ref ref) {
  final roomListAsync = ref.watch(roomListServiceProvider);
  final query = ref.watch(roomSearchQueryProvider).trim().toLowerCase();

  return roomListAsync.maybeWhen(
    data: (rooms) {
      if (query.isEmpty) return rooms;

      return rooms.where((room) {
        final nameMatch = (room.roomName ?? '').toLowerCase().contains(query);
        final msgMatch = (room.lastMessage?.content ?? '')
            .toLowerCase()
            .contains(query);
        return nameMatch || msgMatch;
      }).toList();
    },
    loading: () => const [],
    orElse: () => const [],
  );
}

/// 根据关键词过滤并按置顶优先排序后的聊天室列表（保留异步状态）
///
/// 供页面直接使用 `when` 处理 loading/error/data。
final filteredSortedRoomListAsyncProvider =
    Provider<AsyncValue<List<ChatRoomVO>>>((ref) {
      final roomListAsync = ref.watch(roomListServiceProvider);
      final query = ref.watch(roomSearchQueryProvider).trim().toLowerCase();
      final pinnedIds = ref.watch(pinnedRoomsProvider);

      return roomListAsync.whenData((rooms) {
        final filteredRooms = query.isEmpty
            ? rooms
            : rooms.where((room) {
                final nameMatch = (room.roomName ?? '').toLowerCase().contains(
                  query,
                );
                final msgMatch = (room.lastMessage?.content ?? '')
                    .toLowerCase()
                    .contains(query);
                return nameMatch || msgMatch;
              }).toList();

        if (filteredRooms.isEmpty || pinnedIds.isEmpty) {
          return filteredRooms;
        }

        final pinnedRooms = <ChatRoomVO>[];
        final normalRooms = <ChatRoomVO>[];
        for (final room in filteredRooms) {
          final id = room.roomId;
          if (id != null && pinnedIds.contains(id)) {
            pinnedRooms.add(room);
          } else {
            normalRooms.add(room);
          }
        }

        return <ChatRoomVO>[...pinnedRooms, ...normalRooms];
      });
    });

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

/// 根据房间 ID 获取对应的聊天室对象
@riverpod
ChatRoomVO? currentRoom(Ref ref, String roomId) {
  // 1. 监听整个房间列表的状态
  final roomListState = ref.watch(roomListServiceProvider);

  // 2. 从列表中筛选出对应的房间
  return RoomLookupHelper.findByRoomId(roomListState.value, roomId);
}
