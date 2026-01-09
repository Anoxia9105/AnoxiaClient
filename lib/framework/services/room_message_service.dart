import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../logs/talker.dart';
import '../protocol/PacketType.dart';
import '../protocol/message/RoomMessage.dart';
import '../provider/ws/ws_controller.dart';

part 'room_message_service.g.dart';

@riverpod
class ChatMessages extends _$ChatMessages {
  @override
  Map<String, List<RoomMessage>> build() {
    // 1. 获取原始流
    final stream = ref.watch(wsControllerProvider.notifier).messageStream;

    // 2. 建立监听流水线
    final subscription = stream
        .where((frame) => frame.topic == PacketType.message)
        .map((frame) => frame.data as RoomMessage)
        .listen((msg) {
          // 3. 收到消息后更新状态
          _addMessage(msg);
        });

    // 4. 💡 关键：当这个 Provider 销毁时，必须取消订阅，防止内存泄漏
    ref.onDispose(() {
      log.info("聊天消息服务销毁，取消订阅");
      subscription.cancel();
    });

    return {}; // 初始为空
  }

  void _addMessage(RoomMessage msg) {
    final roomId = msg.roomId ?? "system";
    // 获取当前房间的旧消息列表
    final currentRoomMessages = state[roomId] ?? []; // 拿到旧列表的引用

    //水位限制
    const int maxMessagePerRoom = 100;

    List<RoomMessage> newList = [...currentRoomMessages, msg];

    // 如果超过限制，删除最旧的（列表头部的）
    if (newList.length > maxMessagePerRoom) {
      // 移除前 20 条，避免频繁触发删除动作（建议成批删除，性能更好）
      newList = newList.sublist(newList.length - maxMessagePerRoom);
      log.info("房间 $roomId 超过内存阈值，执行自动清理");
    }

    // 💡 这里的更新必须创建新 List 才能触发 UI 刷新
    state = {
      ...state, // 把所有房间的旧数据都复制一份
      //把旧列表里的消息取出来 把新消息放进去
      roomId: newList, // 唯独覆盖掉当前这个 roomId 的数据
    };
  }

  /// 也可以提供清空某个房间消息的方法
  void clearRoom(String roomId) {
    state = {...state, roomId: []};
  }

  // 在 UI 或者是调试工具里调用这个，查看当前内存压力
  int get totalMessageCount {
    return state.values.fold(0, (sum, list) => sum + list.length);
  }
}
