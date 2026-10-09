import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' show Offset;
import 'call_connection_warmup.dart';

import 'package:anoxia/common/constants/call_window_sizes.dart';
import 'package:anoxia/framework/codec/v6/im_packet_v6.dart';
import 'package:anoxia_protocol/anoxia_protocol.dart' as v6;
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/core/push_manager.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/protocol/packet_type.dart';
import 'package:anoxia/framework/protocol/message/high_message.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/core/call_repository_provider.dart';
import 'package:anoxia/framework/provider/core/toast_service_provider.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:anoxia/framework/provider/chat/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/chat/call/channel.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/theme/theme_controller.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:anoxia/framework/extensions/window_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CallInvitationPhase {
  incoming,
  outgoing,
  acceptedElsewhere,
  rejectedElsewhere,

  /// 对方已拒绝（本端为呼出方，收到对方的 CALL_REJECT）
  rejected,
  canceled,
  busy,
  ended,
}

class CallInvitationState {
  final String inviteId;
  final String roomId;
  final String title;
  final int? callerId;
  final int? targetId;
  final int createdAt;
  final CallInvitationPhase phase;
  final CallInitialMedia initialMedia;
  final bool isGroup;
  final String callerName;
  final String callerAvatar;
  final String roomAvatar;

  /// 是否已最小化到全局悬浮窗（仅本地 UI 状态，不随信令传输）
  final bool minimized;

  /// 悬浮窗坐标（仅本地 UI 状态）
  final Offset position;

  const CallInvitationState({
    required this.inviteId,
    required this.roomId,
    required this.title,
    required this.createdAt,
    required this.phase,
    this.initialMedia = CallInitialMedia.audio,
    this.callerId,
    this.targetId,
    this.isGroup = false,
    this.callerName = '',
    this.callerAvatar = '',
    this.roomAvatar = '',
    this.minimized = false,
    this.position = const Offset(16, 150),
  });

