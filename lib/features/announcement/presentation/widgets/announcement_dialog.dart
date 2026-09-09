import 'package:anoxia/framework/domain/announcement.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final required = widget.announcement.level == AnnouncementLevel.required;
    // 公告级别徽标：普通用主题强调色，强制确认用错误色，保证明/暗主题与自定义强调色下均可读。
    final badgeColor = required
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;
    final badgeIconColor = required
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;
    return PopScope(
      canPop: !required,
      child: AlertDialog(
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(RadiusToken.lg),
              ),
              child: HugeIcon(
                icon: required
                    ? HugeIcons.strokeRoundedAlertCircle
                    : HugeIcons.strokeRoundedMegaphone01,
                size: 22,
                color: badgeIconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.announcement.title)),
          ],
        ),
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
