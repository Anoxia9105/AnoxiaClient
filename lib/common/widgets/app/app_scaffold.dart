import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/desktop/DesktopAppBar.dart';
import 'package:anoxia/framework/theme/AppColors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? mobileAppBar;
  final bool showMobileAppBar;

  final bool hideAppBarLogo;
  final bool showDesktopHeaderEnhancements;

  const AppScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.mobileAppBar,
    this.showMobileAppBar = true,
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
          appBar: getAppbar(context, overlayStyle),
          body: body,
          bottomNavigationBar: bottomNavigationBar,
        ),
      ),
    );
  }

  PreferredSizeWidget? getAppbar(
    BuildContext context,
    SystemUiOverlayStyle overlayStyle,
  ) {
    if (DeviceUtil.isRealDesktop()) {
      return DesktopAppBar(
        hideAppBarLogo: hideAppBarLogo,
        showHeaderEnhancements: showDesktopHeaderEnhancements,
      );
    }

    if (!showMobileAppBar) return null;

    return mobileAppBar ??
        AppBar(
          title: Text(title?.tr() ?? ''),
          systemOverlayStyle: overlayStyle,
        );
  }
}
