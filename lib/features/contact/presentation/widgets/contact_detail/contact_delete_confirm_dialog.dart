import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 显示删除联系人确认对话框并执行删除
///
/// 返回 `true` 表示删除成功
Future<bool> showContactDeleteConfirmDialog(
  BuildContext context,
  WidgetRef ref,
  int contactId,
  String? nickName,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colorScheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('contact_delete'.tr()),
        content: Text(
          'contact_delete_confirm_content'.tr(args: [nickName ?? '']),
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('dialog_cancel'.tr()),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('chat_confirm_btn'.tr()),
          ),
        ],
      );
    },
  );

  if (confirm != true) return false;

  try {
    final response = await DioClient().delete(
      '${API.contactDelete}?contactId=$contactId',
    );

    final ok = response.data is Map && response.data['code'] == 200;
    if (!ok) {
      final msg = response.data is Map
          ? response.data['msg']?.toString()
          : null;
      Toast.showToast(
        msg?.isNotEmpty == true ? msg! : 'chat_operation_retry_failed'.tr(),
      );
      return false;
    }

    Toast.showToast(
      'contact_delete_success'.tr(),
      type: ToastType.success,
    );
    return true;
  } catch (_) {
    Toast.showToast('contact_delete_failed'.tr(), type: ToastType.error);
    return false;
  }
}
