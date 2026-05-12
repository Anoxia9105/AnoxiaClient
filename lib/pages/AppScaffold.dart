import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../common/utils/DeviceUtil.dart';
import '../common/widgets/desktop/DesktopAppBar.dart';
import '../framework/theme/AppColors.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? mobileAppBar;
  final bool showMobileAppBar;

  // 是否隐藏应用栏Logo
  final bool hideAppBarLogo;
  // 桌面端是否显示头部增强区（搜索/状态/快捷按钮）
  final bool showDesktopHeaderEnhancements;

  const AppScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.mobileAppBar,
    this.showMobileAppBar = false, //默认不显示移动端AppBar，除非显式传入mobileAppBar或设置showMobileAppBar为true
    this.hideAppBarLogo = false,
    this.showDesktopHeaderEnhancements = false,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).extension<AppColors>()?.scaffoldGradient;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: Scaffold(
          appBar: getAppbar(context),
          body: body,
          bottomNavigationBar: bottomNavigationBar,
        ),
      ),
    );
  }

  //获取应用栏
  PreferredSizeWidget? getAppbar(BuildContext context) {
    if (DeviceUtil.isRealDesktop()) {
      return DesktopAppBar(
        hideAppBarLogo: hideAppBarLogo,
        showHeaderEnhancements: showDesktopHeaderEnhancements,
      );
    }

    if (!showMobileAppBar) return null;

    return mobileAppBar ?? AppBar(title: Text(title ?? ''));
  }
}
