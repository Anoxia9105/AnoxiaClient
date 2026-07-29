import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:anoxia/framework/codec/v5/ImPacketV5.dart';
import 'package:anoxia/framework/protocol/message/high_message.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';

import '../../../logs/talker.dart';
import 'channel.dart';
import 'call_initial_media.dart';

part 'call_window_controller.g.dart';

@Riverpod(keepAlive: true)
class CallWindowController extends _$CallWindowController {
  @override
  WindowController? build() {
    Channel.callChannel.setMethodCallHandler((call) async {
      if (call.method == 'on_call_window_close') {
        log.info('收到窗口关闭');
        state = null;
      } else if (call.method == 'invite_call_members') {
        _sendMemberInvites(Map<String, dynamic>.from(call.arguments as Map));
      }
      return null;
    });
    return null;
  }

  void _sendMemberInvites(Map<String, dynamic> payload) {
    final roomId = payload['roomId']?.toString() ?? '';
    final userIds = (payload['userIds'] as List? ?? const [])
        .map((id) => int.tryParse(id.toString()))
        .whereType<int>()
        .toSet();
    if (roomId.isEmpty || userIds.isEmpty) return;
    final user = ref.read(authControllerProvider).value;
    final content = jsonEncode({
      'inviteId': '${roomId}_${DateTime.now().microsecondsSinceEpoch}',
      'roomId': roomId,
      'title': payload['title']?.toString() ?? '',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'initialMedia': payload['initialMedia']?.toString() ?? 'audio',
      'isGroup': true,
      'callerName': user?.nickName ?? '',
      'callerAvatar': user?.avatar ?? '',
    });
    for (final userId in userIds) {
      final message = HighMessage(
        type: HighMessageType.CALL_INVITE,
        roomId: roomId,
        targetId: userId,
        content: content,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      ref
          .read(wsControllerProvider.notifier)
          .sendMessage(ImPacketV5.encodeHighMessageFrame(message));
    }
  }

  Future<void> openCallWindow({
    required int themeIndex,
    required String title,
    required String roomId,
    CallInitialMedia initialMedia = CallInitialMedia.audio,
    bool isGroup = false,
    String? token,
  }) async {
    if (state != null) {
      await state!.show();
      await updateSettings(themeIndex: themeIndex);
      return;
    }

    ref.read(callInitialMediaProvider(roomId).notifier).state = initialMedia;
    ref.read(callIsGroupProvider(roomId).notifier).state = isGroup;
    final controller = await WindowController.create(
      WindowConfiguration(
        hiddenAtLaunch: true,
        arguments: jsonEncode({
          'themeIndex': themeIndex,
          'title': title,
          'roomId': roomId,
          'initialMedia': initialMedia.value,
          'isGroup': isGroup,
          if (token != null && token.isNotEmpty) 'token': token,
        }),
      ),
    );

    state = controller;
    controller.show();
  }

  Future<void> updateSettings({int? themeIndex, String? localeCode}) async {
    final payload = <String, Object>{};
    if (themeIndex != null) payload['themeIndex'] = themeIndex;
    if (localeCode != null) payload['locale'] = localeCode;
    if (payload.isEmpty) return;

    // The call page listens on Channel.callChannel. WindowController has its
    // own channel for window lifecycle methods and cannot receive this method.
    if (state == null) return;

    try {
      log.info('调用Call窗口设置: $payload');
      await Channel.callChannel.invokeMethod(
        Channel.callChannelMethod,
        payload,
      );
    } catch (e, st) {
      // The child engine may still be registering its handler, or may have
      // closed between the state check and this invocation.
      log.warning('Call窗口设置同步失败，已忽略本次更新', e, st);
    }
  }
}
