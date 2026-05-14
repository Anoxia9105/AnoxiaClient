import 'dart:convert';

import 'package:anoxia/common/utils/NotificationHelper.dart';
import 'package:anoxia/features/chat/presentation/call/call_window_page.dart';
import 'package:anoxia/framework/protocol/message/EventMessage.dart';
import 'package:anoxia/framework/protocol/message/HighMessage.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:window_manager/window_manager.dart' as desktop;

import 'app.dart';
import 'common/constants/API.dart';
import 'common/utils/DeviceUtil.dart';
import 'common/utils/SPUtil.dart';
import 'framework/extensions/window_controller.dart';
import 'framework/logs/talker.dart';
import 'framework/network/DioClient.dart';
import 'framework/network/TokenManager.dart';
import 'framework/provider/core/AppUpdateInfo.dart';
import 'framework/protocol/PacketType.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:anoxia/features/update/presentation/pages/update_page.dart';
import 'framework/protocol/message/RoomMessage.dart';
import 'framework/protocol/register/PacketRegistry.dart';

/// 全局 Riverpod 容器（所有窗口共享，实现状态同步）
///
/// 使用 [UncontrolledProviderScope] 挂载到各个窗口，
/// 确保主窗口、子窗口、更新窗口共享同一套状态。
final ProviderContainer globalContainer = ProviderContainer(
  // 可按需开启观察者，用于调试 Provider 生命周期
  // observers: [
  //   TalkerRiverpodObserver(
  //     talker: log,
  //     settings: const TalkerRiverpodLoggerSettings(printProviderDisposed: true),
  //   ),
  // ],
);

/// SharedPreferences 存储 Key：蓝牙权限是否已申请
const String _kBluetoothPermissionRequestedKey =
    'bluetooth_permission_requested_v1';

/// 检查并请求蓝牙权限（仅 Android）
///
/// 为音视频通话做准备，仅首次启动时请求，
/// 若被永久拒绝则引导用户前往系统设置开启。
Future<void> _checkBluetoothPermissions() async {
  // Web 和非 Android 平台无需处理
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

  // 检查是否已请求过，避免重复弹窗
  final requested =
    SPUtil.instance.getBool(_kBluetoothPermissionRequestedKey) ?? false;
  if (requested) return;

  bool hasPermanentlyDenied = false;

  // 请求蓝牙权限
  var status = await Permission.bluetooth.request();
  if (status.isPermanentlyDenied) {
    log.warning('Bluetooth Permission disabled');
    hasPermanentlyDenied = true;
  }

  // 请求蓝牙连接权限
  status = await Permission.bluetoothConnect.request();
  if (status.isPermanentlyDenied) {
    log.warning('Bluetooth Connect Permission disabled');
    hasPermanentlyDenied = true;
  }

  // 记录已请求状态
  await SPUtil.instance.setBool(_kBluetoothPermissionRequestedKey, true);

  // 若有永久拒绝，引导用户去设置
  if (hasPermanentlyDenied) {
    await openAppSettings();
  }
}

/// 应用入口
Future<void> main(List<String> args) async {
  log.info("程序启动参数：$args");
  try {
    //  优先初始化 Flutter 核心绑定
    WidgetsFlutterBinding.ensureInitialized();

    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String appName = packageInfo.appName;
    String packageName = packageInfo.packageName;
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;

    log.info("=======================================================");
    log.info(appName);
    log.info(packageName);
    log.info(version);
    log.info(buildNumber);
    log.info("=======================================================");

    // 核心资源初始化（所有窗口共用，必须在窗口启动前完成）
    await Future.wait([
      EasyLocalization.ensureInitialized(), // 多语言初始化
      SPUtil.instance.init(), // 本地存储初始化
    ]);

    // Android 蓝牙耳机权限（首次启动会触发系统弹窗）
    await _checkBluetoothPermissions();

    // 检查更新
    if (!DeviceUtil.isWeb) {
      final updateInfo = await _checkUpdate();
      if (updateInfo != null && updateInfo.forceUpdate) {
        log.info("检测到强制更新，进入更新页面");
        await runUpdateApp(updateInfo);
        return;
      }
    }

    // 注册协议解析器（全局生效）
    _registerPacketParsers();

    // 桌面端窗口初始化（区分主/子窗口）
    if (DeviceUtil.isRealDesktop()) {
      await _handleDesktopWindows(args);
    } else {
      // 非桌面端直接启动主窗口
      await runMainApp();
    }
  } catch (e, stack) {
    log.error("应用启动失败", e, stack);
    // 启动失败兜底（显示错误页面）
    runApp(_buildErrorPage("应用启动失败：$e"));
  }
}

