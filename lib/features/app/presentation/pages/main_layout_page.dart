import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/desktop/DesktopSidebar.dart';
import 'package:anoxia/common/widgets/app/MobileBottomBar.dart';
import 'package:anoxia/common/widgets/app/app_scaffold.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_page.dart';
import 'package:anoxia/features/contact/presentation/pages/contact_page.dart';
import 'package:anoxia/features/favorite/presentation/pages/favorites_page.dart';
import 'package:anoxia/features/me/presentation/pages/me_page.dart';
import 'package:anoxia/features/settings/presentation/pages/settings_page.dart';
import 'package:anoxia/framework/provider/layout/layout_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainLayoutPage extends ConsumerWidget {
  const MainLayoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(layoutControllerProvider);
    final safeIndex = layout.currentIndex.clamp(0, layout.items.length - 1);

    final size = MediaQuery.of(context).size;
    if (size.width < 320 || size.height <= 320) {
      return Scaffold(
        body: Center(child: Text('layout_too_small_device'.tr())),
      );
    }

    return AppScaffold(
      title: layout.items[safeIndex].name,
      showDesktopHeaderEnhancements: true,
      body: Row(
        children: [
          if (DeviceUtil.isDesktop(context) || DeviceUtil.isTablet(context))
            const DesktopSidebar(),
          Expanded(
            child: Scaffold(
              body: IndexedStack(
                key: ValueKey(context.locale.languageCode),
                index: safeIndex,
                children: const [
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
      bottomNavigationBar: DeviceUtil.isMobile(context)
          ? const MobileBottomBar()
          : null,
    );
  }
}
