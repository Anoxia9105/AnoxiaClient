import 'dart:async';

import 'package:anoxia/framework/core/notification_helper.dart';
import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:anoxia/framework/codec/v6/im_packet_v6.dart';
import 'package:anoxia/framework/provider/core/chat_repository_provider.dart';
import 'package:anoxia/framework/provider/core/sync_conversations_usecase_provider.dart';
import 'package:anoxia/framework/provider/core/room_repository_provider.dart';
import 'package:anoxia/features/chat/application/system_message_formatter.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/room/do_not_disturb_rooms_provider.dart';
import 'package:anoxia/framework/provider/chat/room/group_announcement_dismissal_provider.dart';
import 'package:anoxia/framework/provider/chat/room/message_notification_policy.dart';
import 'package:anoxia/framework/provider/chat/room/pinned_rooms_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_lookup_helper.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/chat_message.dart';
import '../../../domain/chat_room_vo.dart';
import '../../../domain/official_room_config.dart';
import 'official_room_provider.dart';
import '../../setting/hide_official_room_provider.dart';
import 'package:anoxia/framework/logs/debug_log.dart';

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

  /// 首次拉取是否已完成
  ///
  /// 登录后预加载期间，本地缓存的「空列表」不能作为最终结果上屏，
  /// 否则会先闪「无会话」空态、服同同步完成后才显示列表。
  /// 空态 UI 只能由 fetch 结果决定，非空缓存则允许立即展示。
  bool _initialFetchDone = false;

  /// 剔除误用前端保留 ID 的服务端房间。
  ///
  /// 虚拟官方入口只存在于展示层。若缓存或接口异常返回同 ID 的真实房间，
  /// 将其从普通会话列表移除并清理本地副本，避免出现重复入口。
  List<ChatRoomVO> _pruneReservedOfficialRoomCollisions(
    List<ChatRoomVO> rooms,
  ) {
    final collisions = rooms
        .where(OfficialRoomConfig.usesReservedVirtualRoomId)
        .toList();
    if (collisions.isEmpty) return rooms;
    for (final room in collisions) {
      final id = room.roomId;
      if (id != null) {
        unawaited(
          ref.read(localDataSourceProvider).markConversationDeleted(id),
        );
      }
    }
    return rooms
        .where((r) => !OfficialRoomConfig.usesReservedVirtualRoomId(r))
        .toList();
  }

  @override
  FutureOr<List<ChatRoomVO>> build() async {
    ref.onDispose(() {
      // 销毁时：将所有待上报的 seq 立即上报，然后取消定时器
      for (final entry in _pendingReadSeqs.entries) {
        _sendReadCursor(entry.key, entry.value);
      }
      for (final timer in _readDebounceTimers.values) {
        timer.cancel();
      }
      _readDebounceTimers.clear();
      _pendingReadSeqs.clear();
    });
    final subscription = ref
        .read(chatRepositoryProvider)
        .watchConversations()
        .listen((rooms) {
          // 首次拉取完成前，空缓存不覆盖 state（保持 loading 到 fetch 出结果），
          // 避免「先显示无数据、后显示列表」的闪烁；有缓存房间则立即上屏。
          if (!_initialFetchDone && rooms.isEmpty) return;
          state = AsyncValue.data(_pruneReservedOfficialRoomCollisions(rooms));
        });
    ref.onDispose(subscription.cancel);

    // 未登录时不发起会话列表网络请求：已登录后的 fetch 由登录流程
    // 通过 invalidate(roomListServiceProvider) 触发。否则匿名请求会收到
    // 401，被 DioClient 误判为「token 过期」触发登出，并因本 Provider 为
    // keepAlive 被登出时的会话重置重新 invalidate，形成
    // 「401 → 登出 → 重建 → 再 401」的无限循环，导致刚登录进首页又被登出。
    if (ref.read(authControllerProvider).value == null) {
      return state.value ?? const <ChatRoomVO>[];
    }

    try {
      return await _fetchRoomListForStartup();
    } finally {
      _initialFetchDone = true;
    }
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
      return [];
    }

    try {
      return await ref.read(syncConversationsUseCaseProvider)();
    } on DioException catch (e) {
      // 处理 401 登录过期错误：在初始化时优雅地返回空列表而不是崩溃
      // DioClient 的拦截器已处理登出逻辑，此处仅需返回空列表
      if (e.error == '登录过期') {
        debugLog('登录已过期，返回空列表');
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
      // 先等待会话同步完成，避免首次加载显示空列表
      await ref.read(syncConversationsUseCaseProvider).sync();
      // 同步完成后获取会话列表（不再触发后台同步）
      final rooms = await ref
          .read(syncConversationsUseCaseProvider)(sync: false)
          .timeout(_startupFetchTimeout);
      return _pruneReservedOfficialRoomCollisions(rooms);
    } on TimeoutException catch (e, st) {
      debugLog('[RoomListService] 房间列表加载超时，使用空列表继续启动', e, st);
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
        action == 'CALL_STARTED' ||
        action == 'CALL_ENDED' ||
        action == 'CALL_REJECTED' ||
        action == 'CALL_CANCELED';

    state.whenData((rooms) {
      final oldRoom = RoomLookupHelper.findByRoomId(rooms, newMessage.roomId);
      if (oldRoom != null) {
        final lifecycle = WidgetsBinding.instance.lifecycleState;
        // Flutter maps a hidden Web window/tab to AppLifecycleState.hidden.
        // Source: https://api.flutter.dev/flutter/dart-ui/AppLifecycleState.html
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
        final shouldShowLocalNotification = shouldShowLocalMessageNotification(
          isSelfMessage: isSelfMessage,
          isCallSystemMessage: isCallSystemMessage,
          isCurrentRoom: isCurrentRoom,
          isDoNotDisturb: isDoNotDisturb,
          isMobile: isMobile,
          isAppForeground: isAppForeground,
          isWeb: kIsWeb,
        );

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
            _sendReadCursor(roomId, seqToReport);
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
        _sendReadCursor(roomId, pendingSeq);
      }
    });
  }

  /// 上报已读 seq 到服务器，同时更新本地 DB（last_read_seq / unread_count）
  Future<void> _sendReadCursor(String roomId, int seq) async {
    try {
      await ref
          .read(localDataSourceProvider)
          .markConversationAsRead(roomId, seq: seq);
      ref
          .read(wsControllerProvider.notifier)
          .sendMessage(ImPacketV6.encodeReadCursorFrame(roomId, seq));
    } catch (e) {
      debugLog('上报已读失败: $e');
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
      return existingRoom.roomId;
    }

    try {
      final newRoom = await ref
          .read(roomRepositoryProvider)
          .createPrivateRoom(targetUserId);

      if (newRoom == null) {
        return null;
      }

      // 静默刷新房间列表，确保 UI 侧边栏能同步看到新房间
      await refresh(silent: true);

      return newRoom.roomId;
    } catch (e) {
      debugLog('❌ 获取/创建房间接口调用失败', e);
      return null;
    }
  }

  /// 退出聊天室
  Future<void> leaveRoom(String roomId) async {
    try {
      await ref.read(roomRepositoryProvider).leaveRoom(roomId);

      await ref.read(localDataSourceProvider).deleteConversationCache(roomId);

      // 删除对应房间缓存的消息
      ref.read(chatMessagesProvider.notifier).clearRoom(roomId);

      // 清理加载更多状态
      ref.read(chatHasMoreProvider.notifier).setHasMore(roomId, false);
      await ref.read(doNotDisturbRoomsProvider.notifier).remove(roomId);

      await refresh(silent: true);
    } catch (e) {
      debugLog('❌ 删除会话失败', e);
      rethrow;
    }
  }

  /// 解散群聊
  Future<void> dissolveGroup(String roomId) async {
    try {
      await ref.read(roomRepositoryProvider).disbandRoom(roomId);
      await refresh(silent: true);
    } catch (e) {
      debugLog('❌ 解散群聊失败', e);
      rethrow;
    }
  }

  /// 房间禁言/解除禁言
  ///
  /// [roomId] 房间ID
  /// [isMute] true=禁言，false=解除禁言
  Future<bool> muteRoom(String roomId, bool isMute) async {
    try {
      final ok = await ref
          .read(roomRepositoryProvider)
          .muteRoom(roomId, isMute);

      if (ok) {
        await refresh(silent: true);
      }
      return ok;
    } catch (e, st) {
      debugLog("❌ ${isMute ? '禁言' : '解除禁言'}房间失败", e, st);
      return false;
    }
  }

  /// 修改群聊名称
  Future<bool> updateGroupName(String roomId, String roomName) async {
    try {
      final ok = await ref
          .read(roomRepositoryProvider)
          .updateGroupName(roomId, roomName);

      if (ok) {
        await refresh(silent: true);
      }
      return ok;
    } catch (e, st) {
      debugLog('❌ 修改群聊名称失败', e, st);
      return false;
    }
  }

  /// 修改群公告
  Future<bool> updateGroupAnnouncement(
    String roomId,
    String roomAnnouncement,
  ) async {
    try {
      final ok = await ref
          .read(roomRepositoryProvider)
          .updateGroupAnnouncement(roomId, roomAnnouncement);

      if (ok) {
        // 自己发布公告后本地标记为已关闭，避免 WS 推送回包导致横幅闪现；
        // 只有他人推送的新公告才会重新显示横幅。
        await ref
            .read(groupAnnouncementDismissalProvider.notifier)
            .dismiss(roomId, roomAnnouncement.trim());
        await refresh(silent: true);
      }
      return ok;
    } catch (e, st) {
      debugLog('❌ 修改群公告失败', e, st);
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
  /// 离开旧房间与进入新房间时都会调用 [RoomListService.markAsRead]，
  /// 确保未读角标可以在进入会话后立即清零。
  void setActive(String? roomId) {
    if (state == roomId) return;

    final oldRoomId = state;
    final roomList = ref.read(roomListServiceProvider.notifier);

    if (oldRoomId != null) {
      roomList.markAsRead(oldRoomId);
    }

    state = roomId;

    if (roomId != null) {
      roomList.markAsRead(roomId);
    }
  }
}

/// 进入房间时的初始化任务
///
/// 确保消息和成员数据已同步到本地
@riverpod
Future<void> roomEntryTask(Ref ref, String roomId) async {
  final room = ref.watch(currentRoomProvider(roomId));

  // 官方虚拟房间无需同步消息 / 成员
  if (room?.isOfficial ?? false) return;

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

/// 在房间列表中注入虚拟官方房间（受显隐开关控制）。
List<ChatRoomVO> _injectOfficialRoom(
  List<ChatRoomVO> rooms,
  bool hidden,
  ChatRoomVO official,
) {
  if (hidden) return rooms;
  if (rooms.any((r) => r.roomId == OfficialRoomConfig.virtualRoomId)) {
    return rooms;
  }
  return [official, ...rooms];
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
      final base = _injectOfficialRoom(
        rooms,
        ref.watch(hideOfficialRoomProvider),
        ref.watch(officialRoomProvider),
      );
      if (query.isEmpty) return base;

      return base.where((room) {
        final searchableName = room.isOfficial
            ? 'official_room_name'.tr()
            : (room.roomName ?? '');
        final nameMatch = searchableName.toLowerCase().contains(query);
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
        final base = _injectOfficialRoom(
          rooms,
          ref.watch(hideOfficialRoomProvider),
          ref.watch(officialRoomProvider),
        );
        final filteredRooms = query.isEmpty
            ? base
            : base.where((room) {
                final searchableName = room.isOfficial
                    ? 'official_room_name'.tr()
                    : (room.roomName ?? '');
                final nameMatch = searchableName.toLowerCase().contains(query);
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
  // 官方虚拟房间直接返回构造好的虚拟房间（受显隐开关控制）
  if (roomId == OfficialRoomConfig.virtualRoomId) {
    if (ref.watch(hideOfficialRoomProvider)) return null;
    return ref.watch(officialRoomProvider);
  }

  // 1. 监听整个房间列表的状态
  final roomListState = ref.watch(roomListServiceProvider);

  // 2. 从列表中筛选出对应的房间
  return RoomLookupHelper.findByRoomId(roomListState.value, roomId);
}
