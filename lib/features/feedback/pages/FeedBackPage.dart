import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/utils/DeviceUtil.dart';
import '../../../shared/theme/AppColors.dart';

class FeedBackPage extends StatefulWidget {
  const FeedBackPage({super.key});

  @override
  State<FeedBackPage> createState() => _FeedBackPageState();
}

class _FeedBackPageState extends State<FeedBackPage> {
  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).extension<AppColors>()?.scaffoldGradient;
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        appBar: DeviceUtil.isRealDesktop()
            ? AppBar(
                title: Text("feedback_page_title".tr()),
                flexibleSpace: const DragToMoveArea(child: SizedBox.expand()),
              )
            : AppBar(title: Text("feedback_page_title".tr())),
        body: Center(child: Column(
          children: [
            TextField()
          ],
        )),
      ),
    );
  }
}
