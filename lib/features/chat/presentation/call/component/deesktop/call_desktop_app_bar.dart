import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:anoxia/gen/assets.gen.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:window_manager/window_manager.dart';

/// 桌面端通话应用栏组件
///
/// 提供通话窗口的标题栏，包含：
/// - 应用图标和标题
/// - 窗口控制按钮（最小化、最大化/还原、关闭）
/// - 可拖拽移动窗口的区域
class CallDesktopAppbar extends StatefulWidget implements PreferredSizeWidget {
  /// 标题文字
  final String title;

  const CallDesktopAppbar({super.key, required this.title});

  @override
  State<CallDesktopAppbar> createState() => _CallDesktopAppbarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CallDesktopAppbarState extends State<CallDesktopAppbar>
    with WindowListener {
  /// 窗口是否处于最大化状态
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
        ),
      ),
      elevation: 0,
      actions: [
        const SizedBox(width: 10),
        IconButton(
          tooltip: "header_minimize".tr(),
          padding: EdgeInsets.zero,
          onPressed: () {
            windowManager.minimize();
          },
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedSolidLine01,
            size: 18,
          ),
        ),
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
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: const DragToMoveArea(child: SizedBox.expand()),
    );
  }

  /// 构建窗口模式切换按钮
  ///
  /// 根据当前窗口状态显示最大化或还原图标
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
        icon: HugeIcons.strokeRoundedSquare,
        size: 16,
      ),
    );
  }
}
