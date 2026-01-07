import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:window_manager/window_manager.dart' as desktop;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_observer.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_settings.dart';

import 'app.dart';
import 'common/utils/DeviceUtil.dart';
import 'common/utils/SPUtil.dart';
import 'framework/logs/talker.dart';
import 'framework/network/TokenManager.dart';
import 'framework/provider/auth/auth_controller.dart';

late final ProviderContainer globalContainer;

void main() async {
  // 确保 Flutter 绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化多语言支持
  await EasyLocalization.ensureInitialized();
  // 初始化本地存储
  await SPUtil.init();

  // 预加载并缓存 token，避免后续多处并发读取
  final token = await TokenManager.instance.getToken();
  print('启动预加载的 token: $token');

  log.info('''
 _______
< DEV >
 -------
        \\   ^__^
         \\  (oo)\\_______
            (__)\\       )\\/\\
                ||----w |
                ||     ||
  ''');

  String path = DeviceUtil.isWeb ? 'i18n' : 'assets/i18n';

  // 使用 ScreenUtilInit 进行屏幕适配
  var app = ScreenUtilInit(
    designSize: const Size(375, 812), // iPhone 13 设计稿尺寸
    minTextAdapt: true, // 文本自适应优化
    splitScreenMode: true, // 支持分屏模式
    builder: (context, child) {
      return EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('zh'), Locale('ja')],
        path: path,
        fallbackLocale: const Locale('en', 'US'),
        saveLocale: true,
        child: const App(),
      );
    },
  );

  // 仅桌面端执行 window_manager 初始化
  if (DeviceUtil.isRealDesktop()) {
    await desktop.windowManager.ensureInitialized();

    final windowOptions = desktop.WindowOptions(
      size: const Size(1200, 800),
      minimumSize: const Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: desktop.TitleBarStyle.hidden,
    );

    desktop.windowManager.waitUntilReadyToShow(windowOptions, () async {
      await desktop.windowManager.show();
      await desktop.windowManager.focus();
      await desktop.windowManager.setHasShadow(true);
    });
  }

  // 创建 Riverpod 容器并添加 Talker 观察者
  globalContainer = ProviderContainer(
    observers: [
      TalkerRiverpodObserver(
        talker: log,
        settings: const TalkerRiverpodLoggerSettings(
          printProviderDisposed: true,
        ),
      ),
    ],
  );

  try {
    await globalContainer.read(authControllerProvider.notifier).autoLogin();
  } catch (e, st) {
    log.error("自动登录失败", e, st);
  }
  runApp(UncontrolledProviderScope(container: globalContainer, child: app));
}
