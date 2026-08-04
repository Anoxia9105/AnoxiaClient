import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../widgets/avatar_edit_flow.dart';

/// 桌面端头像上传对话框
///
/// 点击「我的」页面头像栏弹出，包含图片选择、预览裁剪与上传。
class AvatarEditDialog extends StatelessWidget {
  const AvatarEditDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final editorSize = math.min(
      320.0,
      MediaQuery.of(context).size.width * 0.8,
    );
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.account_circle_outlined, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(child: Text('me_avatar_upload_title'.tr())),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: AvatarEditFlow(
          editorSize: editorSize,
          onDone: (ok) async {
            if (context.mounted) Navigator.of(context).pop(ok);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('dialog_cancel'.tr()),
        ),
      ],
    );
  }
}
