import 'dart:convert';
import 'dart:io';

import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/protocol/message/MessagePayload.dart';
import 'package:anoxia/framework/provider/chat/input/UploadValidator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class CardBox extends StatefulWidget {
  final ValueChanged<CardPayload> onSubmit;
  final VoidCallback? onCancel;

  const CardBox({super.key, required this.onSubmit, this.onCancel});

  @override
  State<CardBox> createState() => _CardBoxState();
}

class _CardBoxState extends State<CardBox> {
  static const _cardTypes = [
    'LINK',
    'USER',
    'GROUP',
    'FILE',
    'IMAGE',
    'CUSTOM',
  ];

  String _cardType = _cardTypes.first;
  bool _isUploading = false;

  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _thumbnailController = TextEditingController();
  final _propertiesController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _thumbnailController.dispose();
    _propertiesController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadThumbnail() async {
    if (_isUploading) return;

    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      type: FileType.image,
    );
    final picked = result?.files.firstOrNull;
    if (picked == null || picked.path == null) return;
    if (!UploadValidator.validateSingleFile(picked)) return;

    setState(() => _isUploading = true);
    try {
      final res = await DioClient().uploadFiles(
        '/file/uploadBatch',
        files: [File(picked.path!)],
      );
      final rawList = res.data is Map ? res.data['data'] : res.data;
      if (rawList is List && rawList.isNotEmpty) {
        _thumbnailController.text = rawList.first.toString();
        return;
      }
      Toast.showToast('card_thumbnail_upload_failed'.tr());
    } catch (_) {
      Toast.showToast('card_thumbnail_upload_failed'.tr());
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final properties = _parseProperties();
    if (properties == null) return;

    widget.onSubmit(
      CardPayload(
        cardType: _cardType,
        title: title,
        summary: _emptyToNull(_summaryController.text),
        thumbnailUrl: _emptyToNull(_thumbnailController.text),
        properties: properties,
      ),
    );
  }

  Map<String, String>? _parseProperties() {
    final raw = _propertiesController.text.trim();
    if (raw.isEmpty) return const {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
        );
      }
    } catch (_) {
      // Fall through to the toast below.
    }

    Toast.showToast('card_properties_invalid'.tr());
    return null;
  }

  String? _emptyToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'toolbar_card'.tr(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _cardType,
              decoration: InputDecoration(
                labelText: 'card_type_label'.tr(),
                isDense: true,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
              ),
              items: _cardTypes
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text('card_type_$type'.tr()),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _cardType = value);
              },
            ),
            const SizedBox(height: 8),
            _Input(
              controller: _titleController,
              label: 'card_title_label'.tr(),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            _Input(
              controller: _summaryController,
              label: 'card_summary_label'.tr(),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Input(
                    controller: _thumbnailController,
                    label: 'card_thumbnail_label'.tr(),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : _pickAndUploadThumbnail,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_rounded, size: 16),
                    label: Text(
                      _isUploading
                          ? 'card_thumbnail_uploading'.tr()
                          : 'card_thumbnail_upload'.tr(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _Input(
              controller: _propertiesController,
              label: 'card_properties_label'.tr(),
              maxLines: 2,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isUploading ? null : widget.onCancel,
                  child: Text('dialog_cancel'.tr()),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  onPressed: _isUploading ? null : _submit,
                  child: Text('toolbar_send'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final bool readOnly;
  final int maxLines;
  final ValueChanged<String>? onSubmitted;

  const _Input({
    required this.controller,
    required this.label,
    this.autofocus = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      readOnly: readOnly,
      maxLines: maxLines,
      onSubmitted: onSubmitted,
      textInputAction: maxLines == 1 ? TextInputAction.next : null,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      ),
    );
  }
}
