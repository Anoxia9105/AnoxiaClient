import 'package:anoxia/framework/domain/announcement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class AnnouncementDialog extends StatefulWidget {
  const AnnouncementDialog({
    super.key,
    required this.announcement,
    required this.onClose,
    required this.onAcknowledge,
  });

  final Announcement announcement;
  final VoidCallback onClose;
  final Future<bool> Function() onAcknowledge;

  @override
  State<AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<AnnouncementDialog> {
  bool _submitting = false;
  String? _error;

  Future<void> _acknowledge() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final success = await widget.onAcknowledge();
    if (!mounted) return;
    if (success) {
      widget.onClose();
      return;
    }
    setState(() {
      _submitting = false;
      _error = 'announcement_ack_error'.tr();
    });
  }

  @override
  Widget build(BuildContext context) {
    final required = widget.announcement.level == AnnouncementLevel.required;
    return PopScope(
      canPop: !required,
      child: AlertDialog(
        title: Text(widget.announcement.title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(widget.announcement.content),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    key: const Key('announcement-ack-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (!required)
            TextButton(
              key: const Key('announcement-close'),
              onPressed: widget.onClose,
              child: Text('announcement_close'.tr()),
            )
          else
            FilledButton(
              key: const Key('announcement-acknowledge'),
              onPressed: _submitting ? null : _acknowledge,
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('announcement_acknowledge'.tr()),
            ),
        ],
      ),
    );
  }
}
