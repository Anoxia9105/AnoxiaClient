// Web 端 hotkey_manager 空实现桩。
class HotKeyModifier {
  const HotKeyModifier._(this._value);
  final int _value;
  static const meta = HotKeyModifier._(1);
  static const control = HotKeyModifier._(2);
  static const shift = HotKeyModifier._(4);
  static const alt = HotKeyModifier._(8);
}

class HotKeyScope {
  const HotKeyScope._(this._value);
  final int _value;
  static const inapp = HotKeyScope._(0);
  static const system = HotKeyScope._(1);
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
