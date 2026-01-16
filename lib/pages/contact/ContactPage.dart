import 'package:anoxia/pages/contact/component/ContactList.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ContactPage extends ConsumerWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
       return Row(
      children: [
        SizedBox(width: 80.w, child: ContactList()),
        Expanded(
          child: Text("data"),
        ),
      ],
    );
  }
}