import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../logs/talker.dart';
import 'Channel.dart';

part 'call_window_controller.g.dart';

@Riverpod(keepAlive: true)
class CallWindowController extends _$CallWindowController {
  @override
  WindowController? build() {
    Channel.callChannel.setMethodCallHandler((call) async {
      if (call.method == 'on_call_window_close') {
        log.info("收到窗口关闭");
        state = null;
      }
      return null;
    });
    return null;
  }

  /// 打开或聚焦通话窗口
  Future<void> openCallWindow({
    required int themeIndex,
    required String title,
    required String roomId,
  }) async {
    if (state != null) {
      await state!.show();
      return;
    }
    // 2. 创建新窗口
    final controller = await WindowController.create(
      WindowConfiguration(
        hiddenAtLaunch: true,
        arguments: jsonEncode({'themeIndex': themeIndex, 'title': title,'roomId':roomId}),
      ),
    );

    // 3. 保存 ID 到状态
    state = controller;

    Future.delayed(Duration(seconds: 1), () {
      controller.show();
    });
  }

  void updateSettings({int? themeIndex, String? localeCode}) {
    log.info("调用Call窗口$themeIndex,$localeCode");

    if (themeIndex != null) {
      Channel.callChannel.invokeMethod(Channel.callChannelMethod, {
        'themeIndex': themeIndex,
      });
    }
    if (localeCode != null) {
      Channel.callChannel.invokeMethod(Channel.callChannelMethod, {
        'locale': localeCode,
      });
    }
  }
}