/// 注册协议解析器（抽取为独立函数，便于维护）
void _registerPacketParsers() {
  PacketRegistry.register(
    PacketType.message,
    (data) => RoomMessage.fromJson(data),
  );
  PacketRegistry.register(
    PacketType.event,
    (data) => EventMessage.fromJson(data),
  );
  PacketRegistry.register(
    PacketType.highFrequency,
    (data) => HighMessage.fromJson(data),
  );
  log.info("协议解析器注册完成");
}

/// 处理桌面端窗口逻辑（主/子窗口区分）
Future<void> _handleDesktopWindows(List<String> args) async {
  try {
    // 获取当前窗口控制器（带异常处理）
    final windowController = await WindowController.fromCurrentEngine();
    await windowController.doCustomInitialize();

    // 严谨判断是否为子窗口（解析 JSON 而非 toString）
    final bool isSubWindow = _isSubWindow(windowController.arguments);

    if (isSubWindow) {
      // 子窗口：继承全局容器，共享状态
      await runSubApp(windowController);
    } else {
      // 主窗口：初始化全局状态（如 Token）并启动
      await runMainApp();
    }
  } catch (e, stack) {
    log.error("桌面窗口初始化失败", e, stack);
    runApp(_buildErrorPage("窗口初始化失败：$e"));
  }
}

/// 严谨判断是否为子窗口（避免 toString 误判）
bool _isSubWindow(dynamic arguments) {
  if (arguments == null) return false;
  try {
    // 尝试解析为 JSON，判断是否有子窗口标识
    final argsMap = arguments is Map
        ? arguments
        : jsonDecode(arguments.toString());
    return argsMap.isNotEmpty;
  } catch (e) {
    return false;
  }
}

/// 启动主窗口（修正异步逻辑 + 窗口配置）
Future<void> runMainApp() async {
  try {
    // 预加载全局 Token（主窗口核心逻辑）
    final token = await TokenManager.instance.getToken();
    log.info('主窗口启动，Token: ${token?.substring(0, 20)}...'); // 脱敏打印

    log.info('''
 _______
< 主窗口启动 >
 -------
        \\   ^__^
         \\  (oo)\\_______
            (__)\\       )\\/\\
                ||----w |
                ||     ||
    ''');

    // 桌面端主窗口配置（标题栏隐藏 + 更大尺寸）
    if (DeviceUtil.isRealDesktop()) {
      await setupDesktopWindow(
        size: const Size(1200, 800),
        minimumSize: const Size(800, 600),
      );
      // 初始化通知服务
      await NotificationHelper().init();
    }

    // 启动主窗口（使用全局容器）
    runApp(
      UncontrolledProviderScope(
        container: globalContainer,
        child: _buildAppWrapper(const App()),
      ),
    );
  } catch (e, stack) {
    log.error("主窗口启动失败", e, stack);
    runApp(_buildErrorPage("主窗口启动失败：$e"));
  }
}

