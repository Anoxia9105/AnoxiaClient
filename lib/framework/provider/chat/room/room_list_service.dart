import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/ChatMessage.dart';
import '../../../domain/ChatRoomVO.dart';

part 'room_list_service.g.dart';

@Riverpod(keepAlive: true)
class RoomListService extends _$RoomListService {
  @override
  FutureOr<List<ChatRoomVO>> build() async {
    return await fetchRoomList();
  }

  Future<List<ChatRoomVO>> fetchRoomList() async {
    try {
      final res = await DioClient().get("/chat/rooms");

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
  Future<void> refresh({bool silent = false}) async {
    if (!silent) state = const AsyncValue.loading();
    final newState = await AsyncValue.guard(() => fetchRoomList());
    state = newState;
  }

  /// 实时更新：增加是否计算未读数的逻辑
  void updateRoomPosition(
    ChatMessage newMessage, {
    bool isCurrentRoom = false,
  }) {
    state.whenData((rooms) {
      final List<ChatRoomVO> updatedList = List.from(rooms);
      final index = updatedList.indexWhere(
        (r) => r.roomId == newMessage.roomId,
      );

      if (index != -1) {
        final oldRoom = updatedList.removeAt(index);

        // 如果是当前房间，未读数不增加；否则 +1
        final int newUnread = isCurrentRoom
            ? (oldRoom.unreadCount ?? 0)
            : (oldRoom.unreadCount ?? 0) + 1;

        final newRoom = oldRoom.copyWith(
          lastMessage: newMessage,
          unreadCount: newUnread,
        );

        updatedList.insert(0, newRoom);
        state = AsyncValue.data(updatedList);
      } else {
        // 如果列表中没有这个房间（比如新开启的私聊），建议直接触发一次 fetchRoomList
        refresh(silent: true);
      }
    });
  }

  // 在 RoomListService 类中添加
  void markAsRead(String roomId) {
    state.whenData((rooms) {
      final index = rooms.indexWhere((r) => r.roomId == roomId);
      if (index != -1 && (rooms[index].unreadCount ?? 0) > 0) {
        final List<ChatRoomVO> updatedList = List.from(rooms);

        // 更新该房间的未读数为 0
        updatedList[index] = updatedList[index].copyWith(unreadCount: 0);

        // 这里的 seq 通常取自 lastMessage.seq
        final int? lastSeq = updatedList[index].lastMessage?.seq;
        if (lastSeq != null) {
          _reportReadSeq(roomId, lastSeq); // 触发上报
        }

        state = AsyncValue.data(updatedList);
      }
    });
  }

  // TODO: 实现上报最新 seq 的接口调用
  Future<void> _reportReadSeq(String roomId, int seq) async {
    try {
      print("🚀 上报已读状态: 房间 $roomId, Seq $seq");
      // await DioClient().post("/chat/readReport", data: {"roomId": roomId, "seq": seq});
    } catch (e) {
      print("上报已读失败: $e");
    }
  }
}

//当前选中房间
@riverpod
class ActiveRoomId extends _$ActiveRoomId {
  @override
  String? build() => null; // 初始没有选中的房间

  void setActive(String roomId) {
    if (state == roomId) return;
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
        .where((r) => r.roomType == '1') // GROUP
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
