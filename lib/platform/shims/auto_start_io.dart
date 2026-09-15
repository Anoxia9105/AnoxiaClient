import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../framework/logs/debug_log.dart';

/// 开机自启拉起时附加到命令行上的标记参数
///
/// 注册表/自启项中记录 `exe --autostart`，应用据此判断是否由开机自启拉起，
/// 从而决定要不要走「静默驻留托盘」逻辑。
const String kAutoStartArg = '--autostart';

/// 当前环境是否支持开机自启
///
/// 首期仅 Windows 正式包开放：
/// - 非正式包的可执行文件位于 build 目录，写进注册表会让系统开机拉起调试产物；
/// - Linux 尚未验证（桌面环境/沙盒差异大），macOS 还需额外原生集成 LaunchAtLogin。
bool autoStartSupported() => Platform.isWindows && kReleaseMode;

/// 初始化自启动配置（需在本地存储初始化之后、读写状态之前调用一次）
Future<void> autoStartSetup() async {
  if (!autoStartSupported()) return;
  try {
    final info = await PackageInfo.fromPlatform();
    launchAtStartup.setup(
      appName: info.appName,
      appPath: Platform.resolvedExecutable,
      args: const <String>[kAutoStartArg],
    );
  } catch (e, st) {
    debugLog('[AutoStart] setup 失败', e, st);
  }
}

/// 系统里是否已注册开机自启
Future<bool> autoStartIsEnabled() async {
  if (!autoStartSupported()) return false;
  try {
    return await launchAtStartup.isEnabled();
  } catch (e, st) {
    debugLog('[AutoStart] isEnabled 失败', e, st);
    return false;
  }
}

/// 注册/取消开机自启，返回操作后系统里的真实状态
///
/// 返回值用于回写 UI，避免「开关显示已开启但系统里没注册成功」。
Future<bool> autoStartSetEnabled(bool enabled) async {
  if (!autoStartSupported()) return false;
  try {
    if (enabled) {
      await launchAtStartup.enable();
    } else {
      await launchAtStartup.disable();
    }
    return await launchAtStartup.isEnabled();
  } catch (e, st) {
    debugLog('[AutoStart] setEnabled($enabled) 失败', e, st);
    return false;
  }
}
