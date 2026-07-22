import 'dart:async';

import 'package:anoxia/common/constants/API.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../domain/ChatRoomMemberVO.dart';
import '../../../network/DioClient.dart';
import '../../../logs/talker.dart';
import '../../auth/auth_controller.dart';
import '../../contact/contact_list_controller.dart';

part 'room_member_service.g.dart';

/// 获取指定房间的成员列表
@riverpod
List<ChatRoomMemberVO> roomMembers(Ref ref, String roomId) {
  final state = ref.watch(roomMemberServiceProvider);
  final members = state[roomId]?.values.toList() ?? [];
  final contacts = ref.watch(contactListServiceProvider).value;
  final currentUser = ref.watch(authControllerProvider).value;

  // 成员接口刚返回空资料或本地仍在同步时，用已缓存的本人/联系人资料补齐，
  // 避免消息和成员列表短暂显示“？”、“用户1”之类的占位内容。
  return members.map((member) {
    final rawName = member.nickName?.trim() ?? '';
    final rawAvatar = member.avatar?.trim() ?? '';
    if (rawName.isNotEmpty && rawAvatar.isNotEmpty) return member;

    final isCurrentUser = member.userId == currentUser?.userId;
    final contact = contacts?[member.userId];
    final fallbackName = isCurrentUser
        ? currentUser?.nickName
        : (contact?.remark?.trim().isNotEmpty == true
              ? contact!.remark
              : contact?.nickName);
    final fallbackAvatar = isCurrentUser
        ? currentUser?.avatar
        : contact?.avatar;

    return member.copyWith(
      nickName: rawName.isEmpty ? fallbackName : member.nickName,
      avatar: rawAvatar.isEmpty ? fallbackAvatar : member.avatar,
    );
  }).toList();
}

/// 获取指定房间的成员数量
@riverpod
int roomMemberCount(Ref ref, String roomId) {
  final members = ref.watch(roomMembersProvider(roomId));
  return members.length;
}

/// 获取指定房间内某个用户的成员信息
///
/// 使用 Record 作为参数避免定义额外的参数类
@riverpod
ChatRoomMemberVO? roomMember(Ref ref, (String, int) args) {
  final (roomId, userId) = args;
  final state = ref.watch(roomMemberServiceProvider);
  return state[roomId]?[userId];
}

/// 判断指定用户在某房间是否是管理员
@riverpod
bool isRoomAdmin(Ref ref, (String, int) args) {
  final member = ref.watch(roomMemberProvider(args));
  return member?.roleId == 0;
}

/// 房间成员服务
///
/// 数据结构：`Map<roomId, Map<userId, ChatRoomMemberVO>>`
/// 双层 Map 实现 O(1) 按房间、按用户 ID 查询
///
/// 采用 keepAlive 模式，跨页面保持缓存避免重复拉取
@Riverpod(keepAlive: true)
class RoomMemberService extends _$RoomMemberService {
  /// 已同步过的房间 ID 集合，用于避免重复请求
  final Set<String> _syncedRoomIds = {};
  final Map<String, Future<void>> _syncingRoomIds = {};

  @override
  Map<String, Map<int, ChatRoomMemberVO>> build() => {};

  /// 同步指定房间的成员列表
  ///
  /// [roomId] 目标房间 ID
  /// [force] 是否强制重新拉取（忽略本地缓存），默认 false
  ///
  /// 以下场景需要 force=true：
  /// - 添加/踢出成员后
  /// - 收到成员变化的 WebSocket 推送后
  Future<void> syncMembers(
    String roomId, {
    bool force = false,
    Duration? timeout,
  }) async {
    if (_syncedRoomIds.contains(roomId) && !force) return;

    final existing = _syncingRoomIds[roomId];
    if (existing != null) return existing;

    final task = _syncMembers(roomId, timeout: timeout);
    _syncingRoomIds[roomId] = task;
    try {
      await task;
    } finally {
      if (identical(_syncingRoomIds[roomId], task)) {
        _syncingRoomIds.remove(roomId);
      }
    }
  }