  CallInvitationState copyWith({
    CallInvitationPhase? phase,
    CallInitialMedia? initialMedia,
    bool? minimized,
    Offset? position,
  }) {
    return CallInvitationState(
      inviteId: inviteId,
      roomId: roomId,
      title: title,
      callerId: callerId,
      targetId: targetId,
      createdAt: createdAt,
      phase: phase ?? this.phase,
      initialMedia: initialMedia ?? this.initialMedia,
      isGroup: isGroup,
      callerName: callerName,
      callerAvatar: callerAvatar,
      roomAvatar: roomAvatar,
      minimized: minimized ?? this.minimized,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toNotificationPayload() => <String, dynamic>{
    'inviteId': inviteId,
    'roomId': roomId,
    'title': title,
    'callerId': callerId,
    'targetId': targetId,
    'createdAt': createdAt,
    'initialMedia': initialMedia.value,
    'isGroup': isGroup,
    'callerName': callerName,
    'callerAvatar': callerAvatar,
    'roomAvatar': roomAvatar,
  };

  factory CallInvitationState.fromNotificationPayload(
    Map<String, dynamic> payload,
  ) {
    int? readInt(dynamic value) =>
        value is int ? value : int.tryParse(value?.toString() ?? '');
    final roomId = payload['roomId']?.toString() ?? '';
    return CallInvitationState(
      inviteId:
          payload['inviteId']?.toString() ??
          '${roomId}_${payload['createdAt'] ?? ''}',
      roomId: roomId,
      title: payload['title']?.toString() ?? '',
      callerId: readInt(payload['callerId'] ?? payload['senderId']),
      targetId: readInt(payload['targetId'] ?? payload['receiverId']),
      createdAt:
          readInt(payload['createdAt']) ??
          DateTime.now().millisecondsSinceEpoch,
      phase: CallInvitationPhase.incoming,
      initialMedia: CallInitialMedia.fromValue(payload['initialMedia']),
      isGroup: payload['isGroup'] == true || payload['isGroup'] == 'true',
      callerName: payload['callerName']?.toString() ?? '',
      callerAvatar: payload['callerAvatar']?.toString() ?? '',
      roomAvatar: payload['roomAvatar']?.toString() ?? '',
    );
  }
}

final callInvitationControllerProvider =
    NotifierProvider<CallInvitationController, CallInvitationState?>(
      CallInvitationController.new,
    );

class CallInvitationController extends Notifier<CallInvitationState?> {
  Timer? _clearTimer;

  /// 1:1 呼出振铃超时定时器：30s 未接自动发 CALL_CANCEL 并回到空闲。
  Timer? _ringTimer;

  /// 已发出/已确认结束的 roomId 集合，用于防止 CALL_END 重复发送。
  ///
  /// 桌面端 CALL_END 统一由通话窗口关闭回调（on_call_window_close）发出，
  /// 而远端挂断/拒绝也会关闭窗口，需要借此去重，避免向对端回发多余的 CALL_END。
  final Set<String> _endedRooms = <String>{};

  @override
  CallInvitationState? build() {
    final subscription = ref
        .read(wsControllerProvider.notifier)
        .messageStream
        .where(
          (frame) =>
              frame.topic == PacketType.highFrequency &&
              frame.data is HighMessage,
        )
        .map((frame) => frame.data as HighMessage)
        .listen(_handleHighMessage);

    ref.onDispose(() {
      _clearTimer?.cancel();
      _ringTimer?.cancel();
      subscription.cancel();
    });

    return null;
  }

  /// 发起通话（1:1 或群呼）。
  ///
  /// - 1:1：进入呼出振铃态，**不连接媒体**，等收到 CALL_ACCEPT 后才连；
  ///   30s 无人接听自动发 CALL_CANCEL。
  /// - 群呼：通知式邀请（成员看到横幅可加入），发起人自己直接进入通话。
  Future<void> invite(
    ChatRoomVO room, {
    CallInitialMedia initialMedia = CallInitialMedia.audio,
  }) async {
    final roomId = room.roomId ?? '';
    if (roomId.isEmpty) return;
    ref.read(callConnectionWarmupProvider).start();

    final currentUser = ref.read(authControllerProvider).value;
    final isGroup = room.roomType == 1;
    final invite = CallInvitationState(
      inviteId: _newInviteId(roomId),
      roomId: roomId,
      title: isGroup ? room.roomName ?? '' : currentUser?.nickName ?? '',
      targetId: room.roomType == 0 ? room.peerId : null,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      phase: CallInvitationPhase.outgoing,
      initialMedia: initialMedia,
      isGroup: isGroup,
      callerName: currentUser?.nickName ?? '',
      callerAvatar: currentUser?.avatar ?? '',
      roomAvatar: room.roomAvatar ?? '',
    );
    state = isGroup ? null : invite;
    // 仅 1:1 需要振铃超时自动取消；群呼是加入式，不设取消定时，
    // 且不进入「呼出振铃」态（发起人直接进通话页）。
    if (!isGroup) {
      _scheduleAutoCancel(const Duration(seconds: 30));
    }

    _send(HighMessageType.CALL_INVITE, invite, targetId: invite.targetId);
  }

  /// 群通话中定向提醒尚未入会的成员。
  ///
  /// 群邀请是「通知式」提醒（不进入全屏振铃）：成员收到横幅后可一键加入，
  /// 或稍后在聊天栏看到「加入通话」。这里不写全局邀请状态，
  /// 避免打断发起人自己正在进行中的通话界面。
  Future<void> inviteMembers(
    ChatRoomVO room,
    Iterable<int> userIds, {
    CallInitialMedia initialMedia = CallInitialMedia.audio,
  }) async {
    final roomId = room.roomId ?? '';
    if (roomId.isEmpty) return;
    final currentUser = ref.read(authControllerProvider).value;
    final invite = CallInvitationState(
      inviteId: _newInviteId(roomId),
      roomId: roomId,
      title: room.roomName ?? '',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      phase: CallInvitationPhase.outgoing,
      initialMedia: initialMedia,
      isGroup: true,
      callerName: currentUser?.nickName ?? '',
      callerAvatar: currentUser?.avatar ?? '',
      roomAvatar: room.roomAvatar ?? '',
    );
    for (final userId in userIds.toSet()) {
      _send(HighMessageType.CALL_INVITE, invite, targetId: userId);
    }
  }

  /// 取消呼出（振铃页「挂断」/ 超时自动取消）。
  Future<void> cancelCurrent() async {
    _ringTimer?.cancel();
    final invite = state;
    if (invite == null) return;
    _endedRooms.add(invite.roomId);
    _send(HighMessageType.CALL_CANCEL, invite, targetId: invite.targetId);
    state = null;
    // 桌面端：呼出振铃窗口仍处于振铃态，取消后需关闭；
    // 窗口关闭回调触发 endRoom 时会被 _endedRooms 去重，不会重复发信令。
    if (DeviceUtil.isRealDesktop()) {
      final window = ref.read(callWindowControllerProvider);
      if (window != null) {
        try {
          await window.close();
        } catch (_) {}
      }
    }
  }

  /// 接听：发送 ACCEPT 信令并关闭本端来电提示。
  Future<void> accept(CallInvitationState invite) async {
    _send(HighMessageType.CALL_ACCEPT, invite, targetId: invite.callerId);
    _clearIncomingNotifications();
    state = null;
  }

  /// 接听并进入通话界面。
  ///
  /// [media] 可选：视频来电时「以语音方式接听」传入 audio，
  /// 此时 ACCEPT 载荷与后续媒体都以语音为准。
  Future<void> acceptAndOpen(
    CallInvitationState invite, {
    CallInitialMedia? media,
  }) async {
    final effective = media ?? invite.initialMedia;
    await accept(invite.copyWith(initialMedia: effective));
    await _openCallUi(invite.copyWith(initialMedia: effective));
  }

  /// 群呼通知横幅的「加入」：加入式直连，不发送 ACCEPT 信令。
  Future<void> joinGroupCall(CallInvitationState invite) async {
    _ringTimer?.cancel();
    _clearIncomingNotifications();
    state = null;
    await _openCallUi(invite);
  }

  /// 忽略通知（群呼横幅的「忽略」）：仅本地关闭，不发送任何信令。
  void dismissInvitation() {
    _ringTimer?.cancel();
    state = null;
  }

  /// 最小化邀请页到全局悬浮窗（手机/Web 全屏邀请页）。
  void minimizeInvitation() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(minimized: true);
  }

  /// 点击悬浮窗恢复全屏邀请页。
  void restoreInvitation() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(minimized: false);
  }

