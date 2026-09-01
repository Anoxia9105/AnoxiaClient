import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 显示编辑备注对话框并处理保存
///
/// 返回 `true` 表示保存成功
Future<bool> showContactEditRemarkDialog(
  BuildContext context,
  WidgetRef ref,
  int contactId,
  String? initialRemark,
) async {
  final controller = TextEditingController(text: initialRemark ?? '');

  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      final colorScheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.xl)),
        title: Text('contact_edit_remark'.tr()),
        content: TextField(
          controller: controller,
          maxLength: 100,
          decoration: InputDecoration(
            hintText: 'contact_edit_remark'.tr(),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.35,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RadiusToken.lg),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RadiusToken.lg),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RadiusToken.lg),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('dialog_cancel'.tr()),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text('chat_confirm_btn'.tr()),
          ),
        ],
      );
    },
  );

  controller.dispose();
  if (result == null) return false;

  try {
    final encodedRemark = Uri.encodeComponent(result);
    final response = await DioClient().put(
      '${API.contactRemarkUpdate}?contactId=$contactId&remark=$encodedRemark',
    );

    final ok = response.data is Map && response.data['code'] == 200;
    if (!ok) {
      final msg = response.data is Map
          ? response.data['msg']?.toString()
          : null;
      Toast.showToast(
        msg?.isNotEmpty == true ? msg! : 'chat_operation_retry_failed'.tr(),
        type: ToastType.error,
      );
      return false;
    }

    Toast.showToast(
      'contact_edit_remark_success'.tr(),
      type: ToastType.success,
    );
    return true;
  } catch (_) {
    Toast.showToast('contact_edit_remark_failed'.tr(), type: ToastType.error);
    return false;
  }
}
