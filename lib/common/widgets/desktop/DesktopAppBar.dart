import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:window_manager/window_manager.dart';

import '../../../framework/provider/layout/layout_controller.dart';
import '../../../gen/assets.gen.dart';

class DesktopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  // 是否隐藏应用栏Logo
  final bool hideAppBarLogo;


  const DesktopAppBar({super.key, this.hideAppBarLogo = false});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extended = ref.watch(
      layoutControllerProvider.select((r) => r.extendedValue),
    );
    return AppBar(
      elevation: 0,
      leading: hideAppBarLogo
          ? SizedBox.shrink()
          : Center(
              child: Assets.images.appIconPng.image(
                width: 24,
                height: 24,
                // fit: BoxFit.cover
              ),
            ),
      actions: [
        // buildMoreButton(),
        SizedBox(width: 10),
        //最小化
        IconButton(
          tooltip: "header_minimize".tr(),
          padding: EdgeInsets.zero,
          onPressed: () {
            windowManager.minimize();
          },
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedSolidLine01,
            // color: widget.iconColor,
            size: 18,
          ),
        ),
        //正常/最大化
        changeScreenMode(extended),
        IconButton(
          tooltip: "header_closure".tr(),
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
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedCancel01,
            size: 18,
            // color: widget.iconColor,
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: const DragToMoveArea(child: SizedBox.expand()),
    );
  }

  Widget changeScreenMode(bool mode) {
    if (mode) {
      return IconButton(
        tooltip: "header_reduction".tr(),
        padding: EdgeInsets.zero,
        onPressed: () {
          windowManager.unmaximize();
        },
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedChangeScreenMode,
          // color: widget.iconColor,
          size: 18,
        ),
      );
    }
    return IconButton(
      tooltip: "header_maximize".tr(),
      padding: EdgeInsets.zero,
      onPressed: () {
        windowManager.maximize();
      },
      icon: HugeIcon(
        // color: widget.iconColor,
        icon: HugeIcons.strokeRoundedSquare,
        size: 16,
      ),
    );
  }
}
