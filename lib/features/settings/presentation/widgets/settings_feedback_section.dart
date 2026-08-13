import 'package:anoxia/domain/repositories/settings_repository.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 设置页的问题反馈表单。
class SettingsFeedbackSection extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final TextEditingController contactController;
  final List<FeedbackImageAttachment> images;
  final bool submitting;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveImage;
  final VoidCallback onSubmit;

  const SettingsFeedbackSection({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.contentController,
    required this.contactController,
    required this.images,
    required this.submitting,
    required this.onPickImages,
    required this.onRemoveImage,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedBulb,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'settings_feedback_intro_title'.tr(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'settings_feedback_intro_body'.tr(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            key: const ValueKey('feedback-subject-field'),
            controller: titleController,
            textInputAction: TextInputAction.next,
            maxLength: 200,
            decoration: _fieldDecoration(
              context,
              label: 'settings_feedback_subject'.tr(),
              hint: 'settings_feedback_subject_hint'.tr(),
              icon: HugeIcons.strokeRoundedMessage01,
            ),
            validator: (value) => (value ?? '').trim().isEmpty
                ? 'settings_feedback_subject_required'.tr()
                : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey('feedback-content-field'),
            controller: contentController,
            minLines: 5,
            maxLines: 9,
            maxLength: 4000,
            decoration: _fieldDecoration(
              context,
              label: 'settings_feedback_content'.tr(),
              hint: 'settings_feedback_content_hint'.tr(),
              icon: HugeIcons.strokeRoundedFileAttachment,
              alignLabelWithHint: true,
            ),
            validator: (value) => (value ?? '').trim().isEmpty
                ? 'settings_feedback_content_required'.tr()
                : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: contactController,
            textInputAction: TextInputAction.done,
            maxLength: 120,
            decoration: _fieldDecoration(
              context,
              label: 'settings_feedback_contact'.tr(),
              hint: 'settings_feedback_contact_hint'.tr(),
              icon: HugeIcons.strokeRoundedMail01,
            ),
          ),
          const SizedBox(height: 10),
          _ImagePickerArea(
            images: images,
            enabled: !submitting,
            onPickImages: onPickImages,
            onRemoveImage: onRemoveImage,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const ValueKey('feedback-submit-button'),
            onPressed: submitting ? null : onSubmit,
            icon: submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const HugeIcon(
                    icon: HugeIcons.strokeRoundedSent,
                    color: Colors.white,
                    size: 20,
                  ),
            label: Text(
              submitting
                  ? 'settings_feedback_submitting'.tr()
                  : 'settings_feedback_submit'.tr(),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    required List<List<dynamic>> icon,
    bool alignLabelWithHint = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: Padding(
        padding: const EdgeInsets.all(13),
        child: HugeIcon(
          icon: icon,
          color: colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }
}

class _ImagePickerArea extends StatelessWidget {
  final List<FeedbackImageAttachment> images;
  final bool enabled;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveImage;

  const _ImagePickerArea({
    required this.images,
    required this.enabled,
    required this.onPickImages,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'settings_feedback_images'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${images.length}/3',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'settings_feedback_images_helper'.tr(),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        if (images.isNotEmpty) ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var index = 0; index < images.length; index++)
                _ImagePreview(
                  image: images[index],
                  index: index,
                  enabled: enabled,
                  onRemove: () => onRemoveImage(index),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (images.length < 3)
          OutlinedButton.icon(
            key: const ValueKey('feedback-pick-images-button'),
            onPressed: enabled ? onPickImages : null,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedImageAdd01,
              size: 20,
            ),
            label: Text('settings_feedback_images_add'.tr()),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: BorderSide(color: colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final FeedbackImageAttachment image;
  final int index;
  final bool enabled;
  final VoidCallback onRemove;

  const _ImagePreview({
    required this.image,
    required this.index,
    required this.enabled,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: image.name,
      image: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              image.bytes,
              key: ValueKey('feedback-image-$index'),
              width: 112,
              height: 88,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 112,
                height: 88,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          Positioned(
            right: -8,
            top: -8,
            child: IconButton.filled(
              key: ValueKey('feedback-remove-image-$index'),
              tooltip: 'settings_feedback_image_remove'.tr(args: [image.name]),
              onPressed: enabled ? onRemove : null,
              icon: const Icon(Icons.close, size: 18),
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
