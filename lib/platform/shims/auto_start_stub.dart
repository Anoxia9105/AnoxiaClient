/// 开机自启能力：Web 端空实现
///
/// Web 没有「开机自启」概念，全部返回 false，保证跨平台调用点无需分支。
const String kAutoStartArg = '--autostart';

bool autoStartSupported() => false;

Future<void> autoStartSetup() async {}

Future<bool> autoStartIsEnabled() async => false;

Future<bool> autoStartSetEnabled(bool enabled) async => false;