/// 启动子窗口（继承全局容器 + 适配子窗口配置）
Future<void> runSubApp(WindowController controller) async {
  try {
    log.info('子窗口启动，参数：${controller.arguments}');
    log.info('''
 _______
< 子窗口启动 >
 -------
        \\   ^__^
         \\  (oo)\\_______
            (__)\\       )\\/\\
                ||----w |
                ||     ||
    ''');

    // 子窗口配置（保留标题栏 + 较小尺寸）
    if (DeviceUtil.isRealDesktop()) {
      await setupDesktopWindow(
        size: const Size(800, 600),
        minimumSize: const Size(600, 400),
      );
    }

    // 启动子窗口（继承全局容器，共享状态）
    runApp(
      UncontrolledProviderScope(
        container: globalContainer,
        child: _buildAppWrapper(CallWindowPage(controller: controller)),
      ),
    );
  } catch (e, stack) {
    log.error("子窗口启动失败", e, stack);
    runApp(_buildErrorPage("子窗口启动失败：$e"));
  }
}

/// 启动更新窗口
Future<void> runUpdateApp(AppUpdateInfo updateInfo) async {
  try {
    log.info('''
 _______
< 更新启动 >
 -------
        \\   ^__^
         \\  (oo)\\_______
            (__)\\       )\\/\\
                ||----w |
                ||     ||
    ''');
    if (DeviceUtil.isRealDesktop()) {
      await setupDesktopWindow(
        size: const Size(800, 600),
        minimumSize: const Size(800, 600),
      );
    }

    runApp(
      UncontrolledProviderScope(
        container: globalContainer,
        child: _buildAppWrapper(UpdatePage(updateInfo: updateInfo)),
      ),
    );
  } catch (e, stack) {
    log.error("更新窗口启动失败", e, stack);
    runApp(_buildErrorPage("更新窗口启动失败：$e"));
  }
}

/// 通用窗口初始化（可配置标题栏/尺寸）
Future<void> setupDesktopWindow({
  required Size size,
  required Size minimumSize,
}) async {
  await desktop.windowManager.ensureInitialized();
  desktop.windowManager.setIcon(Assets.images.appIconIco);
  final desktop.WindowOptions windowOptions = desktop.WindowOptions(
    size: size,
    minimumSize: minimumSize,
    center: true,
    backgroundColor: Colors.white,
    // 取消透明背景，避免跨平台显示异常
    skipTaskbar: false,
    titleBarStyle: desktop.TitleBarStyle.hidden,
  );

  await desktop.windowManager.waitUntilReadyToShow(windowOptions, () async {
    await desktop.windowManager.show();
    await desktop.windowManager.focus();
  });
}

/// 公共 UI 包装器（多语言 + 屏幕适配）
Widget _buildAppWrapper(Widget home) {
  String path = DeviceUtil.isWeb ? 'i18n' : 'assets/i18n';
  return EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('zh'), Locale('ja')],
    path: path,
    fallbackLocale: const Locale('en', 'US'),
    saveLocale: true,
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: home,
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}

/// 启动失败兜底页面
Widget _buildErrorPage(String message) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          desktop.windowManager.close();
        },
        child: const Icon(Icons.close),
      ),
    ),
  );
}

Future<AppUpdateInfo?> _checkUpdate() async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersionText = packageInfo.version;
    final currentVersion = Version.parse(currentVersionText);

    String clientType = 'all';
    if (DeviceUtil.isRealWeb()) {
      clientType = 'web';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      clientType = 'android';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      clientType = 'ios';
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      clientType = 'windows';
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      clientType = 'macos';
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      clientType = 'linux';
    }

    final response = await DioClient().get(
      API.appUpdateLatest,
      auth: false,
      queryParameters: {
        'clientType': clientType,
        'currentVersion': currentVersionText,
      },
    );
    final payload = response.data;
    if (payload is! Map || payload['code'] != 200 || payload['data'] is! Map) {
      return null;
    }

    final remoteData = AppUpdateInfo.fromJson(payload['data']);
    if (remoteData.latestVersion.isEmpty || remoteData.downloadUrl.isEmpty) {
      return null;
    }
    final latestVersion = Version.parse(remoteData.latestVersion);

    if (latestVersion > currentVersion || remoteData.hasUpdate) {
      return remoteData;
    }
  } catch (e) {
    log.error("检查更新失败: $e");
  }
  return null;
}
