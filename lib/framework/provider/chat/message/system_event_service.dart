import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/call/call_status_provider.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/provider/contact/contact_requests_controller.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:anoxia/framework/provider/ws/ws_state.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/ChatRoomVO.dart';
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

    // 2. 监听 WS 连接状态：断线重连后自动刷新业务数据
    ref.listen(wsControllerProvider, (previous, next) {
      final wasDisconnected = previous?.status != WsStatus.connected;
      final isNowConnected = next.status == WsStatus.connected;

      if (wasDisconnected && isNowConnected) {
        log.info("🔄 WS 重连成功，刷新业务数据补偿断线期间丢失的事件...");
        _onReconnected();
      }
    });

    // 3. 销毁时释放
    ref.onDispose(() {
      log.info("系统事件服务销毁");
      subscription.cancel();
    });
  }

  /// WS 重连成功后的数据补偿
  Future<void> _onReconnected() async {
    // 1. 刷新房间列表（补偿断线期间可能错过的：新房间、房间删除、禁言、未读数等）
    await ref.read(roomListServiceProvider.notifier).refresh(silent: true);

    // 2. 补偿当前房间的消息和成员
    final activeRoomId = ref.read(activeRoomIdProvider);
    if (activeRoomId != null) {
      // 2a. 清除同步标记，让当前房间重新拉取消息（增量合并，不清空已有消息）
      ref.read(chatMessagesProvider.notifier).markNeedResync(activeRoomId);

      // 2b. 触发重新同步：拿刷新后的房间列表中最新的 lastMessage.seq 进行增量拉取
      final rooms = ref.read(roomListServiceProvider).value ?? [];
      ChatRoomVO? activeRoom;
      try {
        activeRoom = rooms.firstWhere((r) => r.roomId == activeRoomId);
      } catch (_) {
        activeRoom = null;
      }
      ref
          .read(chatMessagesProvider.notifier)
          .syncRoomMessages(activeRoomId, activeRoom?.lastMessage?.seq);

      // 2c. 刷新成员列表（补偿断线期间可能错过的：成员变动、角色变更等）
      ref
          .read(roomMemberServiceProvider.notifier)
          .syncMembers(activeRoomId, force: true);

  // 2d. 补偿当前房间的通话状态
      ref.read(callStatusControllerProvider.notifier).refresh(activeRoomId);
    }

    // 3. 刷新通讯录（补偿断线期间的在线状态变化）
    ref.read(contactListServiceProvider.notifier).refresh();

    // 4. 刷新好友申请列表（补偿断线期间可能错过的新申请）
    ref.read(contactRequestsServiceProvider.notifier).refresh(quiet: true);

    log.info("✅ 重连数据补偿完成");
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
      case SystemEventType.roomMuted:
        _handleUserMuted(event);
        break;
      case SystemEventType.roomDissolved:
        _handleRoomDissolved(event);
        break;
      case SystemEventType.userLeft:
        _handleUserLeft(event);
        break;
      case SystemEventType.messageRecall:
        _handleMessageRecall(event);
        break;

      case SystemEventType.roomUpdated:
        _handleRoomUpdated(event);
        break;

      case SystemEventType.userRoleChanged:
        _handleUserRoleChanged(event);
        break;
      case SystemEventType.callStarted:
        _handleCallStarted(event);
        break;
      case SystemEventType.callEnded:
        _handleCallEnded(event);
        break;
      case SystemEventType.contactUpdated:
        ref.read(contactListServiceProvider.notifier).refresh();
        ref.read(contactRequestsServiceProvider.notifier).refresh(quiet: true);
        break;
      case SystemEventType.contactRequest:
        ref.read(contactRequestsServiceProvider.notifier).refresh(quiet: true);
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

  /// 处理房间解散/封禁
  /// 说明：此状态下保留会话与历史消息，仅把底部输入区切成状态标签
  void _handleRoomDissolved(EventMessage event) {
    final String? roomId = _extractRoomIdFromEvent(event);
    final dissolveType = event.extra?['type']?.toString().toLowerCase();

    if (roomId != null) {
      // type=ban 视为封禁(2)，其它视为解散(3)
      final nextStatus = dissolveType == 'ban' ? 2 : 3;
      ref.read(roomListServiceProvider.notifier).updateRoomStatus(roomId, nextStatus);
      log.info("房间 $roomId 已${nextStatus == 2 ? '封禁' : '解散'}，保留历史消息并更新状态");
    }

    // 兜底：静默刷新房间列表
    ref.read(roomListServiceProvider.notifier).refresh(silent: true);
    log.info("房间状态已更新，兜底刷新房间列表");
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
    final String? roomId = _extractRoomIdFromEvent(event);
    if (roomId != null && roomId.isNotEmpty) {
      ref.read(callStatusControllerProvider.notifier).refresh(roomId);
    }

    // 兜底刷新房间列表
    ref.read(roomListServiceProvider.notifier).refresh(silent: true);
    log.info("房间信息更新，刷新房间列表");
  }

  /// 处理通话开始
  void _handleCallStarted(EventMessage event) {
    final String? roomId = _extractRoomIdFromEvent(event);
    if (roomId == null || roomId.isEmpty) return;

    final startTime = (event.extra?['startTime'] as num?)?.toInt();
    ref
        .read(callStatusControllerProvider.notifier)
        .markStarted(roomId, startTime: startTime);
    log.info("房间 $roomId 通话开始");
  }

  /// 处理通话结束
  void _handleCallEnded(EventMessage event) {
    final String? roomId = _extractRoomIdFromEvent(event);
    if (roomId == null || roomId.isEmpty) return;

    ref.read(callStatusControllerProvider.notifier).markEnded(roomId);
    log.info("房间 $roomId 通话结束");
  }

  /// 处理全体禁言/解除禁言
  void _handleUserMuted(EventMessage event) {
    final String? roomId = _extractRoomIdFromEvent(event);
    final dynamic rawIsMute = event.extra?['isMute'];
    final bool isMute = rawIsMute == true ||
        rawIsMute == 1 ||
        rawIsMute?.toString().toLowerCase() == 'true';

    if (roomId == null) {
      log.warning("无法从 userMuted 事件中获取 roomId");
      return;
    }

    // 1. 本地立即更新房间状态（0=正常, 1=禁言）
    final newStatus = isMute ? 1 : 0;
    ref
        .read(roomListServiceProvider.notifier)
        .updateRoomStatus(roomId, newStatus);
    log.info("房间 $roomId ${isMute ? '已禁言' : '已解除禁言'}，本地更新状态");

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
    final raw = event.extra?['roomId'];
    if (raw == null) return null;
    final roomId = raw.toString().trim();
    return roomId.isEmpty ? null : roomId;
  }

  /// 处理消息撤回
  void _handleMessageRecall(EventMessage event) {
    final String? roomId = _extractRoomIdFromEvent(event);
    final String? messageId = event.extra?['messageId'] as String?;

    if (roomId == null || messageId == null) {
      log.warning("无法从 messageRecall 事件中获取 roomId 或 messageId");
      return;
    }

    ref.read(chatMessagesProvider.notifier).removeMessage(messageId, roomId);
  }
}
