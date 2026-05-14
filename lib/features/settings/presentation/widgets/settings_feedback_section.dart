import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'settings_item_card.dart';

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'settings_feedback_subject'.tr(),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) {
                    return 'settings_feedback_subject_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: contentController,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: 'settings_feedback_content'.tr(),
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) {
                    return 'settings_feedback_content_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: contactController,
                decoration: InputDecoration(
                  labelText: 'settings_feedback_contact'.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: submitting ? null : onSubmit,
                  icon: submitting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.bug_report_outlined, size: 18),
                  label: Text('settings_feedback_submit'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
