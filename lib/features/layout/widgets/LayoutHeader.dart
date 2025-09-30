import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:notepadclient/core/utils/DeviceUtil.dart';
import 'package:notepadclient/core/utils/PageTransitions.dart';
import 'package:notepadclient/features/auth/controller/AuthController.dart';
import 'package:notepadclient/shared/widgets/Application.dart';
import 'package:notepadclient/shared/widgets/AvatarWidget.dart';
import 'package:notepadclient/shared/widgets/BubbleDialog.dart';
import 'package:notepadclient/shared/widgets/Toast.dart';
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
    if (DeviceUtil.isRealDesktop()) {
      return AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        // backgroundColor:
        // ThemeUtil.isDarkMode(context) ? Colors.transparent : Color(0xFFE6E6E9),
        // title: Text(widget.title, style: TextStyle(fontSize: 14)),
        actions: [
          if (authController.userInfo != null) ...[
            buildMoreButton(),
            SizedBox(width: 10),
            buildUserInfo(),
          ],
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

    return AppBar(
      title: Text("Mobile Header"),
      actions: [
        if (authController.userInfo != null) ...[buildMoreButton()],
        SizedBox(width: 10),
      ],
    );
  }

  Widget buildUserInfo() {
    return AvatarWidget(
      url: authController.userInfo?.data?.avatar,
      name: authController.userInfo?.data?.userName,
      size: 35,
    );
  }

  Widget buildMoreButton() {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Tooltip(
          message: "header_more_tooltip".tr(),
          child: IconButton(
            onPressed: () {
              Function? close;
              close = Toast.showWidget(
                context,
                direction: PreferDirection.topRight,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 200),
                  child: Material(
                    type: MaterialType.transparency,
                    child: BubbleWidget(
                      arrowDirection: AxisDirection.up,
                      arrowOffset: 180,
                      arrowLength: 6,
                      arrowRadius: 3,
                      arrowWidth: 17,
                      borderRadius: BorderRadius.circular(4),
                      border: BorderSide(
                        width: 1,
                        color: colorScheme.outlineVariant,
                      ),
                      backgroundColor: colorScheme.onPrimary.withValues(
                        alpha: 0.9,
                      ),
                      contentBuilder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          layoutController.headerMenus.length * 2 - 1,
                          (index) {
                            if (index.isEven) {
                              final menu =
                                  layoutController.headerMenus[index ~/ 2];
                              return HeaderMenusOptions(
                                name: menu.localizedName,
                                icon: menu.icon,
                                onTap: () {
                                  // layoutController.jumpToPage(
                                  //   "sidebar_settings",
                                  // );
                                  Application.navigatorKey.currentState?.push(
                                    PageTransitions.createRoute(menu.page),
                                  );
                                  close?.call();
                                },
                              );
                            } else {
                              return Divider();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            icon: HugeIcon(icon: HugeIcons.strokeRoundedListSetting, size: 20),
          ),
        );
      },
    );
  }
}

class HeaderMenusOptions extends StatelessWidget {
  final String name;
  final IconData icon;
  final Widget? trailing;
  final GestureTapCallback? onTap;

  const HeaderMenusOptions({
    super.key,
    required this.name,
    required this.icon,
    this.trailing = const HugeIcon(
      icon: HugeIcons.strokeRoundedArrowRight01,
      size: 18,
    ),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: HugeIcon(icon: icon, size: 18),
      title: Text(name),
      trailing: trailing,
      hoverColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
      onTap: onTap,
    );
  }
}
