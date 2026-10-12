// 通话窗口控制器
//
// 管理桌面端通话独立窗口的创建、显示、设置同步和成员邀请。
// 基于 Riverpod 的 KeepAlive Provider，通过多窗口框架实现子窗口通信。
import 'dart:convert';
import 'dart:async';

import 'package:anoxia/platform/shims/desktop_multi_window_shim.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:anoxia/framework/codec/v6/im_packet_v6.dart';
import 'package:anoxia_protocol/anoxia_protocol.dart' as v6;
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/auth/token_provider.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';

import 'package:anoxia/framework/logs/debug_log.dart';
import 'channel.dart';
import 'call_initial_media.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';

part 'call_window_controller.g.dart';

/// 通话窗口控制器
///
/// 负责桌面端通话窗口的创建、管理、设置同步和通话成员邀请。
/// 通过 [WindowController] 实现多窗口通信。
@Riverpod(keepAlive: true)
class CallWindowController extends _$CallWindowController {
  /// 当前通话窗口绑定的房间 ID，用于窗口关闭时处理本端退出（私聊补发 CALL_END）。
  String? _activeRoomId;
  String? _windowSession;
  bool _windowReady = false;
  Map<String, Object>? _pendingAcceptance;
  late Future<void> _channelReady;

  /// 当前通话窗口绑定的房间 ID（只读，供外部做「防跨房误关」比对；可能为 null）。
  String? get activeRoomId => _activeRoomId;
  String? get activeSession => _windowSession;

  @override
  WindowController? build() {
    _channelReady = Future<void>(() async {
      await Channel.callChannel.setMethodCallHandler((call) async {
        if (call.method == Channel.callWindowAuthMethod) {
          final payload = Map<String, dynamic>.from(call.arguments as Map);
          // 仅当前通话窗口能读取登录态，迟到的旧窗口或其他房间一律拒绝。
          if (_activeRoomId == null ||
              _windowSession == null ||
              payload['roomId'] != _activeRoomId ||
              payload['session'] != _windowSession) {
            return null;
          }
          return ref.read(tokenCacheProvider);
        }
        if (call.method == Channel.callWindowReadyMethod) {
          final payload = Map<String, dynamic>.from(call.arguments as Map);
          if (payload['roomId'] != _activeRoomId ||
              payload['session'] != _windowSession) {
            return null;
          }
          _windowReady = true;
          return _pendingAcceptance;
        }
        if (call.method == Channel.callWindowEndingMethod) {
          _endActiveRoom();
        } else if (call.method == Channel.callWindowCloseMethod) {
          // 兼容未发送 ending 事件的旧子窗口，同时由 _endedRooms 保证幂等。
          _endActiveRoom();
          _activeRoomId = null;
          _windowSession = null;
          _windowReady = false;
          _pendingAcceptance = null;
          state = null;
        } else if (call.method == 'invite_call_members') {
          _sendMemberInvites(Map<String, dynamic>.from(call.arguments as Map));
        }
        return null;
      });
    });
    return null;
  }

  void _endActiveRoom() {
    final roomId = _activeRoomId;
    if (roomId == null || roomId.isEmpty) return;
    // ending 和 close 都可能到达；邀请控制器通过 _endedRooms 去重。
    ref.read(callInvitationControllerProvider.notifier).endRoom(roomId);
  }

  void _sendMemberInvites(Map<String, dynamic> payload) {
    final roomId = payload['roomId']?.toString() ?? '';
    final userIds = (payload['userIds'] as List? ?? const [])
        .map((id) => int.tryParse(id.toString()))
        .whereType<int>()
        .toSet();
    if (roomId.isEmpty || userIds.isEmpty || roomId != _activeRoomId) return;
    final room = ref.read(currentRoomProvider(roomId));
    final user = ref.read(authControllerProvider).value;
    final content = jsonEncode({
      'inviteId': '${roomId}_${DateTime.now().microsecondsSinceEpoch}',
      'roomId': roomId,
      'title': room?.roomName ?? payload['title']?.toString() ?? '',
      'roomAvatar': room?.roomAvatar ?? '',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'initialMedia': payload['initialMedia']?.toString() ?? 'audio',
      'isGroup': true,
      'callerName': user?.nickName ?? '',
      'callerAvatar': user?.avatar ?? '',
    });
    for (final userId in userIds) {
      ref
          .read(wsControllerProvider.notifier)
          .sendMessage(
            ImPacketV6.encodeCallSignalFrame(
              roomId: roomId,
              targetUserId: userId,
              type: v6.CallSignalType.CALL_SIGNAL_TYPE_INVITE,
              content: content,
            ),
          );
    }
  }

