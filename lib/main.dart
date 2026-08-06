import 'dart:async';
import 'dart:convert';

import 'package:anoxia/framework/core/notification_helper.dart';
import 'package:anoxia/features/chat/presentation/call/window_call_page.dart';
import 'package:anoxia/features/live/presentation/pages/window_live_page.dart';
import 'package:anoxia/features/live/presentation/pages/window_live_preview_page.dart';
import 'package:anoxia/framework/core/app_globals.dart';
import 'package:anoxia/framework/core/push_manager.dart';
import 'package:anoxia/framework/provider/chat/call/call_invitation_controller.dart';
// 引入 WindowController 扩展（doCustomInitialize）。analyze 会误判 stub 分支而报 unused_import，
// 但 Windows/macOS 原生编译必须依赖该扩展，故忽略该提示。
// ignore: unused_import
import 'package:anoxia/framework/extensions/window_controller.dart';
import 'package:anoxia/framework/provider/setting/update_check_provider.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:anoxia/platform/shims/desktop_multi_window_shim.dart';
import 'package:anoxia/platform/shims/cross_tab_session_sync_shim.dart';
import 'package:anoxia/platform/shims/system_locale_shim.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anoxia/platform/shims/hotkey_manager_shim.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:anoxia/platform/shims/window_manager_shim.dart' as desktop;

import 'app.dart';
import 'common/constants/api.dart';
import 'common/utils/device_util.dart';
import 'common/utils/sp_util.dart';
import 'features/app/presentation/pages/error_page.dart';
import 'framework/logs/talker.dart';
import 'framework/network/dio_client.dart';
import 'framework/network/token_manager.dart';
import 'framework/local_cache/cache_providers.dart';
import 'framework/core/web_navigation_blocker.dart';
import 'framework/provider/auth/token_provider.dart';
import 'framework/provider/auth/auth_controller.dart';
import 'framework/provider/core/session_reset_service.dart';
import 'framework/provider/chat/room/room_list_service.dart';
import 'framework/provider/layout/layout_controller.dart';
import 'framework/domain/app_update_info.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:anoxia/features/update/presentation/pages/update_page.dart';

/// 应用入口
Future<void> main(List<String> args) async {
  log.info('程序启动参数：$args');
  try {
    //  优先初始化 Flutter 核心绑定
    WidgetsFlutterBinding.ensureInitialized();

    // Web 端禁用浏览器返回/前进按钮（须在创建 Router / WidgetsApp 之前
    // 注册，确保作为第一个 WidgetsBindingObserver 拦截 pop 消息）
    if (DeviceUtil.isRealWeb()) {
      WidgetsBinding.instance.addObserver(WebNavigationBlocker());
    }

    // 捕获 Flutter 框架在构建/布局/绘制阶段抛出的错误（含渲染异常的原始堆栈）。
    //
    // WASM 下错误处理链路（如 FlutterError.presentError → dumpErrorToConsole）
    // 可能触发二次异常 Platform._operatingSystem，把控制台刷屏并掩盖原始错误。
    // 用 try-catch 包裹确保原始错误被完整记录到 Talker；不再调用
    // presentError（会递归触发 onError），改由 ErrorWidget.builder + Talker
    // 控制台输出负责展示。
    FlutterError.onError = (FlutterErrorDetails details) {
      try {
        log.error(
          'FlutterError: ${details.exceptionAsString()}',
          details.exception,
          details.stack,
        );
      } catch (_) {
        // Talker 日志记录本身失败时，用 debugPrint 兜底（WASM 安全）
        debugPrint('FlutterError (log failed): ${details.exception}');
      }
    };

    // WASM 安全的 ErrorWidget：不访问 dart:io Platform，避免渲染错误时触发
    // 二次 Platform._operatingSystem 异常。渲染失败时展示完整自定义错误页
    // （ErrorPage），不再显示 Flutter 默认红屏。
    ErrorWidget.builder = (FlutterErrorDetails details) {
      try {
        log.error(
          'Build 失败: ${details.exceptionAsString()}',
          details.exception,
          details.stack,
        );
      } catch (_) {
        debugPrint('Build error: ${details.exception}');
      }
      return ErrorPage(
        details: details.exceptionAsString(),
        onClose: DeviceUtil.isRealDesktop()
            ? () {
                try {
                  desktop.windowManager.close();
                } catch (_) {}
              }
            : null,
      );
    };

    // 捕获 Zone 外未处理的异步错误（返回 true 阻止默认处理，避免触发 Platform）
    PlatformDispatcher.instance.onError = (error, stack) {
      try {
        log.error('未捕获异步错误', error, stack);
      } catch (_) {
        debugPrint('Async error: $error');
      }
      return true;
    };

    if (DeviceUtil.isRealDesktop()) {
      // 热键管理器初始化（桌面端全局快捷键注册）
      await hotKeyManager.unregisterAll();
    }

    // 核心资源初始化（所有窗口共用，必须在窗口启动前完成）
    await Future.wait([
      EasyLocalization.ensureInitialized(), // 多语言初始化
      SPUtil.instance.init(), // 本地存储初始化
    ]);

    _backgroundAsyncInit();

    // 桌面端窗口初始化（区分主/子窗口）
    if (DeviceUtil.isRealDesktop()) {
      await _handleDesktopWindows(args);
    } else {
      // 非桌面端直接启动主窗口
      await runMainApp();
    }
  } catch (e, stack) {
    log.error('应用启动失败', e, stack);
    // 启动失败兜底（显示错误页面）
    runApp(_buildErrorPage('应用启动失败：$e'));
  }
}

