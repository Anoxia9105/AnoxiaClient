import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../domain/ChatRoomMemberVO.dart';
import '../../../network/DioClient.dart';
import '../../../logs/talker.dart';

part 'room_member_service.g.dart';

@Riverpod(keepAlive: true)
class RoomMemberService extends _$RoomMemberService {
  // 记录已经同步过成员列表的房间 ID，避免重复请求
  final Set<String> _syncedRoomIds = {};

  @override
  Map<String, List<ChatRoomMemberVO>> build() {
    // 初始为空 Map，key 是 roomId
    return {};
  }

  /// 核心：同步房间成员列表
  /// [force] 是否强制刷新（忽略缓存）
  Future<void> syncMembers(String roomId, {bool force = false}) async {
    // 如果已经同步过且不强制刷新，直接返回
    if (_syncedRoomIds.contains(roomId) && !force) return;

    log.info("🚀 正在拉取房间 $roomId 的成员列表...${force ? '（强制刷新）' : ''}");

    try {
      final res = await DioClient().get(
        "/chat/members",
        queryParameters: {'roomId': roomId},
      );

      final data = res.data["data"];
      if (data is List) {
        final List<ChatRoomMemberVO> members = data
            .map((e) => ChatRoomMemberVO.fromJson(e))
            .toList();

        // 更新状态：保持旧的 Map，只替换/增加当前房间的成员
        state = {...state, roomId: members};

        // 只有成功才加入/保留在已同步列表中
        if (!_syncedRoomIds.contains(roomId)) {
          _syncedRoomIds.add(roomId);
        }
        log.info("✅ 房间 $roomId 成员同步完成，共 ${members.length} 人");
      }
    } catch (e, st) {
      log.error("❌ 同步房间 $roomId 成员失败", e, st);
      // 失败了不加进 synced 列表，下次进房还可以重试
    }
  }

  /// 全局更新：当某个用户上下线时，更新所有包含该用户的房间
  void updateGlobalUserStatus(int userId, bool isOnline) {
    final newState = <String, List<ChatRoomMemberVO>>{};
    bool changed = false;

    state.forEach((roomId, members) {
      final index = members.indexWhere((m) => m.userId == userId);
      if (index != -1) {
        final newList = List<ChatRoomMemberVO>.from(members);
        newList[index] = newList[index].copyWith(onlineStatus: isOnline);
        newState[roomId] = newList;
        changed = true;
      } else {
        newState[roomId] = members;
      }
    });

    if (changed) {
      state = newState; // 只有发生变化时才触发 Riverpod UI 刷新
    }
  }

  /// 获取指定房间的成员（辅助 Getter）
  List<ChatRoomMemberVO> getMembersByRoom(String roomId) {
    return state[roomId] ?? [];
  }

  /// 登出时清理所有缓存
  void clearAll() {
    _syncedRoomIds.clear();
    state = {};
  }

  /// 添加成员到群聊
  Future<bool> addMembers(String roomId, List<int> userIds) async {
    try {
      log.info("🚀 正在添加成员到房间 $roomId，用户ID: $userIds");

      final res = await DioClient().post(
        "/chat/room/addMembers",
        data: {
          "roomId": roomId,
          "userIds": userIds,
        },
      );

      if (res.data["code"] == 200) {
        log.info("✅ 添加成员成功");
        // 强制刷新成员列表
        await syncMembers(roomId, force: true);
        return true;
      }
      return false;
    } catch (e, st) {
      log.error("❌ 添加成员失败", e, st);
      return false;
    }
  }
}
