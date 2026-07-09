import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../logs/talker.dart';
import 'Channel.dart';
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
      }
      return null;
    });
    return null;
  }

  Future<void> openCallWindow({
    required int themeIndex,
    required String title,
    required String roomId,
    CallInitialMedia initialMedia = CallInitialMedia.audio,
  }) async {
    if (state != null) {
      await state!.show();
      updateSettings(themeIndex: themeIndex);
      return;
    }

    ref.read(callInitialMediaProvider(roomId).notifier).state = initialMedia;
    final controller = await WindowController.create(
      WindowConfiguration(
        hiddenAtLaunch: true,
        arguments: jsonEncode({
          'themeIndex': themeIndex,
          'title': title,
          'roomId': roomId,
          'initialMedia': initialMedia.value,
        }),
      ),
    );

    state = controller;
    controller.show();
  }

  void updateSettings({int? themeIndex, String? localeCode}) {
    final payload = <String, Object>{};
    if (themeIndex != null) payload['themeIndex'] = themeIndex;
    if (localeCode != null) payload['locale'] = localeCode;
    if (payload.isEmpty) return;

    log.info('调用Call窗口设置: $payload');

    final controller = state;
    if (controller != null) {
      controller.invokeMethod(Channel.callChannelMethod, payload);
      return;
    }

    Channel.callChannel.invokeMethod(Channel.callChannelMethod, payload);
  }
}
