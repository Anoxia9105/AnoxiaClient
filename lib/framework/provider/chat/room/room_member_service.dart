import 'package:anoxia/common/constants/API.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../domain/ChatRoomMemberVO.dart';
import '../../../network/DioClient.dart';
import '../../../logs/talker.dart';

part 'room_member_service.g.dart';

// ================= Provider 选择器 =================
// 把常用的衍生数据提取成独立 Provider，好处：
//   1. UI 只订阅自己需要的数据，精准重建，不会因为其他房间成员变化而重建
//   2. 调用方不需要手写 .select()，语义更清晰
//   3. 逻辑集中在 service 层，不散落在各个 Widget 里

/// 获取指定房间的成员列表（List）
/// 用法：ref.watch(roomMembersProvider('roomId'))
/// 当该房间成员变化时才重建，其他房间变化不影响
@riverpod
List<ChatRoomMemberVO> roomMembers(Ref ref, String roomId) {
  final state = ref.watch(roomMemberServiceProvider);
  return state[roomId]?.values.toList() ?? [];
}

/// 获取指定房间的成员数量
/// 用法：ref.watch(roomMemberCountProvider('roomId'))
@riverpod
int roomMemberCount(Ref ref, String roomId) {
  final members = ref.watch(roomMembersProvider(roomId));
  return members.length;
}

/// 获取指定房间内某个用户的成员信息
/// 用法：ref.watch(roomMemberProvider(('roomId', userId)))
/// 用 Record 作为参数避免定义额外的参数类
@riverpod
ChatRoomMemberVO? roomMember(Ref ref, (String, int) args) {
  final (roomId, userId) = args;
  final state = ref.watch(roomMemberServiceProvider);
  return state[roomId]?[userId];
}

/// 判断指定用户在某房间是否是管理员（roleId == 0）
/// 用法：ref.watch(isRoomAdminProvider(('roomId', userId)))
@riverpod
bool isRoomAdmin(Ref ref, (String, int) args) {
  final member = ref.watch(roomMemberProvider(args));
  return member?.roleId == 0;
}

// ================= Service =================

/// 房间成员服务
///
/// 数据结构：Map<roomId, Map<userId, ChatRoomMemberVO>>
/// 用双层 Map 实现 O(1) 按房间、按用户 ID 查询
///
/// keepAlive: true — 跨页面保持缓存，避免重复拉取
@Riverpod(keepAlive: true)
class RoomMemberService extends _$RoomMemberService {
  /// 已同步过的房间 ID 集合，用于避免重复请求
  /// force=true 时忽略此缓存
  final Set<String> _syncedRoomIds = {};

  @override
  Map<String, Map<int, ChatRoomMemberVO>> build() {
    return {};
  }

  // ================= 数据同步 =================

  /// 同步指定房间的成员列表
  ///
  /// [roomId] 目标房间 ID
  /// [force] 是否强制重新拉取（忽略本地缓存），默认 false
  ///
  /// 已同步过的房间默认跳过，以下场景需要 force=true：
  ///   - 添加/踢出成员后
  ///   - 收到成员变化的 WebSocket 推送后
  Future<void> syncMembers(String roomId, {bool force = false}) async {
    // 已同步且不强制刷新，直接跳过
    if (_syncedRoomIds.contains(roomId) && !force) return;

    log.info("🚀 拉取房间 $roomId 成员列表");

    try {
      final res = await DioClient().get(
        API.chatMembers,
        queryParameters: {'roomId': roomId},
      );

      final data = res.data["data"];
      if (data is! List) return;

      // 构建 userId -> ChatRoomMemberVO 的 Map，实现 O(1) 查询
      final Map<int, ChatRoomMemberVO> members = {
        for (final e in data)
          if (ChatRoomMemberVO.fromJson(e).userId != null)
            ChatRoomMemberVO.fromJson(e).userId!: ChatRoomMemberVO.fromJson(e),
      };

      // 不可变更新：只替换目标房间，其他房间数据保持不变
      state = {...state, roomId: members};
      _syncedRoomIds.add(roomId);

      log.info("✅ 房间 $roomId 成员同步完成，共 ${members.length} 人");
    } catch (e, st) {
      log.error("❌ 同步成员失败", e, st);
    }
  }

  // ================= 状态更新 =================

  /// 全局更新某用户的在线状态
  /// 通常由 WebSocket 在线状态推送触发
  /// 会遍历所有房间，将该用户的在线状态同步更新
  ///
  /// [userId] 目标用户 ID
  /// [isOnline] true=上线，false=下线
  void updateGlobalUserStatus(int userId, bool isOnline) {
    bool changed = false;

    // 遍历所有房间，找到包含该用户的房间并更新
    final newState = state.map((roomId, members) {
      if (!members.containsKey(userId)) return MapEntry(roomId, members);

      changed = true;
      return MapEntry(roomId, {
        ...members,
        userId: members[userId]!.copyWith(onlineStatus: isOnline),
      });
    });

    // 只有真正有变化才触发重建，避免无效 notify
    if (changed) state = newState;
  }

  /// 更新单个成员信息（收到服务端推送时使用）
  ///
  /// [roomId] 目标房间
  /// [member] 最新的成员数据
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
  ///
  /// [roomId] 目标房间
  /// [userId] 被移除的用户 ID
  void removeMember(String roomId, int userId) {
    final roomMembers = state[roomId];
    if (roomMembers == null) return;

    final updated = Map<int, ChatRoomMemberVO>.from(roomMembers)
      ..remove(userId);
    state = {...state, roomId: updated};
  }

  // ================= 远程操作 =================

  /// 批量添加成员到房间
  ///
  /// [roomId] 目标房间
  /// [userIds] 要添加的用户 ID 列表
  /// 返回 true 表示成功
  Future<bool> addMembers(String roomId, List<int> userIds) async {
    try {
      log.info("🚀 添加成员 $userIds 到房间 $roomId");

      final res = await DioClient().post(
        API.chatRoomAddMembers,
        data: {"roomId": roomId, "userIds": userIds},
      );

      if (res.data["code"] == 200) {
        // 添加成功后强制刷新成员列表
        await syncMembers(roomId, force: true);
        return true;
      }

      return false;
    } catch (e, st) {
      log.error("❌ 添加成员失败", e, st);
      return false;
    }
  }

  /// 踢出成员
  ///
  /// [roomId] 目标房间
  /// [targetUserId] 被踢出的用户 ID
  /// 返回 true 表示成功
  Future<bool> kickMember(String roomId, int targetUserId) async {
    try {
      log.info("🚀 从房间 $roomId 踢出用户 $targetUserId");

      final res = await DioClient().get(
        API.chatRoomKickMember,
        queryParameters: {"roomId": roomId, "targetUserId": targetUserId},
      );

      if (res.data["code"] == 200) {
        // 先乐观更新本地缓存（立即生效，不用等服务端）
        removeMember(roomId, targetUserId);
        // 再强制同步确保数据一致
        await syncMembers(roomId, force: true);
        return true;
      }

      return false;
    } catch (e, st) {
      log.error("❌ 踢人失败", e, st);
      return false;
    }
  }

  // ================= 缓存管理 =================

  /// 清空所有缓存（退出登录时调用）
  void clearAll() {
    _syncedRoomIds.clear();
    state = {};
  }

  /// 清空指定房间的缓存（退出房间时调用）
  void clearRoom(String roomId) {
    _syncedRoomIds.remove(roomId);
    final newState = Map<String, Map<int, ChatRoomMemberVO>>.from(state)
      ..remove(roomId);
    state = newState;
  }
}