import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/common/widgets/dialogs/danger_confirm_dialog.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/provider/contact/private_contact_access.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

class BlockedContactsPage extends ConsumerWidget {
  const BlockedContactsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text('contact_blocked_list'.tr())),
      body: ref
          .watch(blockedContactsProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(blockedContactsProvider),
                child: Text('retry'.tr()),
              ),
            ),
            data: (contacts) => contacts.isEmpty
                ? Center(child: Text('contact_blocked_empty'.tr()))
                : ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      final id = contact.contactId;
                      return ListTile(
                        leading: AvatarWidget(
                          url: contact.avatar,
                          name: contact.nickName,
                        ),
                        title: Text(
                          contact.nickName ?? 'chat_unknown_user'.tr(),
                        ),
                        trailing: TextButton(
                          onPressed: id == null
                              ? null
                              : () => changeContactBlock(
                                  context,
                                  ref,
                                  id,
                                  blocked: false,
                                ),
                          child: Text('contact_unblock'.tr()),
                        ),
                      );
                    },
                  ),
          ),
    );
  }
}

Future<void> changeContactBlock(
  BuildContext context,
  WidgetRef ref,
  int contactId, {
  required bool blocked,
}) async {
  if (blocked) {
    final confirmed = await showDangerConfirmDialog(
      context,
      icon: HugeIcons.strokeRoundedCancel01,
      title: 'contact_block'.tr(),
      content: 'contact_block_confirm'.tr(),
      confirmLabel: 'contact_block'.tr(),
    );
    if (!confirmed || !context.mounted) return;
  }
  try {
    await setContactBlocked(contactId, blocked: blocked);
  } catch (_) {
    if (!context.mounted) return;
    Toast.showToast('chat_operation_retry_failed'.tr(), type: ToastType.error);
    return;
  }

  if (!context.mounted) return;
  ref.invalidate(privateContactAccessProvider(contactId));
  ref.invalidate(blockedContactsProvider);
  final contacts = ref.read(contactListServiceProvider.notifier);
  if (blocked) {
    try {
      await contacts.removeContact(contactId);
    } catch (_) {
      await contacts.refresh(quiet: true);
    }
  } else {
    await contacts.refresh(quiet: true);
  }
  if (!context.mounted) return;
  Toast.showToast(
    (blocked ? 'contact_blocked_success' : 'contact_unblocked_success').tr(),
    type: ToastType.success,
  );
}