  /// 悬浮窗拖拽中实时更新坐标（边界约束与通话悬浮窗一致）。
  void updateInvitationPosition(
    Offset delta,
    double screenWidth,
    double screenHeight,
  ) {
    final current = state;
    if (current == null) return;
    final widgetWidth = CallWindowSizes.audioWidth;
    final widgetHeight = CallWindowSizes.audioHeight;
    double newX = current.position.dx + delta.dx;
    double newY = current.position.dy + delta.dy;
    newX = newX.clamp(
      0.0,
      (screenWidth - widgetWidth).clamp(0.0, double.infinity),
    );
    newY = newY.clamp(
      40.0,
      (screenHeight - widgetHeight - 40.0).clamp(40.0, double.infinity),
    );
    state = current.copyWith(position: Offset(newX, newY));
  }

  /// 悬浮窗手势松开后自动吸边。
  void snapInvitationToEdge(double screenWidth) {
    final current = state;
    if (current == null) return;
    final widgetWidth = CallWindowSizes.audioWidth;
    final padding = CallWindowSizes.edgePadding;
    double targetX;
    if ((current.position.dx + widgetWidth / 2) < screenWidth / 2) {
      targetX = padding;
    } else {
      targetX = screenWidth - widgetWidth - padding;
    }
    state = current.copyWith(position: Offset(targetX, current.position.dy));
  }

  /// 拒绝来电：发送 REJECT 信令，1:1 时由服务端在信令处落一条「对方已拒绝」系统消息。
  Future<void> reject(CallInvitationState invite) async {
    _send(HighMessageType.CALL_REJECT, invite, targetId: invite.callerId);
    _clearIncomingNotifications();
    state = null;
  }

