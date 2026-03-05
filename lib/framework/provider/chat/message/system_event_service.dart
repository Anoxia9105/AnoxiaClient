import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
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
      case SystemEventType.roomCreated:
      case SystemEventType.roomCreatedGroup:
        _handleRoomCreated(event);
        break;
      case SystemEventType.userJoined:
        _handleUserJoined(event);
        break;
      case SystemEventType.userKicked:
        _handleUserKicked(event);
        break;
      case SystemEventType.userMuted:
        _handleUserMuted(event);
        break;
      case SystemEventType.roomClosed:
        _handleRoomClosed(event);
        break;

      case SystemEventType.userLeft:
        _handleUserLeft(event);
        break;

      case SystemEventType.roomUpdated:
        _handleRoomUpdated(event);
        break;

      case SystemEventType.userRoleChanged:
        _handleUserRoleChanged(event);
        break;
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
    final String? roomId = _extractRoomIdFromEvent(event);
    final int? targetId = event.extra?['targetId'];
    final currentUser = ref.read(authControllerProvider).value;

    if (roomId == null) {
      log.warning("无法从 userKicked 事件中获取 roomId");
      return;
    }

    // 判断是否是自己被踢
    if (targetId == currentUser?.userId) {
      log.warning("你已被踢出房间 $roomId");

      // 1. 本地移除该房间
      ref.read(roomListServiceProvider.notifier).removeRoomLocally(roomId);

      // 2. 如果当前正在该房间，清空选中状态
      final activeId = ref.read(activeRoomIdProvider);
      if (activeId == roomId) {
        ref.read(activeRoomIdProvider.notifier).setActive(null);
      }

      // 3. 清理该房间的消息和成员缓存
      ref.read(chatMessagesProvider.notifier).clearRoom(roomId);

      // 4. 兜底：静默刷新房间列表确保与服务端同步
      ref.read(roomListServiceProvider.notifier).refresh(silent: true);
    } else {
      // 别人被踢：刷新该房间的成员列表
      ref
          .read(roomMemberServiceProvider.notifier)
          .syncMembers(roomId, force: true);
      log.info("用户 $targetId 被踢出房间 $roomId，刷新成员列表");
    }
  }

  /// 处理房间注销/解散
  void _handleRoomClosed(EventMessage event) {
    final String? roomId = _extractRoomIdFromEvent(event);

    if (roomId != null) {
      // 1. 本地移除该房间
      ref.read(roomListServiceProvider.notifier).removeRoomLocally(roomId);

      // 2. 如果当前正在该房间，清空选中状态
      final activeId = ref.read(activeRoomIdProvider);
      if (activeId == roomId) {
        ref.read(activeRoomIdProvider.notifier).setActive(null);
      }

      // 3. 清理该房间的消息缓存
      ref.read(chatMessagesProvider.notifier).clearRoom(roomId);

      log.info("房间 $roomId 已关闭，本地移除");
    }

    // 4. 兜底：静默刷新房间列表
    ref.read(roomListServiceProvider.notifier).refresh(silent: true);
    log.info("房间已关闭，兜底刷新房间列表");
  }

  /// 处理用户加入房间
  void _handleUserJoined(EventMessage event) {
    final String? roomId = _extractRoomIdFromEvent(event);

    if (roomId != null) {
      // 1. 先刷新成员列表（响应更快）
      ref
          .read(roomMemberServiceProvider.notifier)
          .syncMembers(roomId, force: true);
      log.info("用户 ${event.operatorId} 加入房间 $roomId，刷新成员列表");
    }

    // 2. 兜底刷新房间列表
    ref.read(roomListServiceProvider.notifier).refresh(silent: true);
  }

  /// 处理用户离开房间
  void _handleUserLeft(EventMessage event) {
    final String? roomId = _extractRoomIdFromEvent(event);
    if (roomId != null) {
      ref
          .read(roomMemberServiceProvider.notifier)
          .syncMembers(roomId, force: true);
      log.info("用户 ${event.operatorId} 离开房间 $roomId，强制刷新成员列表");
    } else {
      log.warning("无法从 userLeft 事件中获取 roomId");
    }
  }

  /// 处理房间创建（私聊/群聊被邀请加入）
  /// 注意：此事件只通过 system_event_service 触发一次 refresh
  /// room_message_service 中收到的 topic=0 系统消息不再触发额外的 refresh
  void _handleRoomCreated(EventMessage event) {
    // 直接刷新房间列表（只调用一次）
    ref.read(roomListServiceProvider.notifier).refresh(silent: true);
    log.info("房间创建成功，刷新房间列表");
  }

  /// 处理房间信息更新
  void _handleRoomUpdated(EventMessage event) {
    // 兜底刷新房间列表
    ref.read(roomListServiceProvider.notifier).refresh(silent: true);
    log.info("房间信息更新，刷新房间列表");
  }

  /// 处理全体禁言/解除禁言
  void _handleUserMuted(EventMessage event) {
    final String? roomId = _extractRoomIdFromEvent(event);
    final bool? isMute = event.extra?['isMute'];

    if (roomId == null) {
      log.warning("无法从 userMuted 事件中获取 roomId");
      return;
    }

    // 1. 本地立即更新房间状态（0=正常, 1=禁言）
    final newStatus = (isMute == true) ? 1 : 0;
    ref.read(roomListServiceProvider.notifier).updateRoomStatus(roomId, newStatus);
    log.info("房间 $roomId ${isMute == true ? '已禁言' : '已解除禁言'}，本地更新状态");

    // 2. 兜底：静默刷新确保与服务端同步
    ref.read(roomListServiceProvider.notifier).refresh(silent: true);
  }

  /// 处理用户角色变更
  void _handleUserRoleChanged(EventMessage event) {
    final String? roomId = _extractRoomIdFromEvent(event);
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
