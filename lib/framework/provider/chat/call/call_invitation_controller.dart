import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:anoxia/framework/codec/v5/ImPacketV5.dart';
import 'package:anoxia/framework/domain/ChatRoomVO.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/protocol/PacketType.dart';
import 'package:anoxia/framework/protocol/message/HighMessage.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:anoxia/framework/provider/chat/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
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

  const CallInvitationState({
    required this.inviteId,
    required this.roomId,
    required this.title,
    required this.createdAt,
    required this.phase,
    this.initialMedia = CallInitialMedia.audio,
    this.callerId,
    this.targetId,
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

    final invite = CallInvitationState(
      inviteId: _newInviteId(roomId),
      roomId: roomId,
      title: room.roomName ?? '',
      targetId: room.roomType == 0 ? room.peerId : null,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      phase: CallInvitationPhase.outgoing,
      initialMedia: initialMedia,
    );
    state = invite;
    _scheduleClear(const Duration(seconds: 30));

    _send(HighMessageType.CALL_INVITE, invite, targetId: invite.targetId);
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

  Future<void> reject(CallInvitationState invite) async {
    _send(HighMessageType.CALL_REJECT, invite, targetId: invite.callerId);
    state = null;
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