  /// 接听/拒绝/通话结束后清掉系统通知栏里残留的来电推送（仅移动端）。
  void _clearIncomingNotifications() {
    if (!DeviceUtil.isRealMobile()) return;
    unawaited(PushManager.instance.clearNotifications());
  }

  /// 结束通话（挂断 / 桌面关窗）。
  ///
  /// 若仍处于呼出振铃态，则发 CALL_CANCEL（取消呼叫）；
  /// 已接通后调用则发 CALL_END（正常挂断）。
  Future<void> endRoom(String roomId, {String? title}) async {
    if (roomId.isEmpty || _endedRooms.contains(roomId)) return;
    _endedRooms.add(roomId);
    _ringTimer?.cancel();
    final current = state;
    final invite = CallInvitationState(
      inviteId: (current != null && current.roomId == roomId)
          ? current.inviteId
          : _newInviteId(roomId),
      roomId: roomId,
      title: title ?? current?.title ?? '',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      phase: CallInvitationPhase.ended,
      targetId: current?.targetId,
    );
    final wasOutgoing =
        current?.roomId == roomId &&
        current?.phase == CallInvitationPhase.outgoing;
    if (wasOutgoing) {
      _send(HighMessageType.CALL_CANCEL, invite, targetId: invite.targetId);
    } else {
      _send(HighMessageType.CALL_END, invite);
    }
    if (state?.roomId == roomId) state = null;
  }

  /// Restores an invitation delivered through JPush while the IM WebSocket
  /// was unavailable. Expired pushes are deliberately ignored.
  void receiveExternalInvite(Map<String, dynamic> payload) {
    final invite = CallInvitationState.fromNotificationPayload(payload);
    if (invite.roomId.isEmpty) return;
    final age = DateTime.now().millisecondsSinceEpoch - invite.createdAt;
    if (age > const Duration(seconds: 60).inMilliseconds) return;
    if (state?.inviteId == invite.inviteId &&
        state?.phase == CallInvitationPhase.incoming) {
      return;
    }
    _handleIncomingInvite(invite);
  }

  void _handleHighMessage(HighMessage msg) {
    final type = msg.type;
    if (type == null || !_isCallSignal(type)) return;

    final payload = _decodePayload(msg);
    final roomId = msg.roomId ?? payload['roomId']?.toString() ?? '';
    if (roomId.isEmpty) return;

    final currentUserId = ref.read(authControllerProvider).value?.userId;
    final fromSelf = currentUserId != null && msg.senderId == currentUserId;
    final invite = _stateFromMessage(msg, payload, roomId);

    switch (type) {
      case HighMessageType.CALL_INVITE:
        if (fromSelf) return;
        _handleIncomingInvite(invite);
        break;
      case HighMessageType.CALL_ACCEPT:
        _handleRemoteAccept(invite, fromSelf: fromSelf);
        break;
      case HighMessageType.CALL_REJECT:
        _handleTerminalSignal(
          invite,
          fromSelf: fromSelf,
          selfPhase: CallInvitationPhase.rejectedElsewhere,
          remotePhase: CallInvitationPhase.rejected,
        );
        if (!fromSelf) {
          _endedRooms.add(invite.roomId);
          unawaited(_endActiveCall(invite.roomId));
        }
        _clearIncomingNotifications();
        break;
      case HighMessageType.CALL_CANCEL:
        _handleTerminalSignal(
          invite,
          fromSelf: fromSelf,
          selfPhase: CallInvitationPhase.canceled,
          remotePhase: CallInvitationPhase.canceled,
        );
        _clearIncomingNotifications();
        break;
      case HighMessageType.CALL_END:
        _handleTerminalSignal(
          invite,
          fromSelf: fromSelf,
          selfPhase: CallInvitationPhase.ended,
          remotePhase: CallInvitationPhase.ended,
        );
        _endedRooms.add(invite.roomId);
        _clearIncomingNotifications();
        // 通话进行中（非振铃期）对方挂断：提示后再结束会话，避免界面
        // 直接消失而用户不知道原因。
        unawaited(
          _endActiveCall(invite.roomId, showPeerEndedNotice: !fromSelf),
        );
        break;
      case HighMessageType.CALL_BUSY:
        if (!fromSelf && _isSameInvite(state, invite)) {
          if (state?.minimized == true) {
            // 悬浮窗态收到忙线：Toast 提示后直接清除，避免弹回全屏。
            ref
                .read(toastServiceProvider)
                .showNotificationNow('call_peer_busy'.tr());
            state = null;
          } else {
            state = invite.copyWith(phase: CallInvitationPhase.busy);
            _scheduleClear(const Duration(seconds: 2));
          }
        }
        break;
      default:
        break;
    }
  }

