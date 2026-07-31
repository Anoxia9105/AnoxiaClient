// Web 端 flutter_background 桩。
enum AndroidNotificationImportance { none, min, low, normal, high, max }

class AndroidResource {
  final String? name;
  final String? defType;
  const AndroidResource({this.name, this.defType});
}

class FlutterBackgroundAndroidConfig {
  final String? notificationTitle;
  final String? notificationText;
  final AndroidNotificationImportance? notificationImportance;
  final dynamic notificationIcon;
  const FlutterBackgroundAndroidConfig({
    this.notificationTitle,
    this.notificationText,
    this.notificationImportance,
    this.notificationIcon,
  });
}

class FlutterBackground {
  static bool get isBackgroundExecutionEnabled => false;
  static Future<bool> initialize({
    required FlutterBackgroundAndroidConfig androidConfig,
  }) async =>
      true;
  static Future<void> enableBackgroundExecution() async {}
  static Future<void> disableBackgroundExecution() async {}
}
