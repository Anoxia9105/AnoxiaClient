import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/desktop/DesktopSidebar.dart';
import 'package:anoxia/common/widgets/app/MobileBottomBar.dart';
import 'package:anoxia/common/widgets/app/app_scaffold.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_page.dart';
import 'package:anoxia/features/contact/presentation/pages/contact_page.dart';
import 'package:anoxia/features/favorite/presentation/pages/favorites_page.dart';
import 'package:anoxia/features/live/presentation/pages/live_list_page.dart';
import 'package:anoxia/features/me/presentation/pages/me_page.dart';
import 'package:anoxia/features/me/presentation/pages/menu_page.dart';
import 'package:anoxia/features/settings/presentation/pages/settings_page.dart';
import 'package:anoxia/framework/provider/layout/layout_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

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

    Widget buildMainContent() {
      return AppScaffold(
        showDesktopHeaderEnhancements: DeviceUtil.isDesktop(context),
        body: Row(
          children: [
            /// 桌面端和平板显示侧边栏，移动端不显示
            if (DeviceUtil.isDesktop(context) || DeviceUtil.isTablet(context))
              const DesktopSidebar(),
            Expanded(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: IndexedStack(
                  key: ValueKey(context.locale.languageCode),
                  index: safeIndex,
                  children: const [
                    _DesktopContentCard(child: ChatPage()),
                    _DesktopContentCard(child: ContactPage()),
                    _DesktopContentCard(child: LiveListPage()),
                    _DesktopContentCard(child: FavoritesPage()),
                    MyPage(),
                    _DesktopContentCard(child: SettingsPage()),
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

    if (DeviceUtil.isMobile(context)) {
      return ZoomDrawer(
        menuBackgroundColor: Theme.of(context).colorScheme.primary, // 抽屉背景色
        menuScreen: const MenuPage(), // 左侧抽屉菜单
        mainScreen: buildMainContent(), // 将带底部导航栏的整体作为主体推走
        borderRadius: 24.0,
        showShadow: false,
        angle: 0.0, // 纯平移
        slideWidth: size.width * 0.65, // 侧滑宽度 65%
        menuScreenWidth: size.width * 0.65, // 抽屉宽度 65%
      );
    }

    // 桌面端和平板直接返回原生主体，没有任何抽屉干扰
    return buildMainContent();
  }
}

class _DesktopContentCard extends StatelessWidget {
  final Widget child;

  const _DesktopContentCard({required this.child});

  @override
  Widget build(BuildContext context) {
    if (DeviceUtil.isMobile(context)) {
      return child;
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: isDark ? 0.16 : 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.12),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: cs.primary.withValues(alpha: isDark ? 0.10 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(18), child: child),
      ),
    );
  }
}
