// Web 端 hotkey_manager 空实现桩。
class HotKeyModifier {
  const HotKeyModifier._();
  static const meta = HotKeyModifier._();
  static const control = HotKeyModifier._();
  static const shift = HotKeyModifier._();
  static const alt = HotKeyModifier._();
}

class HotKeyScope {
  const HotKeyScope._();
  static const inapp = HotKeyScope._();
  static const system = HotKeyScope._();
}

class HotKey {
  final dynamic key;
  final List<HotKeyModifier>? modifiers;
  final HotKeyScope? scope;
  const HotKey({this.key, this.modifiers, this.scope});
}

class HotKeyManager {
  Future<void> register(
    HotKey hotKey, {
    Function(HotKey hotKey)? keyDownHandler,
  }) async {}

  Future<void> unregister(HotKey hotKey) async {}
  Future<void> unregisterAll() async {}
}

final hotKeyManager = HotKeyManager();
