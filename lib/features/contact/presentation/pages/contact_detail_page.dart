import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/BubbleDialog.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/features/contact/presentation/widgets/contact_detail_widgets.dart';
import 'package:anoxia/framework/domain/ChatContactDetailVO.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/contact/contact_detail_controller.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/provider/contact/contact_selection_controller.dart';
import 'package:anoxia/framework/provider/layout/layout_controller.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

class ContactDetail extends ConsumerWidget {
  const ContactDetail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(contactSelectionProvider);
    final contact = selection.selectedContact;

    if (selection.viewType != ContactViewType.contactDetail ||
        contact == null) {
      return const ContactDetailEmptyState();
    }

    final isOnline = ref.watch(
      contactListServiceProvider.select(
        (asyncMap) => asyncMap.value?[contact.contactId]?.onlineStatus ?? false,
      ),
    );
    final detailAsync = ref.watch(
      contactDetailDataProvider(contact.contactId!),
    );

    return Scaffold(
      backgroundColor: DeviceUtil.isRealDesktop()
          ? Colors.transparent
          : Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        actionsPadding: const EdgeInsets.symmetric(horizontal: 8),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () {
                  Function? close;
                  close = Toast.showWidget(
                    context,
                    direction: PreferDirection.rightTop,
                    child: Material(
                      color: Colors.transparent,
                      child: BubbleWidget(
                        arrowDirection: AxisDirection.right,
                        arrowOffset: 25,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        border: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          width: 0.5,
                        ),
                        contentBuilder: (context) => Container(
                          constraints: const BoxConstraints(
                            maxWidth: 200,
                            maxHeight: 400,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedEdit01,
                                  size: 20,
                                ),
                                title: Text('contact_edit_remark'.tr()),
                                onTap: () async {
                                  close?.call();
                                  await _showEditRemarkDialog(
                                    context,
                                    ref,
                                    contact.contactId!,
                                    detailAsync.asData?.value.remark,
                                  );
                                },
                                dense: true,
                              ),
                              ListTile(
                                dense: true,
                                leading: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedDelete01,
                                  size: 20,
                                ),
                                title: Text('contact_delete'.tr()),
                                onTap: () async {
                                  close?.call();
                                  await _showDeleteConfirmDialog(
                                    context,
                                    ref,
                                    contact.contactId!,
                                    detailAsync.asData?.value.nickName,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.more_horiz),
              );
            },
          ),
        ],
      ),
      body: detailAsync.when(
        data: (detail) => _buildDetailContent(context, detail, isOnline, ref),
        loading: () => const ContactDetailSkeleton(),
        error: (err, _) => Center(
          child: Text(
            'contact_load_failed_with_error'.tr(args: [err.toString()]),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailContent(
    BuildContext context,
    ChatContactDetailVO detail,
    bool isOnline,
    WidgetRef ref,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCreating = ref.watch(contactChatLoadingProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                AvatarWidget(
                  url: detail.avatar,
                  name: detail.nickName,
                  size: 100,
                  borderRadius: 12,
                ),
                const SizedBox(height: 16),
                Text(
                  detail.nickName ?? '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          ContactInfoTile(
            label: 'contact_status'.tr(),
            value: isOnline ? 'contact_online'.tr() : 'contact_offline'.tr(),
          ),
          ContactInfoTile(
            label: 'contact_remark'.tr(),
            value: detail.remark ?? 'contact_no_remark'.tr(),
          ),
          ContactInfoTile(
            label: 'contact_username'.tr(),
            value: detail.userName ?? '',
          ),
          ContactInfoTile(
            label: 'contact_gender'.tr(),
            value: _getTranslatedGender(detail.sex),
          ),
          ContactInfoTile(
            label: 'contact_phone'.tr(),
            value: detail.phoneNumber ?? 'contact_no_phone'.tr(),
          ),
          ContactInfoTile(
            label: 'contact_became_friends'.tr(),
            value: detail.formattedDate,
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isCreating
                        ? null
                        : () async {
                            final targetId = detail.userId;
                            if (targetId == null) return;

                            ref
                                .read(contactChatLoadingProvider.notifier)
                                .set(true);

                            try {
                              final roomId = await ref
                                  .read(roomListServiceProvider.notifier)
                                  .getOrCreateRoom(detail.userId!);

                              if (roomId != null) {
                                ref
                                    .read(activeRoomIdProvider.notifier)
                                    .setActive(roomId);
                                ref
                                    .read(layoutControllerProvider.notifier)
                                    .setIndex(0);
                              }
                            } finally {
                              ref
                                  .read(contactChatLoadingProvider.notifier)
                                  .set(false);
                            }
                          },
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedChatting01,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: isCreating
                        ? const CircularProgressIndicator()
                        : Text('chat_send_message'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTranslatedGender(String? sex) {
    switch (sex) {
      case '0':
        return 'contact_male'.tr();
      case '1':
        return 'contact_female'.tr();
      default:
        return 'contact_unknown_gender'.tr();
    }
  }

  Future<void> _showEditRemarkDialog(
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('contact_edit_remark'.tr()),
          content: TextField(
            controller: controller,
            maxLength: 30,
            decoration: InputDecoration(
              hintText: 'contact_edit_remark'.tr(),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
    if (result == null) return;

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
        );
        return;
      }

      ref.invalidate(contactDetailDataProvider(contactId));
      await ref.read(contactListServiceProvider.notifier).refresh(quiet: true);
      _syncSelectedContact(ref, contactId);
      Toast.showToast(
        'contact_edit_remark_success'.tr(),
        type: ToastType.success,
      );
    } catch (_) {
      Toast.showToast('contact_edit_remark_failed'.tr(), type: ToastType.error);
    }
  }

  Future<void> _showDeleteConfirmDialog(
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

    if (confirm != true) return;

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
        return;
      }

      ref.invalidate(contactDetailDataProvider(contactId));
      await ref.read(contactListServiceProvider.notifier).refresh(quiet: true);
      ref.read(contactSelectionProvider.notifier).clearSelection();
      Toast.showToast('contact_delete_success'.tr(), type: ToastType.success);
    } catch (_) {
      Toast.showToast('contact_delete_failed'.tr(), type: ToastType.error);
    }
  }

  void _syncSelectedContact(WidgetRef ref, int contactId) {
    final contactMap = ref.read(contactListServiceProvider).value;
    final latest = contactMap?[contactId];
    if (latest != null) {
      ref.read(contactSelectionProvider.notifier).selectContact(latest);
    }
  }
}
