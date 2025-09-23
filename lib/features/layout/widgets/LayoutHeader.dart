import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:notepadclient/core/utils/DeviceUtil.dart';
import 'package:notepadclient/features/auth/controller/AuthController.dart';
import 'package:notepadclient/shared/widgets/AvatarWidget.dart';
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
  final AuthController authController = getIt<AuthController>();

  AppBar getAppbar({Color? color}) {
    if (DeviceUtil.isDesktop) {
      return AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        // backgroundColor:
        // ThemeUtil.isDarkMode(context) ? Colors.transparent : Color(0xFFE6E6E9),
        // title: Text(widget.title, style: TextStyle(fontSize: 14)),
        actions: [
          authController.userInfo !=null ?buildUserInfo():SizedBox.shrink(),
          SizedBox(width: 10),
          IconButton(
            tooltip: "header_minimize".tr(),
            padding: EdgeInsets.zero,
            onPressed: () {
              windowManager.minimize();
            },
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedSolidLine01,
              color: color,
              size: 16,
            ),
            style: btnStyle,
          ),
          layoutController.extended
              ? IconButton(
                  tooltip: "header_reduction".tr(),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    windowManager.unmaximize();
                  },
                  style: btnStyle,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedChangeScreenMode,
                    color: color,
                    size: 18,
                  ),
                )
              : IconButton(
                  tooltip: "header_maximize".tr(),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    windowManager.maximize();
                  },
                  style: btnStyle,
                  icon: HugeIcon(
                    color: color,
                    icon: HugeIcons.strokeRoundedSquare,
                    size: 16,
                  ),
                ),
          IconButton(
            tooltip: "header_closure".tr(),
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
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedCancel01,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
        ],
        flexibleSpace: const DragToMoveArea(child: SizedBox.expand()),
      );
    }
    return AppBar(title: Text("Mobile Header"));
  }

  Widget buildUserInfo() {
    return  AvatarWidget(
      url: authController.userInfo?.data?.avatar,
      name: authController.userInfo?.data?.userName,
      size: 35,
    );
  }
}
