import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 好友请求状态操作按钮
///
/// 根据请求状态展示同意/拒绝按钮或已处理文字
class NewFriendsStatusButtons extends StatelessWidget {
  final int? status;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const NewFriendsStatusButtons({
    super.key,
    required this.status,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();

    if (status == 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'contact_accept'.tr(),
            onPressed: onAccept,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 3,
            ),
          ),
          IconButton(
            tooltip: 'contact_reject'.tr(),
            onPressed: onReject,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCancelCircle,
              color: Colors.red,
              strokeWidth: 3,
            ),
          ),
        ],
      );
    }

    if (status == 1) {
      return Text('contact_request_accepted'.tr());
    }

    return Text('contact_request_rejected'.tr());
  }
}
