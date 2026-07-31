// Web 端 tray_manager 空实现桩。
class MenuItem {
  final String? key;
  final String? label;
  final List<MenuItem>? children;
  const MenuItem({this.key, this.label, this.children});
  factory MenuItem.separator() => const MenuItem();
}

class Menu {
  final List<MenuItem>? items;
  const Menu({this.items});
}

mixin TrayListener {
  void onTrayIconMouseDown() {}
  void onTrayIconRightMouseDown() {}
  void onTrayIconMouseUp() {}
  void onTrayIconRightMouseUp() {}
  void onTrayMenuItemClick(MenuItem menuItem) {}
}

class TrayManager {
  Future<void> setIcon(String path) async {}
  Future<void> setToolTip(String tooltip) async {}
  Future<void> setContextMenu(Menu menu) async {}
  void popUpContextMenu() {}
  void addListener(TrayListener listener) {}
  void removeListener(TrayListener listener) {}
}

final trayManager = TrayManager();