  void _handleIncomingInvite(CallInvitationState invite) {
    final mobileSession = ref.read(mobileCallSessionControllerProvider);
    final desktopWindow = ref.read(callWindowControllerProvider);
    final inAnotherCall =
        (mobileSession != null && mobileSession.roomId != invite.roomId) ||
        (desktopWindow != null && state?.roomId != invite.roomId);

    if (inAnotherCall) {
      _send(HighMessageType.CALL_BUSY, invite, targetId: invite.callerId);
      return;
    }

    state = invite.copyWith(phase: CallInvitationPhase.incoming);
    ref.read(callConnectionWarmupProvider).start();
    _scheduleClear(const Duration(seconds: 45));
  }

  /// 对方已接听：结束呼出振铃并开始连接媒体。
  ///
  /// - 移动/Web：启动全局通话会话（拉取 token 后连接 LiveKit）。
  /// - 桌面：通话窗口此时处于「振铃态」，通过 callChannel 通知其开始连接。
  Future<void> _openCallAfterAccept(CallInvitationState invite) async {
    if (DeviceUtil.isRealMobile() || DeviceUtil.isWeb) {
      // 呼出方视角：标题用对方名称（房间名），而非邀请 payload 里的自己昵称。
      final room = ref.read(currentRoomProvider(invite.roomId));
      ref.read(callIsGroupProvider(invite.roomId).notifier).state =
          invite.isGroup;
      ref
          .read(mobileCallSessionControllerProvider.notifier)
          .start(
            roomId: invite.roomId,
            title: room?.roomName ?? invite.title,
            initialMedia: invite.initialMedia,
          );
      return;
    }
    final window = ref.read(callWindowControllerProvider);
    if (window == null) return;
    try {
      final fresh = await ref
          .read(callRepositoryProvider)
          .fetchCallToken(invite.roomId);
      await Channel.callChannel.invokeMethod('on_call_accepted', {
        'token': fresh,
      });
    } catch (e) {
      debugLog('[CallInvitation] 通知通话窗口开始连接失败: $e');
    }
  }

  /// 打开通话界面（移动/Web 启动会话浮层；桌面打开独立通话窗口）。
  Future<void> _openCallUi(CallInvitationState invite) async {
    if (DeviceUtil.isRealMobile() || DeviceUtil.isWeb) {
      ref.read(callIsGroupProvider(invite.roomId).notifier).state =
          invite.isGroup;
      ref
          .read(mobileCallSessionControllerProvider.notifier)
          .start(
            roomId: invite.roomId,
            title: invite.title,
            initialMedia: invite.initialMedia,
          );
      return;
    }

    await ref
        .read(callWindowControllerProvider.notifier)
        .openCallWindow(
          title: invite.title,
          themeIndex: ref.read(themeIndexProvider),
          roomId: invite.roomId,
          initialMedia: invite.initialMedia,
          isGroup: invite.isGroup,
          token: await ref.read(roomTokenProvider(invite.roomId).future),
        );
  }

