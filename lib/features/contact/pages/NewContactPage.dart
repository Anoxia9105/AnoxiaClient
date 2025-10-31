import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:notepadclient/core/utils/DateUtil.dart';
import 'package:notepadclient/features/contact/controller/ContactController.dart';
import 'package:notepadclient/shared/widgets/NoData.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/AvatarWidget.dart';

///右侧新的朋友申请页面
///
/// 作者: anoxia
///
/// 日期: 2025/10/30 下午1:52
///
class NewContactPage extends StatefulWidget {
  const NewContactPage({super.key});

  @override
  State<NewContactPage> createState() => _NewContactPageState();
}

class _NewContactPageState extends State<NewContactPage> {
  @override
  Widget build(BuildContext context) {
    ColorScheme theme = Theme.of(context).colorScheme;
    final contactRequestList = context
        .read<ContactController>()
        .contactRequestList;

    if (contactRequestList.isEmpty) {
      return NoData(
        iconData: HugeIcons.strokeRoundedAddTeam,
        title: "没有新的好友申请",
      );
    }
    return ListView.separated(
      itemCount: contactRequestList.length,
      itemBuilder: (context, index) {
        var result = contactRequestList[index];
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: AvatarWidget(
                  size: 40,
                  url: result.requestUser?.avatar ?? '',
                  name: result.requestUser?.nickName ?? '',
                ),
                title: Text(

                  style: TextStyle(fontSize: 18),
                  result.requestUser?.nickName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  style: TextStyle(fontSize: 12,color:theme.onSurface ),
                  DateUtil.formatIsoDate(result.createdAt ?? '', pattern: "MM/dd HH:mm"),
                ),
                trailing: switch (result.status) {
                  0 => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          //TODO: 拒绝
                        },
                        child: Text("拒绝"),
                      ),
                      TextButton(
                        onPressed: () {
                          //TODO: 接受
                        },
                        child: Text("同意"),
                      ),
                    ],
                  ),
                  _ => TextButton(
                    onPressed: () {
                      //TODO: 接受
                    },
                    child: Text("接受"),
                  ),
                },
              ),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.primaryContainer.withValues(alpha: 0.7),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "申请理由: ${result.remark}",
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return Divider();
      },
    );
  }
}