void _backgroundAsyncInit() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(() async {
      try {
        // 读包信息即使失败，也不影响用户进 App
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        log.info('App Version: ${packageInfo.version}');

        if (!DeviceUtil.isWeb) {
          // 查更新设置硬超时，防止启动阶段等待过久
          final updateInfo = await _checkUpdate().timeout(
            const Duration(seconds: 5),
          );
          // 把结果同步给 provider，避免 provider 内 3s 延迟重复请求
          globalContainer
              .read(appUpdateCheckerProvider.notifier)
              .syncResult(updateInfo, currentVersion: packageInfo.version);
          if (updateInfo != null && updateInfo.forceUpdate) {
            log.info('检测到强制更新，切换至更新页面');
            await runUpdateApp(updateInfo);
          }
        }
      } on TimeoutException {
        log.warning('后台更新检查超时，已跳过本次检查');
      } catch (e) {
        log.error('后台异步初始化异常: $e');
      }
    }());
  });
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
    log.error('桌面窗口初始化失败', e, stack);
    runApp(_buildErrorPage('窗口初始化失败：$e'));
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

/// 安装跨标签页会话同步监听
///
/// 同一浏览器（同源）的多个标签页共享 localStorage/IndexedDB，但各自持有
/// 独立内存状态。其它标签页登录/登出切换账号时，本页必须清空共享会话缓存
/// 并重载，从共享存储重新冷启动，避免「旧账号头像 + 新账号聊天列表」错位。
///
/// 仅 Web 端生效（原生端 shim 为空实现）。
void _installCrossTabSessionSync() {
  // 防抖：连续事件（登出+登录新账号等）只执行一次清理与重载
  var reloadPending = false;

  CrossTabSessionSync.instance.events.listen((event) async {
    final currentUser = globalContainer.read(authControllerProvider).value;
    final currentUserId = currentUser?.userId;

    final bool shouldReload;
    switch (event.action) {
      case CrossTabAuthAction.logout:
        // 其它标签页登出：本页已登录时回到登录页（重载后无 Token）
        shouldReload = currentUserId != null;
      case CrossTabAuthAction.login:
        // 其它标签页登录了不同账号（或未知账号，storage 兜底路径）：
        // 重载后按共享 Token 自动恢复为新账号
        shouldReload = event.userId == null || event.userId != currentUserId;
    }
    if (!shouldReload || reloadPending) return;
    reloadPending = true;

    log.info(
      '[CrossTabSync] 检测到其它标签页${event.action.name}'
      '（userId=${event.userId}），清空共享缓存并重载页面',
    );
    // 重载前清空共享 IndexedDB 会话缓存，避免把上一个账号的残留数据带进
    // 新会话；失败不阻塞重载（登录流程自身也会兜底清理）。
    try {
      await globalContainer.read(localDataSourceProvider).clearSessionCache();
    } catch (e, st) {
      log.warning('[CrossTabSync] 清空本地会话缓存失败（忽略）: $e', e, st);
    }
    CrossTabSessionSync.instance.reload();
  });
}

