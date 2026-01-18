import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/ChatRoomMemberVO.dart';
import '../network/DioClient.dart';
import '../logs/talker.dart';

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
  Future<void> syncMembers(String roomId) async {
    // 如果已经同步过，直接返回（除非你需要强制刷新）
    if (_syncedRoomIds.contains(roomId)) return;

    log.info("🚀 正在拉取房间 $roomId 的成员列表...");

    try {
      final res = await DioClient().get("/chat/members", queryParameters: {
        'roomId': roomId,
      });

      final data = res.data["data"];
      if (data is List) {
        final List<ChatRoomMemberVO> members = data
            .map((e) => ChatRoomMemberVO.fromJson(e))
            .toList();

        // 更新状态：保持旧的 Map，只替换/增加当前房间的成员
        state = {
          ...state,
          roomId: members,
        };

        _syncedRoomIds.add(roomId);
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
}