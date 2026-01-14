import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class NotCodePage extends StatelessWidget {
  const NotCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center, children: [
        HugeIcon(icon: HugeIcons.strokeRoundedDocumentCode),
        Text("建设中...")
      ]),
    );
  }
}
