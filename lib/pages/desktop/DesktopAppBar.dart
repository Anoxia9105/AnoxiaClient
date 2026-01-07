import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:window_manager/window_manager.dart';

class DesktopAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool extended;
  final Color? iconColor;
  final Color? backgroundColor;

  const DesktopAppBar({
    super.key,
    required this.extended,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  State<DesktopAppBar> createState() => _DesktopAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _DesktopAppBarState extends State<DesktopAppBar> {
  //公用式样
  final btnStyle = ButtonStyle(
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      // surfaceTintColor: Colors.transparent,
      backgroundColor: widget.backgroundColor,
      // ThemeUtil.isDarkMode(context) ? Colors.transparent : Color(0xFFE6E6E9),
      // title: Text(widget.title, style: TextStyle(fontSize: 14)),
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
            color: widget.iconColor,
            size: 16,
          ),
          style: btnStyle,
        ),
        //正常/最大化
        changeScreenMode(widget.extended),
        IconButton(
          tooltip: "header_closure".tr(),
          padding: EdgeInsets.zero,
          hoverColor: Colors.red,
          onPressed: () {
            //隐藏窗口 不退出程序
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
            color: widget.iconColor,
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
        style: btnStyle,
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedChangeScreenMode,
          color: widget.iconColor,
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
      style: btnStyle,
      icon: HugeIcon(
        color: widget.iconColor,
        icon: HugeIcons.strokeRoundedSquare,
        size: 16,
      ),
    );
  }
}
