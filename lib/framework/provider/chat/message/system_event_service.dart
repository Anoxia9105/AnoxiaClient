import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../protocol/PacketType.dart';
import '../../../protocol/message/EventMessage.dart';

part 'system_event_service.g.dart';

/// 系统事件服务 - 负责全局监听并分发处理逻辑
@Riverpod(keepAlive: true)
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

      // 新增事件处理
      case SystemEventType.userJoined:
        _handleUserJoined(event);
        break;

      case SystemEventType.userLeft:
        _handleUserLeft(event);
        break;

      case SystemEventType.roomCreated:
        _handleRoomCreated(event);
        break;

      case SystemEventType.roomUpdated:
        _handleRoomUpdated(event);
        break;

      case SystemEventType.userMuted:
        _handleUserMuted(event);
        break;

      case SystemEventType.userRoleChanged:
        _handleUserRoleChanged(event);
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

    // 刷新房间列表
    ref.read(roomListServiceProvider.notifier).refresh(silent: true);
    log.info("房间已关闭，刷新房间列表");
  }

  /// 处理用户加入房间
  void _handleUserJoined(EventMessage event) {
    // 刷新对应房间的成员列表
    ref.read(roomListServiceProvider.notifier).refresh(silent: true);
    log.info("用户加入房间强制刷新成员列表");
  }

  /// 处理用户离开房间
  void _handleUserLeft(EventMessage event) {
    // 刷新对应房间的成员列表
    String? roomId = _extractRoomIdFromEvent(event);
    if (roomId != null) {
      ref
          .read(roomMemberServiceProvider.notifier)
          .syncMembers(roomId, force: true);
      log.info("用户 ${event.operatorId} 离开房间 $roomId，强制刷新成员列表");
    } else {
      log.warning("无法从 userLeft 事件中获取 roomId");
    }
  }

  /// 处理房间创建
  void _handleRoomCreated(EventMessage event) {
    // 刷新房间列表
    ref.read(roomListServiceProvider.notifier).refresh(silent: true);
    log.info("房间创建成功，刷新房间列表");
  }

  /// 处理房间更新
  void _handleRoomUpdated(EventMessage event) {
    // 刷新房间列表
    ref.read(roomListServiceProvider.notifier).refresh(silent: true);
    log.info("房间信息更新，刷新房间列表");
  }

  /// 处理用户被禁言
  void _handleUserMuted(EventMessage event) {
    // 刷新对应房间的成员列表
    String? roomId = _extractRoomIdFromEvent(event);
    if (roomId != null) {
      ref
          .read(roomMemberServiceProvider.notifier)
          .syncMembers(roomId, force: true);
      log.info("用户 ${event.operatorId} 被禁言，强制刷新成员列表");
    } else {
      log.warning("无法从 userMuted 事件中获取 roomId");
    }
  }

  /// 处理用户角色变更
  void _handleUserRoleChanged(EventMessage event) {
    // 刷新对应房间的成员列表
    String? roomId = _extractRoomIdFromEvent(event);
    if (roomId != null) {
      ref
          .read(roomMemberServiceProvider.notifier)
          .syncMembers(roomId, force: true);
      log.info("用户 ${event.operatorId} 角色变更，强制刷新成员列表");
    } else {
      log.warning("无法从 userRoleChanged 事件中获取 roomId");
    }
  }

  /// 从事件中提取房间 ID
  String? _extractRoomIdFromEvent(EventMessage event) {
    // 从 extra 字段中提取 roomId
    return event.extra?['roomId'] as String?;
  }
}
