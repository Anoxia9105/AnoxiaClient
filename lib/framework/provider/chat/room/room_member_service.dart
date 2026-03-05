import 'package:anoxia/common/constants/API.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../domain/ChatRoomMemberVO.dart';
import '../../../network/DioClient.dart';
import '../../../logs/talker.dart';

part 'room_member_service.g.dart';

@Riverpod(keepAlive: true)
class RoomMemberService extends _$RoomMemberService {
  /// 已同步房间
  final Set<String> _syncedRoomIds = {};

  @override
  Map<String, Map<int, ChatRoomMemberVO>> build() {
    return {};
  }

  /// 同步房间成员
  Future<void> syncMembers(String roomId, {bool force = false}) async {
    if (_syncedRoomIds.contains(roomId) && !force) return;

    log.info("🚀 拉取房间 $roomId 成员列表");

    try {
      final res = await DioClient().get(
        API.chatMembers,
        queryParameters: {'roomId': roomId},
      );

      final data = res.data["data"];

      if (data is List) {
        final Map<int, ChatRoomMemberVO> members = {};

        for (final e in data) {
          final m = ChatRoomMemberVO.fromJson(e);
          if (m.userId != null) {
            members[m.userId!] = m;
          }
        }

        state = {...state, roomId: members};

        _syncedRoomIds.add(roomId);

        log.info("✅ 房间 $roomId 成员同步完成 ${members.length}");
      }
    } catch (e, st) {
      log.error("❌ 同步成员失败", e, st);
    }
  }

  /// O(1) 获取成员
  ChatRoomMemberVO? getMember(String? roomId, int? userId) {
    if (roomId == null || userId == null) return null;
    return state[roomId]?[userId];
  }

  /// 获取房间成员列表
  List<ChatRoomMemberVO> getMembersByRoom(String roomId) {
    return state[roomId]?.values.toList() ?? [];
  }

  /// 更新用户在线状态（全局）
  void updateGlobalUserStatus(int userId, bool isOnline) {
    final newState = <String, Map<int, ChatRoomMemberVO>>{};
    bool changed = false;

    state.forEach((roomId, members) {
      if (members.containsKey(userId)) {
        final updated = members[userId]!.copyWith(onlineStatus: isOnline);

        newState[roomId] = {...members, userId: updated};

        changed = true;
      } else {
        newState[roomId] = members;
      }
    });

    if (changed) {
      state = newState;
    }
  }

  /// 清空缓存
  void clearAll() {
    _syncedRoomIds.clear();
    state = {};
  }

  /// 添加成员
  Future<bool> addMembers(String roomId, List<int> userIds) async {
    try {
      log.info("🚀 添加成员 $userIds 到房间 $roomId");

      final res = await DioClient().post(
        API.chatRoomAddMembers,
        data: {"roomId": roomId, "userIds": userIds},
      );

      if (res.data["code"] == 200) {
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
  Future<bool> kickMember(String roomId, int targetUserId) async {
    try {
      log.info("🚀 从房间 $roomId 踢出 $targetUserId");

      final res = await DioClient().get(
        API.chatRoomKickMember,
        queryParameters: {"roomId": roomId, "targetUserId": targetUserId},
      );

      if (res.data["code"] == 200) {
        await syncMembers(roomId, force: true);
        return true;
      }

      return false;
    } catch (e, st) {
      log.error("❌ 踢人失败", e, st);
      return false;
    }
  }
}