  /// 打开通话窗口
  ///
  /// 若窗口已存在则显示并同步设置，否则创建新窗口。
  /// [themeIndex] 主题索引；[title] 窗口标题；[roomId] 房间 ID；
  /// [initialMedia] 初始媒体类型；[isGroup] 是否为群组通话；[token] 可选认证令牌；
  /// [join] 是否为「加入式直连」（群呼发起/加入进行中通话）：
  /// 为 true 时窗口即使没有 token 也会自行拉取并连接；
  /// 为 false（1:1 呼出）时窗口进入振铃态，等待主窗口下发 `on_call_accepted`。
  Future<void> openCallWindow({
    required int themeIndex,
    required String title,
    required String roomId,
    String avatarUrl = '',
    CallInitialMedia initialMedia = CallInitialMedia.audio,
    bool isGroup = false,
    String? token,
    bool join = false,
  }) async {
    if (state != null) {
      await state!.show();
      await updateSettings(themeIndex: themeIndex);
      return;
    }

    await _channelReady;
    _activeRoomId = roomId;
    _windowSession = '${roomId}_${DateTime.now().microsecondsSinceEpoch}';
    _windowReady = false;
    _pendingAcceptance = null;
    ref.read(callInitialMediaProvider(roomId).notifier).state = initialMedia;
    ref.read(callIsGroupProvider(roomId).notifier).state = isGroup;
    final controller = await WindowController.create(
      WindowConfiguration(
        hiddenAtLaunch: true,
        arguments: jsonEncode({
          'themeIndex': themeIndex,
          'title': title,
          'avatarUrl': avatarUrl,
          'roomId': roomId,
          'session': _windowSession,
          'initialMedia': initialMedia.value,
          'isGroup': isGroup,
          'join': join,
          if (token != null && token.isNotEmpty) 'token': token,
        }),
      ),
    );

    state = controller;
    controller.show();
  }

  /// 主窗口保留接听结果，子窗口尚未就绪时通过 ready 握手领取。
  Future<void> connectAcceptedCall({
    required String roomId,
    String token = '',
    required CallInitialMedia initialMedia,
  }) async {
    if (_activeRoomId != roomId) return;
    final payload = <String, Object>{
      'roomId': roomId,
      'session': _windowSession!,
      if (token.isNotEmpty) 'token': token,
      'initialMedia': initialMedia.value,
    };
    _pendingAcceptance = payload;
    if (!_windowReady) return;
    try {
      await Channel.callChannel.invokeMethod(
        Channel.callAcceptedMethod,
        payload,
      );
    } catch (e, st) {
      debugLog('接听状态等待通话窗口领取', e, st);
    }
  }

  /// 更新通话窗口设置
  ///
  /// 同步主题索引和语言设置到通话子窗口。若子窗口引擎尚未就绪则忽略本次更新。
  Future<void> updateSettings({int? themeIndex, String? localeCode}) async {
    final payload = <String, Object>{};
    if (themeIndex != null) payload['themeIndex'] = themeIndex;
    if (localeCode != null) payload['locale'] = localeCode;
    if (payload.isEmpty) return;

    // The call page listens on Channel.callChannel. WindowController has its
    // own channel for window lifecycle methods and cannot receive this method.
    if (state == null) return;

    try {
      await Channel.callChannel.invokeMethod(
        Channel.callChannelMethod,
        payload,
      );
    } catch (e, st) {
      // The child engine may still be registering its handler, or may have
      // closed between the state check and this invocation.
      debugLog('Call窗口设置同步失败，已忽略本次更新', e, st);
    }
  }
}
