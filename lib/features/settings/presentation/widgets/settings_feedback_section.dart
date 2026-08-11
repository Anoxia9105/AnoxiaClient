import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';

import 'settings_item_card.dart';

/// 反馈意见组件
///
/// 提供用户反馈提交表单，包含标题、内容和联系方式字段
class SettingsFeedbackSection extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final TextEditingController contactController;
  final bool submitting;
  final VoidCallback onSubmit;

  const SettingsFeedbackSection({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.contentController,
    required this.contactController,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SettingItemCard(
      title: 'settings_feedback_title'.tr(),
      subtitle: 'settings_feedback_subtitle'.tr(),
      icon: HugeIcons.strokeRoundedMessage02,
      child: Form(
        key: formKey,
        child: Column(
          children: [
            TextFormField(
              controller: titleController,
              decoration: _fieldDecoration(
                context,
                'settings_feedback_subject'.tr(),
              ),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) {
                  return 'settings_feedback_subject_required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: contentController,
              minLines: 4,
              maxLines: 8,
              decoration: _fieldDecoration(
                context,
                'settings_feedback_content'.tr(),
                alignLabelWithHint: true,
              ),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) {
                  return 'settings_feedback_content_required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: contactController,
              decoration: _fieldDecoration(
                context,
                'settings_feedback_contact'.tr(),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 140,
                child: FilledButton(
                  onPressed: submitting ? null : onSubmit,
                  child: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('settings_feedback_submit'.tr()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(
    BuildContext context,
    String hint, {
    bool alignLabelWithHint = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.error, width: 1.4),
      ),
    );
  }
}
