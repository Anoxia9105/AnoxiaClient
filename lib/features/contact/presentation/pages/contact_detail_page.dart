import 'package:anoxia/features/contact/presentation/widgets/contact_detail/contact_delete_confirm_dialog.dart';
import 'package:anoxia/features/contact/presentation/widgets/contact_detail/contact_detail_actions.dart';
import 'package:anoxia/features/contact/presentation/widgets/contact_detail/contact_detail_empty_state.dart';
import 'package:anoxia/features/contact/presentation/widgets/contact_detail/contact_detail_header.dart';
import 'package:anoxia/features/contact/presentation/widgets/contact_detail/contact_detail_popup_menu.dart';
import 'package:anoxia/features/contact/presentation/widgets/contact_detail/contact_detail_skeleton.dart';
import 'package:anoxia/features/contact/presentation/widgets/contact_detail/contact_edit_remark_dialog.dart';
import 'package:anoxia/features/contact/presentation/widgets/contact_detail/contact_info_section.dart';
import 'package:anoxia/framework/provider/contact/contact_detail_controller.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/provider/contact/contact_selection_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 联系人详情页面
///
/// 显示联系人的详细信息，支持查看资料、编辑备注、删除联系人、发起聊天和推荐名片。
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        actionsPadding: const EdgeInsets.symmetric(horizontal: 8),
        actions: [
          ContactDetailPopupMenuButton(
            onEditRemark: () => _handleEditRemark(
              context,
              ref,
              contact.contactId!,
              detailAsync.asData?.value.remark,
            ),
            onDelete: () => _handleDelete(
              context,
              ref,
              contact.contactId!,
              detailAsync.asData?.value.nickName,
            ),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (detail) => SingleChildScrollView(
          child: Column(
            children: [
              ContactDetailHeader(
                avatar: detail.avatar,
                nickName: detail.nickName,
                remark: detail.remark,
                isOnline: isOnline,
              ),
              ContactInfoSection(detail: detail, isOnline: isOnline),
              const SizedBox(height: SpacingToken.xl),
              ContactDetailActions(detail: detail),
              const SizedBox(height: SpacingToken.lg),
            ],
          ),
        ),
        loading: () => const ContactDetailSkeleton(),
        error: (err, _) => Center(
          child: Text(
            'contact_load_failed_with_error'.tr(args: [err.toString()]),
          ),
        ),
      ),
    );
  }

  Future<void> _handleEditRemark(
    BuildContext context,
    WidgetRef ref,
    int contactId,
    String? initialRemark,
  ) async {
    final success = await showContactEditRemarkDialog(
      context,
      ref,
      contactId,
      initialRemark,
    );
    if (!success) return;

    ref.invalidate(contactDetailDataProvider(contactId));
    await ref.read(contactListServiceProvider.notifier).refresh(quiet: true);
    _syncSelectedContact(ref, contactId);
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    int contactId,
    String? nickName,
  ) async {
    final success = await showContactDeleteConfirmDialog(
      context,
      ref,
      contactId,
      nickName,
    );
    if (!success) return;

    ref.invalidate(contactDetailDataProvider(contactId));
    await ref.read(contactListServiceProvider.notifier).refresh(quiet: true);
    ref.read(contactSelectionProvider.notifier).clearSelection();
  }

  void _syncSelectedContact(WidgetRef ref, int contactId) {
    final contactMap = ref.read(contactListServiceProvider).value;
    final latest = contactMap?[contactId];
    if (latest != null) {
      ref.read(contactSelectionProvider.notifier).selectContact(latest);
    }
  }
}