  Future<void> _syncMembers(String roomId, {Duration? timeout}) async {
    final cancelToken = CancelToken();
    final timeoutTimer = timeout == null
        ? null
        : Timer(timeout, () {
            if (!cancelToken.isCancelled) {
              cancelToken.cancel('room member warm-up timed out');
            }
          });

    log.info('🚀 拉取房间 $roomId 成员列表');

    try {
      final res = await DioClient().get(
        API.chatMembers,
        queryParameters: {'roomId': roomId},
        cancelToken: cancelToken,
      );

      final data = res.data['data'];
      if (data is! List) return;

      // 构建 userId -> ChatRoomMemberVO 的 Map，实现 O(1) 查询
      final Map<int, ChatRoomMemberVO> members = {};
      for (final e in data) {
        if (e is! Map) continue;
        final member = ChatRoomMemberVO.fromJson(Map<String, dynamic>.from(e));
        if (member.userId != null) members[member.userId!] = member;
      }

      state = {...state, roomId: members};
      _syncedRoomIds.add(roomId);

      log.info('✅ 房间 $roomId 成员同步完成，共 ${members.length} 人');
    } on DioException catch (e, st) {
      if (CancelToken.isCancel(e)) {
        log.info('[RoomMember] 房间 $roomId 成员同步已超时取消');
        return;
      }
      log.error('❌ 同步成员失败', e, st);
    } catch (e, st) {
      log.error('❌ 同步成员失败', e, st);
    } finally {
      timeoutTimer?.cancel();
    }
  }

  /// 全局更新某用户的在线状态
  ///
  /// 通常由 WebSocket 在线状态推送触发，
  /// 会遍历所有房间，将该用户的在线状态同步更新。
  void updateGlobalUserStatus(int userId, bool isOnline) {
    bool changed = false;

    final newState = state.map((roomId, members) {
      if (!members.containsKey(userId)) return MapEntry(roomId, members);

      changed = true;
      return MapEntry(roomId, {
        ...members,
        userId: members[userId]!.copyWith(onlineStatus: isOnline),
      });
    });

    if (changed) state = newState;
  }

  /// 更新单个成员信息（收到服务端推送时使用）
  void updateMember(String roomId, ChatRoomMemberVO member) {
    final userId = member.userId;
    if (userId == null) return;

    final roomMembers = state[roomId];
    if (roomMembers == null) return;

    state = {
      ...state,
      roomId: {...roomMembers, userId: member},
    };
  }

  /// 从本地缓存中移除某成员（踢出后本地同步用）
  void removeMember(String roomId, int userId) {
    final roomMembers = state[roomId];
    if (roomMembers == null) return;

    final updated = Map<int, ChatRoomMemberVO>.from(roomMembers)
      ..remove(userId);
    state = {...state, roomId: updated};
  }

  /// 批量添加成员到房间
  ///
  /// [roomId] 目标房间
  /// [userIds] 要添加的用户 ID 列表
  Future<bool> addMembers(String roomId, List<int> userIds) async {
    try {
      log.info('🚀 添加成员 $userIds 到房间 $roomId');

      final res = await DioClient().post(
        API.chatRoomAddMembers,
        data: {'roomId': roomId, 'userIds': userIds},
      );

      if (res.data['code'] == 200) {
        await syncMembers(roomId, force: true);
        return true;
      }

      return false;
    } catch (e, st) {
      log.error('❌ 添加成员失败', e, st);
      return false;
    }
  }

  /// 踢出成员
  ///
  /// [roomId] 目标房间
  /// [targetUserId] 被踢出的用户 ID
  Future<bool> kickMember(String roomId, int targetUserId) async {
    try {
      log.info('🚀 从房间 $roomId 踢出用户 $targetUserId');

      final res = await DioClient().get(
        API.chatRoomKickMember,
        queryParameters: {'roomId': roomId, 'targetUserId': targetUserId},
      );

      if (res.data['code'] == 200) {
        // 先乐观更新本地缓存（立即生效）
        removeMember(roomId, targetUserId);
        // 再强制同步确保数据一致
        await syncMembers(roomId, force: true);
        return true;
      }

      return false;
    } catch (e, st) {
      log.error('❌ 踢人失败', e, st);
      return false;
    }
  }

  /// 清空所有缓存（退出登录时调用）
  void clearAll() {
    _syncedRoomIds.clear();
    _syncingRoomIds.clear();
    state = {};
  }

  /// 清空指定房间的缓存
  void clearRoom(String roomId) {
    _syncedRoomIds.remove(roomId);
    final newState = Map<String, Map<int, ChatRoomMemberVO>>.from(state)
      ..remove(roomId);
    state = newState;
  }
}
