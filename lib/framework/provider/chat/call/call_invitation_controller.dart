import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:anoxia/framework/codec/v5/ImPacketV5.dart';
import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/framework/domain/ChatRoomVO.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/protocol/packet_type.dart';
import 'package:anoxia/framework/protocol/message/high_message.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:anoxia/framework/provider/chat/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:anoxia/framework/provider/theme/theme_controller.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:anoxia/framework/extensions/window_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CallInvitationPhase {
  incoming,
  outgoing,
  acceptedElsewhere,
  rejectedElsewhere,
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
  });

  CallInvitationState copyWith({
    CallInvitationPhase? phase,
    CallInitialMedia? initialMedia,
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

  @override
  CallInvitationState? build() {
    final subscription = ref
        .read(wsControllerProvider.notifier)
        .messageStream
        .where((frame) => frame.topic == PacketType.highFrequency)
        .map((frame) => frame.data as HighMessage)
        .listen(_handleHighMessage);

    ref.onDispose(() {
      _clearTimer?.cancel();
      subscription.cancel();
    });

    return null;
  }

  Future<void> invite(
    ChatRoomVO room, {
    CallInitialMedia initialMedia = CallInitialMedia.audio,
  }) async {
    final roomId = room.roomId ?? '';
    if (roomId.isEmpty) return;

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
    state = invite;
    _scheduleClear(const Duration(seconds: 30));

    _send(HighMessageType.CALL_INVITE, invite, targetId: invite.targetId);
  }

  /// 在群通话中定向提醒尚未入会的成员；群邀请不会触发来电弹窗。
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

  Future<void> cancelCurrent() async {
    final invite = state;
    if (invite == null) return;
    _send(HighMessageType.CALL_CANCEL, invite, targetId: invite.targetId);
    state = null;
  }

  Future<void> accept(CallInvitationState invite) async {
    _send(HighMessageType.CALL_ACCEPT, invite, targetId: invite.callerId);
    state = null;
  }

  Future<void> acceptAndOpen(CallInvitationState invite) async {
    await accept(invite);
    if (DeviceUtil.isRealMobile()) {
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

  Future<void> reject(CallInvitationState invite) async {
    _send(HighMessageType.CALL_REJECT, invite, targetId: invite.callerId);
    unawaited(_persistRejection(invite.roomId));
    state = null;
  }

  Future<void> _persistRejection(String roomId) async {
    try {
      await DioClient().post(API.callReject, data: {'roomId': roomId});
    } catch (error) {
      log.warning('[CallInvitation] failed to persist rejection: $error');
    }
  }

  Future<void> endRoom(String roomId, {String? title}) async {
    if (roomId.isEmpty) return;
    final invite = CallInvitationState(
      inviteId: state?.roomId == roomId
          ? state!.inviteId
          : _newInviteId(roomId),
      roomId: roomId,
      title: title ?? state?.title ?? '',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      phase: CallInvitationPhase.ended,
    );
    _send(HighMessageType.CALL_END, invite);
    if (state?.roomId == roomId) state = null;
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
          fromSelf,
          CallInvitationPhase.rejectedElsewhere,
        );
        if (!fromSelf) unawaited(_endActiveCall(invite.roomId));
        break;
      case HighMessageType.CALL_CANCEL:
        _handleTerminalSignal(invite, fromSelf, CallInvitationPhase.canceled);
        break;
      case HighMessageType.CALL_END:
        _handleTerminalSignal(invite, fromSelf, CallInvitationPhase.ended);
        ref.read(mobileCallSessionControllerProvider.notifier).end();
        break;
      case HighMessageType.CALL_BUSY:
        if (!fromSelf && state?.roomId == roomId) {
          state = invite.copyWith(phase: CallInvitationPhase.busy);
          _scheduleClear(const Duration(seconds: 2));
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
    _scheduleClear(const Duration(seconds: 45));
  }

  Future<void> _endActiveCall(String roomId) async {
    final mobileSession = ref.read(mobileCallSessionControllerProvider);
    if (mobileSession?.roomId == roomId) {
      ref.read(mobileCallSessionControllerProvider.notifier).end();
    }
    final desktopWindow = ref.read(callWindowControllerProvider);
    if (desktopWindow != null) {
      try {
        await desktopWindow.close();
      } catch (error) {
        log.warning('[CallInvitation] failed to close rejected call: $error');
      }
    }
  }

  void _handleRemoteAccept(
    CallInvitationState invite, {
    required bool fromSelf,
  }) {
    if (fromSelf && state?.roomId == invite.roomId) {
      state = invite.copyWith(phase: CallInvitationPhase.acceptedElsewhere);
      _scheduleClear(const Duration(seconds: 2));
      return;
    }

    if (state?.roomId == invite.roomId) {
      state = null;
    }
  }

  void _handleTerminalSignal(
    CallInvitationState invite,
    bool fromSelf,
    CallInvitationPhase phase,
  ) {
    if (state?.roomId != invite.roomId) return;
    state = fromSelf ? invite.copyWith(phase: phase) : null;
    if (fromSelf) _scheduleClear(const Duration(seconds: 2));
  }

  void _send(
    HighMessageType type,
    CallInvitationState invite, {
    int? targetId,
  }) {
    final msg = HighMessage(
      type: type,
      roomId: invite.roomId,
      targetId: targetId,
      content: jsonEncode({
        'inviteId': invite.inviteId,
        'roomId': invite.roomId,
        'title': invite.title,
        'createdAt': invite.createdAt,
        'initialMedia': invite.initialMedia.value,
        'isGroup': invite.isGroup,
        'callerName': invite.callerName,
        'callerAvatar': invite.callerAvatar,
        'roomAvatar': invite.roomAvatar,
      }),
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    final bytes = ImPacketV5.encodeHighMessageFrame(msg);
    ref.read(wsControllerProvider.notifier).sendMessage(bytes);
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
      log.warning('[CallInvitation] invalid high message payload: $content');
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
