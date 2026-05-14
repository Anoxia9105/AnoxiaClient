import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:window_manager/window_manager.dart';

class CallDesktopAppbar extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const CallDesktopAppbar({super.key, required this.title});

  @override
  State<CallDesktopAppbar> createState() => _CallDesktopAppbarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CallDesktopAppbarState extends State<CallDesktopAppbar>
    with WindowListener {
  bool extended = false;

  @override
  void onWindowMaximize() => setState(() => extended = !extended);

  @override
  void onWindowUnmaximize() => setState(() => extended = !extended);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: Text(
        widget.title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      leading: Center(
        child: Assets.images.appIconPng.image(
          width: 24,
          height: 24,
          // fit: BoxFit.cover
        ),
      ),
      elevation: 0,
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
            windowManager.close();
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
          setState(() {
            extended = !extended;
            windowManager.unmaximize();
          });
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
        setState(() {
          extended = !extended;
          windowManager.maximize();
        });
      },
      icon: HugeIcon(
        // color: widget.iconColor,
        icon: HugeIcons.strokeRoundedSquare,
        size: 16,
      ),
    );
  }
}
