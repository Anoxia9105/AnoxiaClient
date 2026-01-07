import 'package:flutter/material.dart';
import 'package:notepadclient/features/contact/controller/ContactController.dart';

///加入群右侧页面
///
/// 作者: anoxia
///
/// 日期: 2025/10/30 下午1:51
///
class GroupListPage extends StatefulWidget {
  final ContactController controller;
  const GroupListPage({super.key, required this.controller});

  @override
  State<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage> {
  @override
  Widget build(BuildContext context) {
    return Text("群列表");
  }
}
