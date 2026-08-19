import 'package:anoxia/common/utils/device_util.dart';

/// 生成带快捷键提示的按钮 tooltip 文案，例如「加粗  Ctrl+B」。
///
/// macOS 使用 ⌘/⇧，其余平台使用 Ctrl/Shift，与 flutter_quill 默认快捷键一致。
String withShortcut(String label, String shortcut) => '$label  $shortcut';

/// 按当前平台拼出快捷键文本：`shortcut('B')` -> `Ctrl+B` / `⌘B`；
/// `shortcut('S', shift: true)` -> `Ctrl+Shift+S` / `⌘⇧S`。
String shortcut(String key, {bool shift = false}) {
  final upper = key.toUpperCase();
  if (DeviceUtil.isMacOS()) {
    return '⌘${shift ? '⇧' : ''}$upper';
  }
  return 'Ctrl+${shift ? 'Shift+' : ''}$upper';
}