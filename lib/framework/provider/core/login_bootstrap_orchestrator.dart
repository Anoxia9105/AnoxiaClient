import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/ChatRoomVO.dart';
import '../../logs/talker.dart';
import '../auth/auth_controller.dart';
import '../chat/message/room_message_service.dart';
import '../chat/message/system_event_service.dart';
import '../chat/room/room_list_service.dart';
import '../chat/room/room_lookup_helper.dart';
import '../chat/room/room_member_service.dart';
import '../setting/update_check_provider.dart';

final loginBootstrapOrchestratorProvider = Provider<LoginBootstrapOrchestrator>(
  (ref) => LoginBootstrapOrchestrator(ref),
);

/// 登录后初始化编排器
///
/// 固定初始化顺序：
/// 1. 拉取房间列表
/// 2. 预热当前房间（消息 -> 成员）
/// 3. 启动常驻监听（WS消息/系统事件/版本检查）
class LoginBootstrapOrchestrator {
  LoginBootstrapOrchestrator(this._ref);

  final Ref _ref;
  Future<void>? _inflight;

  Future<void> run({required String reason}) async {
    final existing = _inflight;
    if (existing != null) {
      log.info('[Bootstrap] 复用正在执行的初始化链路, reason=$reason');
      return existing;
    }

    final task = _runInternal(reason: reason);
    _inflight = task;
    try {
      await task;
    } finally {
      if (identical(_inflight, task)) {
        _inflight = null;
      }
    }
  }

  Future<void> _runInternal({required String reason}) async {
    final user = _ref.read(authControllerProvider).value;
    if (user == null) {
      log.info('[Bootstrap] 当前未登录，跳过初始化链路, reason=$reason');
      return;
    }

    log.info('[Bootstrap] 开始执行初始化链路, reason=$reason');

    // Step 1: 先拉房间列表，作为后续房间预热的前置依赖。
    final rooms = await _safeReadRoomList();

    // Step 2: 预热当前房间，确保刚进入会话时成员/消息不闪空。
    await _warmUpActiveRoomContext(rooms);

    // Step 3: 再挂常驻监听，避免监听先到但基础数据尚未就绪。
    _ref.read(chatMessagesProvider);
    _ref.read(systemEventServiceProvider);
    _ref.read(appUpdateCheckerProvider);

    log.info('[Bootstrap] 初始化链路完成, reason=$reason');
  }

  Future<List<ChatRoomVO>> _safeReadRoomList() async {
    try {
      return await _ref.read(roomListServiceProvider.future);
    } catch (e, st) {
      log.error('[Bootstrap] 房间列表预加载失败，降级为空列表', e, st);
      return const <ChatRoomVO>[];
    }
  }

  Future<void> _warmUpActiveRoomContext(List<ChatRoomVO> rooms) async {
    if (rooms.isEmpty) return;

    final activeRoomId = _ref.read(activeRoomIdProvider);
    final room = activeRoomId != null
        ? RoomLookupHelper.findByRoomId(rooms, activeRoomId)
        : rooms.first;

    final targetRoomId = room?.roomId;
    if (targetRoomId == null || targetRoomId.isEmpty) return;

    try {
      await _ref
          .read(chatMessagesProvider.notifier)
          .syncRoomMessages(targetRoomId, room?.lastMessage?.seq);
    } catch (e, st) {
      log.error('[Bootstrap] 房间消息预热失败，继续后续流程', e, st);
    }

    try {
      await _ref.read(roomMemberServiceProvider.notifier).syncMembers(
        targetRoomId,
      );
    } catch (e, st) {
      log.error('[Bootstrap] 房间成员预热失败，继续后续流程', e, st);
    }
  }
}
