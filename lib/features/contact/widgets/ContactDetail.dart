import 'package:flutter/material.dart';
import 'package:notepadclient/features/contact/controller/ContactController.dart';
import 'package:notepadclient/shared/widgets/Application.dart';
import 'package:provider/provider.dart';


///右侧详细页面切换
///
/// 作者: anoxia
///
/// 日期: 2025/10/31 上午10:15
///
class ContactDetail extends StatefulWidget {
  const ContactDetail({super.key});

  @override
  State<ContactDetail> createState() => _ContactDetailState();
}

class _ContactDetailState extends State<ContactDetail> {
  @override
  Widget build(BuildContext context) {
    final contact = context.read<ContactController>();
    if (contact.selectedIndex == -1) {
      return Center(child: Application.getAppLogo());
    }
    return IndexedStack(
      index: contact.selectedIndex,
      children: contact.detailPageList
          .map(
            (e) => Scaffold(
              appBar: AppBar(title: Text(e.name)),
              body: e.page,
            ),
          )
          .toList(),
    );
  }
}
