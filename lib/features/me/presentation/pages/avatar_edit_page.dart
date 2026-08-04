import 'dart:math' as math;

import 'package:anoxia/common/utils/device_util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../widgets/avatar_edit_flow.dart';

/// 移动端头像上传页面
///
/// 手机端点击「我的」页面头像栏跳转到此页面，包含图片选择、预览裁剪与上传。
class AvatarEditPage extends StatelessWidget {
  const AvatarEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final editorSize = math.min(340.0, screenWidth - 32);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        centerTitle: DeviceUtil.isRealMobile(),
        title: Text('me_avatar_upload_title'.tr()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: AvatarEditFlow(
            editorSize: editorSize,
            onDone: (ok) async {
              if (context.mounted) Navigator.of(context).pop(ok);
            },
          ),
        ),
      ),
    );
  }
}
