import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:anoxia/framework/services/room_member_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../protocol/PacketType.dart';
import '../protocol/message/EventMessage.dart';
import 'contact_list_service.dart';

part 'system_event_service.g.dart';

/// 系统事件服务 - 负责全局监听并分发处理逻辑
@Riverpod(keepAlive: true) // 保持活跃，全局单例监听
class SystemEventService extends _$SystemEventService {
  @override
  void build() {
    // 1. 监听 WebSocket 消息流中的 EVENT 类型
    final stream = ref.watch(wsControllerProvider.notifier).messageStream;

    final subscription = stream
        .where((frame) => frame.topic == PacketType.event)
        .map((frame) => frame.data as EventMessage)
        .listen(_onEventReceived);

    // 2. 销毁时释放
    ref.onDispose(() {
      log.info("系统事件服务销毁");
      subscription.cancel();
    });
  }

  /// 核心分发逻辑
  void _onEventReceived(EventMessage event) {
    log.info("收到系统事件: ${event.eventType} 从用户: ${event.operatorId}");

    switch (event.eventType) {
      case SystemEventType.userOnline:
      case SystemEventType.userOffline:
        _handleUserStatusChange(event);
        break;

      case SystemEventType.userKicked:
        _handleUserKicked(event);
        break;

      case SystemEventType.roomClosed:
        _handleRoomClosed(event);
        break;

      default:
        log.debug("暂未处理的系统事件类型: ${event.eventType}");
    }
  }

  // --- 具体处理逻辑 ---

  /// 处理用户上下线
  void _handleUserStatusChange(EventMessage event) {
    final isOnline = event.eventType == SystemEventType.userOnline;

    // 1. 更新群聊成员状态 (RoomMemberService)
    ref
        .read(roomMemberServiceProvider.notifier)
        .updateGlobalUserStatus(event.operatorId, isOnline);
    // 2. 更新通讯录联系人状态 (ContactListService)
    ref
        .read(contactListServiceProvider.notifier)
        .updateOnlineStatus(event.operatorId, isOnline);

    log.info("用户 ${event.operatorId} ${isOnline ? '上线' : '下线'}");
  }

  /// 处理被踢出房间
  void _handleUserKicked(EventMessage event) {
    // 逻辑：如果当前正在该房间，强制退出 UI 并提示
    // final currentRoomId = ref.read(activeRoomIdProvider);
    // if (currentRoomId == event.roomId) { ... 导航回主页 ... }
    log.warning("你已被踢出房间");
  }

  /// 处理房间注销
  void _handleRoomClosed(EventMessage event) {
    // 逻辑：从房间列表中移除该房间
    // ref.read(roomListServiceProvider.notifier).removeRoom(event.roomId);
  }
}
