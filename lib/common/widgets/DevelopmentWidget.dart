import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class DevelopmentWidget extends StatelessWidget {
  const DevelopmentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('development_under_construction'.tr()));
  }
}
