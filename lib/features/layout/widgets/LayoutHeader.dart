import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:notepadclient/App.dart';
import 'package:notepadclient/core/utils/DeviceUtil.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/di/injector.dart';
import '../controller/LayoutController.dart';

/// 桌面端头部组件
///
/// 作者: anoxia
///
/// 版本: 1.0.0
///
/// 创建时间: 2025-09-16  18:49
class LayoutHeader {
  final btnStyle = ButtonStyle(
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
  );
  final LayoutController layoutController = getIt<LayoutController>();

  AppBar getAppbar() {
    if(DeviceUtil.isDesktop){
      return AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        // backgroundColor:
        // ThemeUtil.isDarkMode(context) ? Colors.transparent : Color(0xFFE6E6E9),
        // title: Text(widget.title, style: TextStyle(fontSize: 14)),
        actions: [
          // buildUserInfo(),
          SizedBox(width: 10),
          IconButton(
            tooltip: "最小化",
            padding: EdgeInsets.zero,
            onPressed: () {
              windowManager.minimize();
            },
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedSolidLine01,
              size: 16,
            ),
            style: btnStyle,
          ),
          layoutController.extended
              ? IconButton(
            tooltip: "还原",
            padding: EdgeInsets.zero,
            onPressed: () {
              windowManager.unmaximize();
            },
            style: btnStyle,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedChangeScreenMode,
              size: 18,
            ),
          )
              : IconButton(
            tooltip: "最大化",
            padding: EdgeInsets.zero,
            onPressed: () {
              windowManager.maximize();
            },
            style: btnStyle,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedSquare,
              size: 16,
            ),
          ),
          IconButton(
            tooltip: "关闭",
            padding: EdgeInsets.zero,
            hoverColor: Colors.red,
            onPressed: () {
              windowManager.hide();
            },
            style: ButtonStyle(
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) {
                  return Colors.white;
                }
                return null;
              }),
            ),
            icon: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 18),
          ),
          const SizedBox(width: 8),
        ],
        flexibleSpace: const DragToMoveArea(child: SizedBox.expand()),
      );
    }
    return AppBar(
      title: Text("Mobile Header"),
    );

  }
}
