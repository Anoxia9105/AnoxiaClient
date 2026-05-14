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

/// 应用主布局页面
///
/// 应用的核心导航框架，根据设备类型自适应展示不同的导航样式：
/// - 桌面端/平板：左侧边栏导航
/// - 移动端：底部导航栏
///
/// 使用 [IndexedStack] 保持各页面状态，避免重复重建
class MainLayoutPage extends ConsumerWidget {
  const MainLayoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(layoutControllerProvider);
    // 确保索引在有效范围内，防止数组越界
    final safeIndex = layout.currentIndex.clamp(0, layout.items.length - 1);

    final size = MediaQuery.of(context).size;
    // 设备屏幕过小，展示提示而非崩溃
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
          // 桌面端和平板显示侧边栏
          if (DeviceUtil.isDesktop(context) || DeviceUtil.isTablet(context))
            const DesktopSidebar(),
          Expanded(
            child: Scaffold(
              body: IndexedStack(
                // 语言切换时重建 IndexedStack，避免缓存旧语言内容
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
      // 仅移动端显示底部导航栏
      bottomNavigationBar: DeviceUtil.isMobile(context)
          ? const MobileBottomBar()
          : null,
    );
  }
}
