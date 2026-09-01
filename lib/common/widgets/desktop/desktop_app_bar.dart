import 'package:anoxia/common/widgets/desktop/connection_status_tag.dart';
import 'package:anoxia/common/widgets/adaptive_page_presenter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/widgets/desktop/global_search_dialog.dart';
import 'package:anoxia/common/widgets/desktop/header_search_entry.dart';
import 'package:anoxia/framework/provider/layout/window_maximized_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:anoxia/platform/shims/window_manager_shim.dart';
import '../../../gen/assets.gen.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 桌面端应用栏
///
/// 提供窗口控制（最小化/最大化/关闭）和全局搜索功能
class DesktopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  // 是否隐藏应用栏Logo
  final bool hideAppBarLogo;
  // 是否显示增强内容（搜索、状态点、快捷新建）
  final bool showHeaderEnhancements;
  // 提供给外部的搜索回调
  final VoidCallback? onSearchTriggered;
  // 自定义标题
  final Widget? title;

  const DesktopAppBar({
    super.key,
    this.hideAppBarLogo = false,
    this.showHeaderEnhancements = false,
    this.onSearchTriggered,
    this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 最大化/还原图标以窗口真实状态为准（幂等同步），与侧边栏等 UI 状态解耦
    final maximized = ref.watch(windowMaximizedProvider);

    final canGoBack = context.canPop();
    return AppBar(
      elevation: 0,
      titleSpacing: 4,
      leading: hideAppBarLogo && canGoBack
          ? IconButton(
              onPressed: () => context.pop(),
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01),
            )
          : Center(
              child: Assets.images.appLogo.image(
                width: 24,
                height: 24,
                filterQuality: FilterQuality.high,
                // fit: BoxFit.cover
              ),
            ),
      title: () {
        if (showHeaderEnhancements) {
          return const Row(
            children: [SizedBox(width: 4), ConnectionStatusTag()],
          );
        }
        return title;
      }(),
      actions: [
        if (showHeaderEnhancements) ...[
          // 点击搜索框入口时，调用回调或直接打开
          HeaderSearchEntry(
            onTap: onSearchTriggered ?? () => _openGlobalSearch(context),
          ),
          const SizedBox(width: 6),
        ],
        //最小化
        IconButton(
          tooltip: 'header_minimize'.tr(),
          padding: EdgeInsets.zero,
          onPressed: () {
            windowManager.minimize();
          },
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedSolidLine01,
            // color: widget.iconColor,
            size: 18,
          ),
          style: ButtonStyle(
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.sm)),
            ),
          ),
        ),
        //正常/最大化
        changeScreenMode(ref, maximized),
        IconButton(
          tooltip: 'header_closure'.tr(),
          padding: EdgeInsets.zero,
          hoverColor: Colors.red,
          onPressed: () {
            windowManager.hide();
          },
          style: ButtonStyle(
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.sm)),
            ),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return Colors.white;
              }
              return null;
            }),
          ),
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedCancel01,
            size: 20,
            // color: widget.iconColor,
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: const DragToMoveArea(child: SizedBox.expand()),
    );
  }

  /// 切换窗口最大化/还原
  ///
  /// 图标状态由 windowMaximizedProvider 以真实窗口状态驱动（事件 set +
  /// 初始 isMaximized 同步），不会因事件丢失/重复而与实际脱节。
  Widget changeScreenMode(WidgetRef ref, bool maximized) {
    void toggle() => ref.read(windowMaximizedProvider.notifier).toggle();
    if (maximized) {
      return IconButton(
        tooltip: 'header_reduction'.tr(),
        padding: EdgeInsets.zero,
        onPressed: toggle,
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedChangeScreenMode,
          size: 18,
        ),
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.sm)),
          ),
        ),
      );
    }
    return IconButton(
      tooltip: 'header_maximize'.tr(),
      padding: EdgeInsets.zero,
      onPressed: toggle,
      icon: const HugeIcon(icon: HugeIcons.strokeRoundedSquare, size: 16),
      style: ButtonStyle(
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.sm)),
        ),
      ),
    );
  }

  /// 打开全局搜索对话框
  void _openGlobalSearch(BuildContext context) {
    showEscClosableDialog(context: context, builder: (_) => GlobalSearchDialog());
  }
}
