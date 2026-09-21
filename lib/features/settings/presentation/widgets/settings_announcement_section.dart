import 'package:anoxia/features/announcement/presentation/widgets/announcement_dialog.dart';
import 'package:anoxia/framework/domain/announcement.dart';
import 'package:anoxia/framework/provider/announcement/announcement_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';

class SettingsAnnouncementSection extends ConsumerWidget {
  const SettingsAnnouncementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementControllerProvider);
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('announcement_load_error'.tr()),
            const SizedBox(height: SpacingToken.md),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(announcementControllerProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: Text('announcement_retry'.tr()),
            ),
          ],
        ),
      );
    }
    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('announcement_empty'.tr()),
            TextButton(
              onPressed: () =>
                  ref.read(announcementControllerProvider.notifier).refresh(),
              child: Text('announcement_refresh'.tr()),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: 'announcement_refresh'.tr(),
            onPressed: state.loading
                ? null
                : () => ref
                      .read(announcementControllerProvider.notifier)
                      .refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ),
        for (final item in state.items)
          Card(
            child: ListTile(
              leading: Icon(
                item.level == AnnouncementLevel.required
                    ? Icons.priority_high
                    : Icons.campaign_outlined,
              ),
              title: Text(item.title),
              subtitle: Text(
                item.level == AnnouncementLevel.required
                    ? (item.acknowledged
                          ? 'announcement_acknowledged'.tr()
                          : 'announcement_required_pending'.tr())
                    : (item.read
                          ? 'announcement_read'.tr()
                          : 'announcement_unread'.tr()),
              ),
              onTap: () => _showDetail(context, ref, item),
            ),
          ),
      ],
    );
  }

  Future<void> _showDetail(
    BuildContext context,
    WidgetRef ref,
    Announcement item,
  ) async {
    final required = item.level == AnnouncementLevel.required;
    final route = AnnouncementDialog.buildRoute(
      context,
      (dialogContext) => AnnouncementDialog(
        announcement: item,
        onClose: () => Navigator.of(dialogContext).pop(),
        onAcknowledge: () =>
            ref.read(announcementControllerProvider.notifier).acknowledge(item),
      ),
      dismissible: !required,
    );
    await Navigator.of(context).push(route);
    if (!required && context.mounted) {
      await ref.read(announcementControllerProvider.notifier).markRead(item);
    }
  }
}
