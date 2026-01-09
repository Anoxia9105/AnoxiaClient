import 'package:flutter/material.dart';

import '../common/utils/DeviceUtil.dart';
import '../common/widgets/desktop/DesktopAppBar.dart';
import '../framework/theme/AppColors.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;

  // 是否隐藏应用栏Logo
  final bool hideAppBarLogo;

  const AppScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.hideAppBarLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).extension<AppColors>()?.scaffoldGradient;

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        appBar: getAppbar(),
        body: body,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }

  //获取应用栏
  PreferredSizeWidget getAppbar() {
    if (DeviceUtil.isRealDesktop()) {
      return DesktopAppBar(hideAppBarLogo: hideAppBarLogo);
    }
    return AppBar(title: Text("Mobile Header"));
  }
}
