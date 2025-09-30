import 'package:alphabet_list_view/alphabet_list_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:notepadclient/features/contact/pages/GroupListPage.dart';
import 'package:notepadclient/features/contact/pages/NewContactPage.dart';

import '../pages/ContactDetailPage.dart';

class ContactController extends ChangeNotifier {
  ///字母排序列表
  late List<AlphabetListViewItemGroup> tech = [
    AlphabetListViewItemGroup(
      tag: 'B',
      children: [Text('Baidu'), Text('Bilibili')],
    ),
    AlphabetListViewItemGroup(
      tag: 'A',
      children: [Text('Apple'), Text('Amazon'), Text('Alibaba')],
    ),
    AlphabetListViewItemGroup(tag: 'I', children: [Text('Intel'), Text('IBM')]),
    AlphabetListViewItemGroup(
      tag: 'H',
      children: [Text('Huawei'), Text('Honor')],
    ),
  ];

  int _selectedIndex = -1;

  int get selectedIndex => _selectedIndex;

  set selectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  List<ContactOptions> detailPageList = [
    ContactOptions(
      name: "新的朋友",
      icon: HugeIcons.strokeRoundedAddTeam,
      page: NewContactPage(),
    ),
    ContactOptions(
      name: "加入的群聊",
      icon: HugeIcons.strokeRoundedUserGroup03,
      page: GroupListPage(),
    ),
    ContactOptions(
      name: "联系人",
      icon: HugeIcons.strokeRoundedAddTeam,
      page: ContactDetailPage(),
      show: false,
    ),
  ];
}

class ContactOptions {
  final String name;
  final Widget page;
  final IconData icon;
  final bool show;

  String get localizedName => name.tr();

  ContactOptions({
    required this.name,
    required this.icon,
    required this.page,
    this.show = true,
  });
}
