/// 通话窗口控制器
///
/// 管理桌面端通话独立窗口的创建、显示、设置同步和成员邀请。
/// 基于 Riverpod 的 KeepAlive Provider，通过多窗口框架实现子窗口通信。
import 'dart:convert';

import 'package:anoxia/platform/shims/desktop_multi_window_shim.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:anoxia/framework/codec/v5/im_packet_v5.dart';
import 'package:anoxia/framework/protocol/message/high_message.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';

import '../../../logs/talker.dart';
import 'channel.dart';
import 'call_initial_media.dart';

part 'call_window_controller.g.dart';

/// 通话窗口控制器
///
/// 负责桌面端通话窗口的创建、管理、设置同步和通话成员邀请。
/// 通过 [WindowController] 实现多窗口通信。
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

  /// 打开通话窗口
  ///
  /// 若窗口已存在则显示并同步设置，否则创建新窗口。
  /// [themeIndex] 主题索引；[title] 窗口标题；[roomId] 房间 ID；
  /// [initialMedia] 初始媒体类型；[isGroup] 是否为群组通话；[token] 可选认证令牌。
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
