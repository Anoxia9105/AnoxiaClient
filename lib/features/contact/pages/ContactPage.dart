import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:notepadclient/features/contact/controller/ContactController.dart';
import 'package:notepadclient/features/contact/widgets/ContactLeft.dart';
import 'package:provider/provider.dart';

import '../../../core/enums/LayoutType.dart';
import '../../setting/controller/SettingsController.dart';
import '../widgets/ContactDetail.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  @override
  Widget build(BuildContext context) {
    final layoutType = context.select<SettingsController, LayoutType>(
      (s) => s.layoutType,
    );

    return Consumer<ContactController>(
      builder: (context, ContactController contact, child) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 100.w, height: double.infinity, child: ContactLeft()),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(2),
              child: layoutType == LayoutType.card
                  ? Card(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: ContactDetail(),
                      ),
                    )
                  : ContactDetail(),
            ),
          ),
        ],
      ),
    );
  }
}
