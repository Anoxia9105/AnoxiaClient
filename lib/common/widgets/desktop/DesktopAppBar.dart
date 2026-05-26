import 'package:anoxia/common/widgets/desktop/ConnectionStatusTag.dart';
import 'package:anoxia/common/widgets/desktop/GlobalSearchDialog.dart';
import 'package:anoxia/common/widgets/desktop/HeaderSearchEntry.dart';
import 'package:anoxia/framework/provider/layout/layout_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:window_manager/window_manager.dart';
import '../../../gen/assets.gen.dart';

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

  const DesktopAppBar({
    super.key,
    this.hideAppBarLogo = false,
    this.showHeaderEnhancements = false,
    this.onSearchTriggered,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extended = ref.watch(
      layoutControllerProvider.select((r) => r.extendedValue),
    );

    return AppBar(
      elevation: 0,
      titleSpacing: 4,
      leading: hideAppBarLogo
          ? const SizedBox.shrink()
          : Center(
              child: Assets.images.appIconPng.image(
                width: 24,
                height: 24,
                // fit: BoxFit.cover
              ),
            ),
      title: const Row(children: [SizedBox(width: 4), ConnectionStatusTag()]),
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
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
        //正常/最大化
        changeScreenMode(extended),
        IconButton(
          tooltip: 'header_closure'.tr(),
          padding: EdgeInsets.zero,
          hoverColor: Colors.red,
          onPressed: () {
            windowManager.hide();
          },
          style: ButtonStyle(
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
  Widget changeScreenMode(bool mode) {
    if (mode) {
      return IconButton(
        tooltip: 'header_reduction'.tr(),
        padding: EdgeInsets.zero,
        onPressed: () {
          windowManager.unmaximize();
        },
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedChangeScreenMode,
          // color: widget.iconColor,
          size: 18,
        ),
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
      );
    }
    return IconButton(
      tooltip: 'header_maximize'.tr(),
      padding: EdgeInsets.zero,
      onPressed: () {
        windowManager.maximize();
      },
      icon: const HugeIcon(
        // color: widget.iconColor,
        icon: HugeIcons.strokeRoundedSquare,
        size: 16,
      ),
      style: ButtonStyle(
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }

  /// 打开全局搜索对话框
  void _openGlobalSearch(BuildContext context) {
    showDialog(context: context, builder: (_) => GlobalSearchDialog());
  }
}
