import 'package:alphabet_list_view/alphabet_list_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:notepadclient/core/domain/Contact.dart';
import 'package:notepadclient/core/domain/ContactRequest.dart';
import 'package:notepadclient/features/contact/pages/GroupListPage.dart';
import 'package:notepadclient/features/contact/pages/NewContactPage.dart';

import '../../../shared/widgets/AvatarWidget.dart';
import '../pages/ContactDetailPage.dart';

class ContactController extends ChangeNotifier {
  ///联系人列表数据
  List<Contact> contactList = [];
  List<ContactRequest> contactRequestList = [];
  var ContactDetail = ValueNotifier<Contact>(Contact());

  ///选中的联系人ID
  num? _selectedContactId = -1;

  num? get selectedContactId => _selectedContactId;

  List<AlphabetListViewItemGroup> buildContactGroups() {
    final Map<String, List<Widget>> grouped = {};

    for (var contact in contactList) {
      final name = contact.contactUser?.nickName ?? '';
      final avatar = contact.contactUser?.avatar ?? '';
      final id = contact.contactId ?? -2;
      // 转拼音
      String pinyin = PinyinHelper.getPinyinE(
        name,
        separator: '',
        defPinyin: '#',
      );

      // 首字母
      String tag = '#';
      if (pinyin.isNotEmpty) {
        final first = pinyin[0].toUpperCase();
        tag = RegExp(r'^[A-Z]$').hasMatch(first) ? first : '#';
      }

      grouped
          .putIfAbsent(tag, () => [])
          .add(
            ListTile(
              leading: AvatarWidget(size: 30, url: avatar, name: name),
              title: Text(name.isNotEmpty ? name : '(未命名用户)'),
              onTap: () {
                _selectedContactId = id;
                _selectedIndex = 2;
                ContactDetail.value = contact;
                notifyListeners();
              },
              selected: selectedContactId == id,
            ),
          );
    }

    // 排序分组：A-Z 再到 #
    final sortedKeys = grouped.keys.toList()..sort();
    if (sortedKeys.remove('#')) sortedKeys.add('#');

    return sortedKeys
        .map(
          (tag) => AlphabetListViewItemGroup(tag: tag, children: grouped[tag]!),
        )
        .toList();
  }

  ///选中的功能项
  int _selectedIndex = -1;

  int get selectedIndex => _selectedIndex;

  set selectedIndex(int index) {
    _selectedIndex = index;
    _selectedContactId = -1;
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
