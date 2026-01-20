import 'package:anoxia/framework/protocol/message/EventMessage.dart';
import 'package:anoxia/framework/protocol/message/HighMessage.dart';
import 'package:anoxia/pages/sub_window/CallWindowPage.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:window_manager/window_manager.dart' as desktop;

import 'app.dart';
import 'common/utils/DeviceUtil.dart';
import 'common/utils/SPUtil.dart';
import 'framework/extensions/window_controller.dart';
import 'framework/logs/talker.dart';
import 'framework/network/TokenManager.dart';
import 'framework/protocol/PacketType.dart';
import 'framework/protocol/message/RoomMessage.dart';
import 'framework/protocol/register/PacketRegistry.dart';

// 创建 Riverpod 容器并添加 Talker 观察者
final ProviderContainer globalContainer = ProviderContainer(
  // observers: [
  //   // provider 观察者，记录 provider 生命周期和状态变化
  //   TalkerRiverpodObserver(
  //     talker: log,
  //     settings: const TalkerRiverpodLoggerSettings(printProviderDisposed: true),
  //   ),
  // ],
);

Future<void> main(List<String> args) async {
  log.info("程序启动参数：$args");
  // 确保 Flutter 绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();
  if (DeviceUtil.isRealDesktop()) {
    // 1. 获取窗口控制器
    final windowController = await WindowController.fromCurrentEngine();
    //注册扩展
    await windowController.doCustomInitialize();
    final bool isSubWindow =
        windowController.arguments.toString().isNotEmpty &&
        windowController.arguments != "{}";
    if (isSubWindow) {
      runSubApp(windowController);
    }
  }

  await EasyLocalization.ensureInitialized();

  await SPUtil.init();
  //解析器注册
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
  runMainApp();
}

void runMainApp() async {
  // 预加载 Token (主窗口逻辑)
  final token = await TokenManager.instance.getToken();
  log.info('主窗口启动，Token: $token');

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
  if (DeviceUtil.isRealDesktop()) {
    await setupDesktopWindow(size: const Size(1200, 800));
  }
  runApp(
    UncontrolledProviderScope(
      container: globalContainer,
      child: _buildAppWrapper(const App()), // 使用主 App 界面
    ),
  );
}

void runSubApp(WindowController controller) async {
  log.info('子窗口启动');

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

  await setupDesktopWindow(size: const Size(800, 600));

  runApp(
    ProviderScope(
      child: _buildAppWrapper(CallWindowPage(controller: controller)),
    ),
  );
}

// ================= 公共 UI 包装器 =================
// 确保所有窗口都有多语言和屏幕适配能力
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
      builder: (context, child) => home,
    ),
  );
}

// 抽取一个通用的窗口初始化函数
Future<void> setupDesktopWindow({required Size size}) async {
  if (!DeviceUtil.isRealDesktop()) return;

  await desktop.windowManager.ensureInitialized();

  desktop.WindowOptions windowOptions = desktop.WindowOptions(
    size: size,
    minimumSize: const Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    // 主窗口通常隐藏标题栏，子窗口根据需求决定
    titleBarStyle: desktop.TitleBarStyle.hidden,
  );

  await desktop.windowManager.waitUntilReadyToShow(windowOptions, () async {
    await desktop.windowManager.show();
    await desktop.windowManager.focus();
  });
}
// {
// "topic":"HIGH_FREQUENCY",
// "data":{
//   "targetId": "1",
//   "roomId": "testroom1",
//   "type": "TYPING_STATUS",
//   "content": "true"
// }
// }

// {
// "topic":"MESSAGE",
// "data":{
//   "messageId": "msg-202512221416001",
//   "roomId": "testroom1",
//   "targetId": "1",
//   "type": "TEXT",
//   "payload": {
//     "content": "SINGLE 你好"
//   }
// }
// }
