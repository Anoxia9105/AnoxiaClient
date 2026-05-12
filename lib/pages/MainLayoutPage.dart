import 'package:anoxia/pages/AppScaffold.dart';
import 'package:anoxia/pages/contact/ContactPage.dart';
import 'package:anoxia/pages/me/MePage.dart';
import 'package:anoxia/pages/setting/SettingsPage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/utils/DeviceUtil.dart';
import '../common/widgets/app/MobileBottomBar.dart';
import '../common/widgets/desktop/DesktopSidebar.dart';
import '../framework/provider/chat/call/mobile_call_session_provider.dart';
import '../framework/provider/layout/layout_controller.dart';
import 'chat/call/MobileCallPage.dart';
import 'chat/ChatPage.dart';
import 'favorite/FavoritesPage.dart';

class MainLayoutPage extends ConsumerWidget {
  const MainLayoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print("🛠️ MainLayoutPage 开始构建: ${DateTime.now().millisecond}ms");

    final layout = ref.watch(layoutControllerProvider);
    final safeIndex = layout.currentIndex.clamp(0, layout.items.length - 1);
  final callSession = ref.watch(mobileCallSessionControllerProvider);

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
          child: Text('layout_too_small_device'.tr()),
        ),
      );
    }

    //外层Scaffold
    return AppScaffold(
      title: layout.items[safeIndex].name,
      showDesktopHeaderEnhancements: true,
      body: Stack(
        children: [
          Row(
            children: [
              //如果是桌面或平板，显示侧边栏
              if (DeviceUtil.isDesktop(context) || DeviceUtil.isTablet(context))
                const DesktopSidebar(),
              //主内容区
              Expanded(
                child: Scaffold(
                  body: IndexedStack(
                    key: ValueKey(context.locale.languageCode),
                    index: safeIndex,
                    children: [
                      ChatPage(),
                      ContactPage(),
                      FavoritesPage(),
                      MyPage(),
                      SettingsPage(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (DeviceUtil.isRealMobile() && callSession?.minimized == true)
            Positioned(
              right: 14,
              bottom: DeviceUtil.isMobile(context) ? 74 : 20,
              child: FloatingActionButton.small(
                heroTag: 'mobile-call-fab',
                onPressed: () {
                  final session = ref.read(mobileCallSessionControllerProvider);
                  if (session == null) return;
                  ref
                      .read(mobileCallSessionControllerProvider.notifier)
                      .enterCallPage();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MobileCallPage(
                        roomId: session.roomId,
                        title: session.title,
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.call),
              ),
            ),
        ],
      ),

      //如果是移动设备，显示底部导航栏
      bottomNavigationBar: DeviceUtil.isMobile(context)
          ? MobileBottomBar()
          : null,
    );
  }
}
