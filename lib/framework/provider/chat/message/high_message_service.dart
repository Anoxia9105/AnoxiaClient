import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../logs/talker.dart';
import '../../../protocol/PacketType.dart';
import '../../../protocol/message/HighMessage.dart';
import '../../ws/ws_controller.dart';

part 'high_message_service.g.dart';

@Riverpod(keepAlive: true)
class HighMessageService extends _$HighMessageService {
  final Map<String, Timer> _typingTimers = {};

  @override
  Map<String, Map<HighMessageType, HighMessage>> build() {
    final stream = ref.watch(wsControllerProvider.notifier).messageStream;
    final subscription = stream
        .where((frame) => frame.topic == PacketType.highFrequency)
        .map((frame) => frame.data as HighMessage)
        .listen((msg) => _handleMessage(msg));

    ref.onDispose(() {
      log.info("高优消息服务销毁，清理定时器和订阅");
      for (var t in _typingTimers.values) {
        t.cancel();
      }
      subscription.cancel();
    });

    return {}; // 初始状态
  }

  void _handleMessage(HighMessage msg) {
    final roomId = msg.roomId ?? "system";
    final type = msg.type;
    if (type == null) return;

    // 1. 拦截并处理特定类型的“副作用”逻辑（不需要存在 State 里的操作）
    _processSideEffects(msg);

    // 2. 更新嵌套状态 Map
    final roomMap = Map<HighMessageType, HighMessage>.from(state[roomId] ?? {});
    roomMap[type] = msg;
    state = {...state, roomId: roomMap};

    // 3. 针对不同类型的状态管理逻辑
    switch (type) {
      case HighMessageType.TYPING_STATUS:
        _manageTypingTimer(msg);
        break;

      case HighMessageType.CALL_INVITE:
        // 收到邀请，通常需要配合声音、震动或弹出全屏接听界面
        _handleCallInvite(msg);
        break;

      case HighMessageType.CALL_END:
      case HighMessageType.CALL_CANCEL:
      case HighMessageType.CALL_REJECT:
        // 通话结束类指令：清理该房间的所有通话相关状态
        _clearCallContext(roomId);
        break;

      case HighMessageType.SYSTEM_KICK:
        // 系统踢人：通常直接跳转登录页并断开连接
        _handleSystemKick(msg);
        break;

      case HighMessageType.MSG_REVOKE:
        // 消息撤回：处理完逻辑后，由于它是瞬时指令，建议从状态中移除
        _clearSingleStatus(roomId, HighMessageType.MSG_REVOKE);
        break;

      default:
        // CALL_CANDIDATE, CALL_MEDIA_CHANGE 等通常由 RTC 引擎监听 State 变化
        break;
    }
  }

  void _manageTypingTimer(HighMessage msg) {
    final roomId = msg.roomId ?? "system";
    final timerKey = "${roomId}_${msg.senderId}";

    // 1. 无论收到什么，先取消旧的定时器
    _typingTimers[timerKey]?.cancel();
    _typingTimers.remove(timerKey);

    if (msg.content == "true") {
      log.info("用户 ${msg.senderId} 正在输入...");
      // 2. 只有是 true 时，才开启 3 秒自灭（防止对方程序崩溃没发 false）
      _typingTimers[timerKey] = Timer(const Duration(seconds: 5), () {
        log.info("输入状态超时自动清理");
        _clearSingleStatus(roomId, HighMessageType.TYPING_STATUS);
      });
    } else {
      log.info("用户 ${msg.senderId} 停止输入，立即清理");
      // 3. 如果收到 "false"，立刻清理状态
      _clearSingleStatus(roomId, HighMessageType.TYPING_STATUS);
    }
  }

  void _processSideEffects(HighMessage msg) {
    // 处理撤回逻辑：去操作 ChatMessages Provider
    if (msg.type == HighMessageType.MSG_REVOKE) {
      final targetMsgId = msg.content;
      if (targetMsgId != null) {
        // 假设你之前实现的聊天记录 Provider 叫 chatMessagesProvider
        // ref.read(chatMessagesProvider.notifier).removeMessage(msg.roomId!, targetMsgId);
        log.info("执行消息撤回副作用，ID: $targetMsgId");
      }
    }
  }

  void _handleCallInvite(HighMessage msg) {
    // 这里可以触发震动、铃声等
    log.info("收到来自 ${msg.senderId} 的通话邀请");
  }

  void _handleSystemKick(HighMessage msg) {
    log.warning("被系统强制踢出: ${msg.content}");
    // 逻辑：清除本地 Token -> 跳转 Login 页面
  }

  /// 清理通话上下文：当通话结束/取消时，把房间里所有跟通话有关的状态一次性抹除
  void _clearCallContext(String roomId) {
    if (!state.containsKey(roomId)) return;

    final roomMap = Map<HighMessageType, HighMessage>.from(state[roomId]!);
    // 移除所有通话相关 Key
    const callTypes = [
      HighMessageType.CALL_INVITE,
      HighMessageType.CALL_ACCEPT,
      HighMessageType.CALL_CANDIDATE,
      HighMessageType.CALL_MEDIA_CHANGE,
    ];

    for (var t in callTypes) {
      roomMap.remove(t);
    }

    _updateRoomState(roomId, roomMap);
  }

  /// 通用的单状态清理逻辑（用于非输入状态的自灭）
  void _clearSingleStatus(String roomId, HighMessageType type) {
    if (!state.containsKey(roomId)) return;
    final roomMap = Map<HighMessageType, HighMessage>.from(state[roomId]!);
    roomMap.remove(type);
    _updateRoomState(roomId, roomMap);
  }

  /// 统一的状态更新逻辑，包含自动回收空房间 Map
  void _updateRoomState(
    String roomId,
    Map<HighMessageType, HighMessage> roomMap,
  ) {
    if (roomMap.isEmpty) {
      final newState = Map<String, Map<HighMessageType, HighMessage>>.from(
        state,
      );
      newState.remove(roomId);
      state = newState;
    } else {
      state = {...state, roomId: roomMap};
    }
  }
}