  Future<void> _endActiveCall(
    String roomId, {
    bool showPeerEndedNotice = false,
  }) async {
    final mobileSession = ref.read(mobileCallSessionControllerProvider);
    if (mobileSession?.roomId == roomId) {
      final token = mobileSession?.token;
      if (showPeerEndedNotice) {
        ref
            .read(toastServiceProvider)
            .showNotificationNow('call_peer_ended'.tr());
      }
      // 先关闭会话，让通话浮层立即退出；再断开 LiveKit 房间释放摄像头/麦克风。
      ref.read(mobileCallSessionControllerProvider.notifier).end();
      if (token != null && token.isNotEmpty) {
        try {
          await ref.read(roomControllerProvider(token).notifier).leave();
        } catch (error) {
          debugLog('[CallInvitation] 远端结束后清理通话资源失败: $error');
        }
      }
      return;
    }
    final desktopWindow = ref.read(callWindowControllerProvider);
    if (desktopWindow != null) {
      // 防跨房/迟到信号误关：窗口已绑定其他房间时，不接受针对别的房间的
      // CALL_END/REJECT 关闭当前活跃窗口（CALL_END 按用户维度投递到全部连接）。
      final activeRoom = ref
          .read(callWindowControllerProvider.notifier)
          .activeRoomId;
      if (activeRoom != null && activeRoom != roomId) {
        debugLog(
          '[CallInvitation] ignore terminal signal for non-active room: $roomId (active=$activeRoom)',
        );
        return;
      }
      try {
        await desktopWindow.close();
      } catch (error) {
        debugLog('[CallInvitation] failed to close rejected call: $error');
      }
    }
  }

  void _handleRemoteAccept(
    CallInvitationState invite, {
    required bool fromSelf,
  }) {
    if (!_isSameInvite(state, invite)) return;

    if (fromSelf) {
      // 我的其他设备已接听：本端停止振铃并提示。
      if (state?.minimized == true) {
        // 悬浮窗态：Toast 提示后直接清除，避免弹回全屏。
        ref
            .read(toastServiceProvider)
            .showNotificationNow('call_answered_elsewhere'.tr());
        state = null;
      } else {
        state = invite.copyWith(phase: CallInvitationPhase.acceptedElsewhere);
        _scheduleClear(const Duration(seconds: 2));
      }
      _clearIncomingNotifications();
      return;
    }

    // 对方接听：结束呼出振铃，开始连接媒体（振铃期未连 LiveKit）。
    final wasOutgoing = state?.phase == CallInvitationPhase.outgoing;
    state = null;
    if (wasOutgoing) {
      unawaited(_openCallAfterAccept(invite));
    }
  }

  /// 终端信令（拒绝/取消/结束）处理。
  ///
  /// - [fromSelf]：信号来自我自己的其它设备（多端收敛），展示
  ///   「已在其他设备接听/拒绝」等提示后短暂停留。
  /// - 否则：信号来自对端，展示「对方已拒绝 / 通话邀请已取消 / 通话已结束」。
  void _handleTerminalSignal(
    CallInvitationState invite, {
    required bool fromSelf,
    required CallInvitationPhase selfPhase,
    required CallInvitationPhase remotePhase,
  }) {
    if (!_isSameInvite(state, invite)) return;
    if (state?.minimized == true) {
      // 悬浮窗态收到终端信号：Toast 提示后直接清除，避免弹回全屏通知卡。
      final effective = fromSelf ? selfPhase : remotePhase;
      final text = switch (effective) {
        CallInvitationPhase.rejected => 'call_rejected_by_peer',
        CallInvitationPhase.rejectedElsewhere => 'call_rejected_elsewhere',
        CallInvitationPhase.canceled => 'call_invitation_cancelled',
        _ => 'call_ended',
      };
      ref.read(toastServiceProvider).showNotificationNow(text.tr());
      state = null;
      return;
    }
    state = invite.copyWith(phase: fromSelf ? selfPhase : remotePhase);
    _scheduleClear(const Duration(seconds: 2));
  }

  /// 是否为同一通呼叫（roomId + inviteId 双重匹配）。
  ///
  /// 多端收敛依赖 inviteId：一端接听/拒绝后，同一邀请的其它设备
  /// 才会收到终端信号并停止振铃；同房间的第二次呼叫互不干扰。
  bool _isSameInvite(
    CallInvitationState? current,
    CallInvitationState incoming,
  ) {
    if (current == null) return false;
    if (current.roomId != incoming.roomId) return false;
    return current.inviteId == incoming.inviteId;
  }