/// 启动主窗口（修正异步逻辑 + 窗口配置）
Future<void> runMainApp() async {
  try {
    // 预加载全局 Token（主窗口核心逻辑）
    final token = await TokenManager.instance.getToken();
    log.info('主窗口启动，Token available: ${token?.isNotEmpty == true}');
    NotificationHelper().configure(
      onOpenRoom: (roomId) {
        globalContainer.read(activeRoomIdProvider.notifier).setActive(roomId);
        globalContainer.read(layoutControllerProvider.notifier).setIndex(0);
      },
      onCallAction: (actionId, payload) async {
        final invitation = CallInvitationState.fromNotificationPayload(payload);
        final controller = globalContainer.read(
          callInvitationControllerProvider.notifier,
        );
        if (actionId == NotificationHelper.callAcceptAction) {
          await controller.acceptAndOpen(invitation);
        } else if (actionId == NotificationHelper.callRejectAction) {
          await controller.reject(invitation);
        }
        await NotificationHelper().cancelIncomingCall(invitation.inviteId);
      },
    );
    if (DeviceUtil.isRealMobile()) {
      PushManager.instance.setOnNotification((payload) {
        final pushType =
            payload['pushType']?.toString() ?? payload['kind']?.toString();
        if (pushType == 'call_invite' || pushType == 'incoming_call') {
          globalContainer
              .read(callInvitationControllerProvider.notifier)
              .receiveExternalInvite(payload);
          return;
        }
        final roomId = payload['roomId']?.toString();
        if (roomId != null && roomId.isNotEmpty) {
          globalContainer.read(activeRoomIdProvider.notifier).setActive(roomId);
          globalContainer.read(layoutControllerProvider.notifier).setIndex(0);
        }
      });
    }
    DioClient().configureAuth(
      tokenLoader: () async {
        final cached = globalContainer.read(tokenCacheProvider);
        if (cached?.isNotEmpty == true) return cached;
        return TokenManager.instance.getToken();
      },
      onUnauthorized: () => globalContainer
          .read(authControllerProvider.notifier)
          .logout(
            reason: SessionResetReason.tokenExpired,
            notifyBackend: false,
          ),
    );

    // 跨标签页会话同步：其它标签页登录/登出切换账号时，本页重置并重载
    _installCrossTabSessionSync();

    // 初始化 DioClient 的国际化语言（用户选择过的 → 系统语言 → 默认 zh）
    final startLocale = _resolveStartLocale();
    DioClient().setLocale(startLocale);

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
        child: _buildAppWrapper(const App(), startLocale: startLocale),
      ),
    );
  } catch (e, stack) {
    log.error('主窗口启动失败', e, stack);
    runApp(_buildErrorPage('主窗口启动失败：$e'));
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

    final args = _parseWindowArguments(controller.arguments);
    final Widget child = switch (args['type']) {
      'live-preview' => WindowLivePreviewPage(controller: controller),
      'live' => WindowLivePage(controller: controller),
      _ => WindowCallPage(controller: controller),
    };

    final container = await _createIsolatedWindowContainer();

    // 子窗口使用独立 ProviderContainer，仅同步认证 token，避免通话/聊天室状态污染主窗口。
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: _buildAppWrapper(child, startLocale: _resolveStartLocale()),
      ),
    );
  } catch (e, stack) {
    log.error('子窗口启动失败', e, stack);
    runApp(_buildErrorPage('子窗口启动失败：$e'));
  }
}

Map<String, dynamic> _parseWindowArguments(dynamic arguments) {
  if (arguments == null) {
    return {};
  }
  try {
    final decoded = arguments is Map
        ? arguments
        : jsonDecode(arguments.toString());
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
  } catch (_) {}
  return {};
}

/// 启动更新窗口
Future<ProviderContainer> _createIsolatedWindowContainer() async {
  final container = ProviderContainer();
  final token = await TokenManager.instance.getToken();
  if (token != null && token.isNotEmpty) {
    container.read(tokenCacheProvider.notifier).setToken(token);
  }
  return container;
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
        child: _buildAppWrapper(
          UpdatePage(updateInfo: updateInfo),
          startLocale: _resolveStartLocale(),
        ),
      ),
    );
  } catch (e, stack) {
    log.error('更新窗口启动失败', e, stack);
    runApp(_buildErrorPage('更新窗口启动失败：$e'));
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

/// 解析启动语言：用户手动选择过的 → 系统/浏览器语言 → 默认 zh
///
/// easy_localization 在 WASM 下无法获取设备语言（内部 intl_standalone 依赖
/// dart:io，Web 上抛异常后 Intl.systemLocale 恒为 en_US），这里自行检测
/// 并作为 startLocale 传入；用户手动选择过的语言（saveLocale）优先级更高。
String _resolveStartLocale() {
  final saved = SPUtil.instance.get('locale');
  if (saved != null && saved.isNotEmpty) {
    final lower = saved.toLowerCase();
    if (lower.startsWith('zh')) return 'zh';
    if (lower.startsWith('ja')) return 'ja';
    return 'en';
  }
  final system = SystemLocale.languageCode();
  if (system != null) return system;
  return 'zh';
}

/// 公共 UI 包装器（多语言 + 屏幕适配）
Widget _buildAppWrapper(Widget home, {String? startLocale}) {
  return EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('zh'), Locale('ja')],
    path: 'assets/i18n',
    fallbackLocale: const Locale('en'),
    startLocale: startLocale != null ? Locale(startLocale) : null,
    saveLocale: true,

    /// 通过 ScreenUtilInit 包裹，提供屏幕适配功能
    ///
    /// rebuildFactor 设为 none：禁用 resize 时 _updateTree 递归遍历整个 widget 树
    /// 调用 markNeedsBuild 的行为。该递归在 WASM 模式下因调用栈较小会导致
    /// "Maximum call stack size exceeded" 崩溃（resize 时触发）。
    /// .w/.h/.sp 等扩展仅为数学计算，widget 的响应式重建由 MediaQuery 自然驱动即可。
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      rebuildFactor: RebuildFactors.none,
      builder: (context, child) => MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: home,
        debugShowCheckedModeBanner: false,
        // 大字号（无障碍）模式下将全局文本缩放钳制在 1.3 以内，
        // 防止小屏设备 + 系统放大字体叠加导致布局溢出。
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );
}

/// 启动失败兜底页面（复用全局错误页，国际化未就绪时自动回退默认文案）
Widget _buildErrorPage(String message) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ErrorPage(
      message: message,
      onClose: () {
        try {
          desktop.windowManager.close();
        } catch (_) {}
      },
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
    log.error('检查更新失败: $e');
  }
  return null;
}
