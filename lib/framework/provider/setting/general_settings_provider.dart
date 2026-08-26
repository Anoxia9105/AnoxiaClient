import 'package:flutter_riverpod/legacy.dart' as legacy;

import '../../../common/constants/storage_keys.dart';
import '../../../common/utils/sp_util.dart';

/// 窗口关闭行为：最小化到托盘
class WindowMinimizeToTrayController extends legacy.StateNotifier<bool> {
  WindowMinimizeToTrayController() : super(_load());
  static bool _load() => SPUtil.instance.getBool(StorageKeys.windowMinimizeToTray, defValue: true) ?? true;
  void setEnabled(bool v) {
    if (state == v) return;
    state = v;
    SPUtil.instance.setBool(StorageKeys.windowMinimizeToTray, v);
  }
}

final windowMinimizeToTrayProvider =
    legacy.StateNotifierProvider<WindowMinimizeToTrayController, bool>((ref) => WindowMinimizeToTrayController());

/// 减少动效
class ReduceMotionController extends legacy.StateNotifier<bool> {
  ReduceMotionController() : super(_load());
  static bool _load() => SPUtil.instance.getBool(StorageKeys.reduceMotion, defValue: false) ?? false;
  void setEnabled(bool v) {
    if (state == v) return;
    state = v;
    SPUtil.instance.setBool(StorageKeys.reduceMotion, v);
  }
}

final reduceMotionProvider =
    legacy.StateNotifierProvider<ReduceMotionController, bool>((ref) => ReduceMotionController());

/// 界面字号缩放
class TextScaleController extends legacy.StateNotifier<double> {
  static const List<double> allowed = [0.9, 1.0, 1.1, 1.2];
  TextScaleController() : super(_load());
  static double _load() {
    final v = SPUtil.instance.getDouble(StorageKeys.textScaleFactor, defValue: 1.0) ?? 1.0;
    if (allowed.contains(v)) return v;
    // 兼容旧 string 存储
    final raw = SPUtil.instance.get(StorageKeys.textScaleFactor);
    final parsed = double.tryParse(raw ?? '');
    if (parsed != null && allowed.contains(parsed)) return parsed;
    return 1.0;
  }

  void setScale(double v) {
    final safe = allowed.contains(v) ? v : 1.0;
    if (state == safe) return;
    state = safe;
    SPUtil.instance.setDouble(StorageKeys.textScaleFactor, safe);
  }
}

final textScaleProvider =
    legacy.StateNotifierProvider<TextScaleController, double>((ref) => TextScaleController());

/// 发送快捷键
enum ChatSendShortcut { enter, ctrlEnter }

ChatSendShortcut parseChatSendShortcut(Object? v) {
  if (v == 'ctrlEnter') return ChatSendShortcut.ctrlEnter;
  return ChatSendShortcut.enter;
}

class ChatSendShortcutController extends legacy.StateNotifier<ChatSendShortcut> {
  ChatSendShortcutController() : super(_load());
  static ChatSendShortcut _load() => parseChatSendShortcut(SPUtil.instance.get(StorageKeys.chatSendShortcut));
  void setShortcut(ChatSendShortcut s) {
    if (state == s) return;
    state = s;
    SPUtil.instance.set(
      StorageKeys.chatSendShortcut,
      s == ChatSendShortcut.ctrlEnter ? 'ctrlEnter' : 'enter',
    );
  }
}

final chatSendShortcutProvider =
    legacy.StateNotifierProvider<ChatSendShortcutController, ChatSendShortcut>(
        (ref) => ChatSendShortcutController());

/// 消息预览（通知中显示内容）
class MessagePreviewController extends legacy.StateNotifier<bool> {
  MessagePreviewController() : super(_load());
  static bool _load() => SPUtil.instance.getBool(StorageKeys.messagePreviewEnabled, defValue: true) ?? true;
  void setEnabled(bool v) {
    if (state == v) return;
    state = v;
    SPUtil.instance.setBool(StorageKeys.messagePreviewEnabled, v);
  }
}

final messagePreviewProvider =
    legacy.StateNotifierProvider<MessagePreviewController, bool>((ref) => MessagePreviewController());

/// 自动播放媒体
class AutoPlayMediaController extends legacy.StateNotifier<bool> {
  AutoPlayMediaController() : super(_load());
  static bool _load() => SPUtil.instance.getBool(StorageKeys.autoPlayMediaEnabled, defValue: true) ?? true;
  void setEnabled(bool v) {
    if (state == v) return;
    state = v;
    SPUtil.instance.setBool(StorageKeys.autoPlayMediaEnabled, v);
  }
}

final autoPlayMediaProvider =
    legacy.StateNotifierProvider<AutoPlayMediaController, bool>((ref) => AutoPlayMediaController());
