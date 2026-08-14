import 'package:anoxia/common/utils/sp_util.dart';
import 'package:flutter_riverpod/legacy.dart' as legacy;

bool shouldUseChatFocusMode({
  required bool enabled,
  required bool isWideLayout,
  required int currentIndex,
  required String? activeRoomId,
}) {
  return enabled &&
      isWideLayout &&
      currentIndex == 0 &&
      activeRoomId != null &&
      activeRoomId.isNotEmpty;
}

class ChatFocusModeController extends legacy.StateNotifier<bool> {
  static const _storageKey = 'chat_focus_mode_enabled';

  ChatFocusModeController()
    : super(SPUtil.instance.getBool(_storageKey, defValue: false) ?? false);

  void setEnabled(bool enabled) {
    if (state == enabled) return;
    state = enabled;
    SPUtil.instance.setBool(_storageKey, enabled);
  }

  void toggle() => setEnabled(!state);
}

final chatFocusModeProvider =
    legacy.StateNotifierProvider<ChatFocusModeController, bool>(
      (ref) => ChatFocusModeController(),
    );
