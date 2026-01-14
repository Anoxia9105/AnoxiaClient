import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notepadclient/pages/AppScaffold.dart';
import 'package:notepadclient/pages/setting/SettingsPage.dart';

import '../common/utils/DeviceUtil.dart';
import '../common/widgets/desktop/DesktopSidebar.dart';
import '../framework/provider/layout/layout_controller.dart';
import 'NotCodePage.dart';
import 'ThemeTestPage.dart';
import 'aichat/AiChatPage.dart';
import 'chat/ChatPage.dart';

class MainLayoutPage extends ConsumerWidget {
  const MainLayoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print("🛠️ MainLayoutPage 开始构建: ${DateTime.now().millisecond}ms");

    final layout = ref.watch(layoutControllerProvider);

    //最小尺寸检测
    final size = MediaQuery.of(context).size;
    if (size.width < 320 || size.height <= 320) {
      return Scaffold(
        body: Center(
          // child: FittedBox(
          //   fit: BoxFit.scaleDown,
          //   child: Application.getAppLogo(
          //     child: Text(
          //       "layout_min_size_error".tr(),
          //       textAlign: TextAlign.center,
          //     ),
          //   ),
          // ),
          child: Text("不支持过小设备"),
        ),
      );
    }

    //外层Scaffold
    return AppScaffold(
      body: Row(
        children: [
          //如果是桌面或平板，显示侧边栏
          if (DeviceUtil.isDesktop(context) || DeviceUtil.isTablet(context))
            const DesktopSidebar(),
          //主内容区
          Expanded(
            child: Scaffold(
              body: IndexedStack(
                key: ValueKey(context.locale.languageCode),
                index: layout.currentIndex,
                children: [
                  ChatPage(),
                  NotCodePage(),
                  AIChatPage(),
                  NotCodePage(),
                  NotCodePage(),
                  SettingsPage(),
                ],
              ),
            ),
          ),
        ],
      ),

      //如果是移动设备，显示底部导航栏
      bottomNavigationBar:
          // DeviceUtil.isMobile(context) ? const MobileBottomBar() : null,
          DeviceUtil.isMobile(context) ? const Text("Android") : null,
    );
  }
}