  void _send(
    HighMessageType type,
    CallInvitationState invite, {
    int? targetId,
  }) {
    final callType = switch (type) {
      HighMessageType.CALL_INVITE => v6.CallSignalType.CALL_SIGNAL_TYPE_INVITE,
      HighMessageType.CALL_CANCEL => v6.CallSignalType.CALL_SIGNAL_TYPE_CANCEL,
      HighMessageType.CALL_ACCEPT => v6.CallSignalType.CALL_SIGNAL_TYPE_ACCEPT,
      HighMessageType.CALL_REJECT => v6.CallSignalType.CALL_SIGNAL_TYPE_REJECT,
      HighMessageType.CALL_END => v6.CallSignalType.CALL_SIGNAL_TYPE_HANGUP,
      HighMessageType.CALL_BUSY => v6.CallSignalType.CALL_SIGNAL_TYPE_BUSY,
      HighMessageType.CALL_CANDIDATE => v6.CallSignalType.CALL_SIGNAL_TYPE_ICE,
      HighMessageType.CALL_MEDIA_CHANGE =>
        v6.CallSignalType.CALL_SIGNAL_TYPE_MEDIA_CHANGE,
      _ => v6.CallSignalType.CALL_SIGNAL_TYPE_UNSPECIFIED,
    };
    final content = jsonEncode({
      'inviteId': invite.inviteId,
      'roomId': invite.roomId,
      'title': invite.title,
      'createdAt': invite.createdAt,
      'initialMedia': invite.initialMedia.value,
      'isGroup': invite.isGroup,
      'callerName': invite.callerName,
      'callerAvatar': invite.callerAvatar,
      'roomAvatar': invite.roomAvatar,
    });
    ref
        .read(wsControllerProvider.notifier)
        .sendMessage(
          ImPacketV6.encodeCallSignalFrame(
            roomId: invite.roomId,
            targetUserId: targetId,
            type: callType,
            content: content,
          ),
        );
  }

  CallInvitationState _stateFromMessage(
    HighMessage msg,
    Map<String, dynamic> payload,
    String roomId,
  ) {
    return CallInvitationState(
      inviteId: payload['inviteId']?.toString() ?? _newInviteId(roomId),
      roomId: roomId,
      title: payload['title']?.toString() ?? '',
      callerId: msg.senderId,
      targetId: msg.targetId,
      createdAt:
          int.tryParse(payload['createdAt']?.toString() ?? '') ??
          msg.timestamp ??
          DateTime.now().millisecondsSinceEpoch,
      phase: CallInvitationPhase.incoming,
      initialMedia: CallInitialMedia.fromValue(payload['initialMedia']),
      isGroup: payload['isGroup'] == true || payload['isGroup'] == 'true',
      callerName: payload['callerName']?.toString() ?? '',
      callerAvatar: payload['callerAvatar']?.toString() ?? '',
      roomAvatar: payload['roomAvatar']?.toString() ?? '',
    );
  }

  Map<String, dynamic> _decodePayload(HighMessage msg) {
    final content = msg.content;
    if (content == null || content.isEmpty) return const {};
    try {
      final decoded = jsonDecode(content);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (e) {
      debugLog('[CallInvitation] invalid high message payload: $content');
      return const {};
    }
  }

  bool _isCallSignal(HighMessageType type) {
    return switch (type) {
      HighMessageType.CALL_INVITE ||
      HighMessageType.CALL_CANCEL ||
      HighMessageType.CALL_ACCEPT ||
      HighMessageType.CALL_REJECT ||
      HighMessageType.CALL_END ||
      HighMessageType.CALL_BUSY => true,
      _ => false,
    };
  }

  /// 呼出振铃超时自动取消（1:1，30s 未接听）。
  void _scheduleAutoCancel(Duration delay) {
    _ringTimer?.cancel();
    _ringTimer = Timer(delay, () {
      final current = state;
      if (current?.phase == CallInvitationPhase.outgoing) {
        // 提示「对方未接听」后自动取消
        ref
            .read(toastServiceProvider)
            .showNotificationNow('call_no_answer'.tr());
        unawaited(cancelCurrent());
      }
    });
  }

  String _newInviteId(String roomId) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final suffix = Random().nextInt(1 << 32).toRadixString(16);
    return '${roomId}_${now}_$suffix';
  }

  void _scheduleClear(Duration delay) {
    _clearTimer?.cancel();
    _clearTimer = Timer(delay, () {
      state = null;
    });
  }
}
