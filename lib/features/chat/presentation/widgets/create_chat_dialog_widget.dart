import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/features/contact/presentation/widgets/sorted_contact_groups_widget.dart';
import 'package:anoxia/framework/provider/chat/room/create_new_gropu_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateChatDialogWidget extends ConsumerStatefulWidget {
  const CreateChatDialogWidget({super.key});

  @override
  ConsumerState<CreateChatDialogWidget> createState() =>
      _CreateChatDialogWidgetState();
}

class _CreateChatDialogWidgetState
    extends ConsumerState<CreateChatDialogWidget> {
  final _nameController = TextEditingController();
  bool _isNameEmpty = true;
  bool _showNameError = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      final isEmpty = _nameController.text.trim().isEmpty;
      if (isEmpty != _isNameEmpty) {
        setState(() => _isNameEmpty = isEmpty);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIds = ref.watch(selectedContactIdsProvider);
    final createStatus = ref.watch(createGroupControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      child: SizedBox(
        width: 900,
        height: 650,
        child: Column(
          children: [
            _buildAppBar(context, selectedIds, createStatus),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: TextField(
                controller: _nameController,
                style: textTheme.bodyLarge,
                onTap: () {
                  if (_showNameError) {
                    setState(() => _showNameError = false);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'create_group_name_hint'.tr(),
                  errorText: (_showNameError && _isNameEmpty)
                      ? 'create_group_name_empty'.tr()
                      : null,
                  helperText: ' ',
                  helperStyle: const TextStyle(height: 0.8),
                  isDense: true,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.35,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.edit_note_rounded,
                    color: colorScheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.8),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 10, 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.65,
                              ),
                            ),
                          ),
                          child: _buildContactPicker(ref),
                        ),
                      ),
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildSelectedPreview(context, ref, selectedIds),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    Set<int> selectedIds,
    AsyncValue createStatus,
  ) {
    final isLoading = createStatus is AsyncLoading;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'create_group_title'.tr(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('dialog_cancel'.tr()),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed:
                (selectedIds.isEmpty ||
                    isLoading ||
                    _nameController.text.isEmpty)
                ? null
                : _submit,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('${'dialog_done'.tr()} (${selectedIds.length})'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _showNameError = true);
      return;
    }

    ref
        .read(createGroupControllerProvider.notifier)
        .createGroup(
          name: name,
          userIds: ref.read(selectedContactIdsProvider).toList(),
          onSuccess: () async {
            await ref
                .read(roomListServiceProvider.notifier)
                .refresh(silent: true);

            final newRoom = ref.read(createGroupControllerProvider).value;

            if (context.mounted) {
              if (newRoom?.roomId != null) {
                ref
                    .read(activeRoomIdProvider.notifier)
                    .setActive(newRoom!.roomId!);
              }
              ref.read(selectedContactIdsProvider.notifier).clear();
              Toast.showToast(
                'create_group_success'.tr(),
                type: ToastType.success,
              );
              if (mounted) {
                Navigator.pop(context);
              }
            }
          },
        );
  }

  Widget _buildSelectedPreview(
    BuildContext context,
    WidgetRef ref,
    Set<int> selectedIds,
  ) {
    final contactMap = ref.watch(contactListServiceProvider).value ?? {};
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'create_group_selected_count'.tr(
                args: [selectedIds.length.toString()],
              ),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: selectedIds.isEmpty
                ? Center(
                    child: Text(
                      'chat_no_conversations'.tr(),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 4),
                    itemCount: selectedIds.length,
                    itemBuilder: (context, index) {
                      final id = selectedIds.elementAt(index);
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: colorScheme.surface,
                        leading: AvatarWidget(
                          url: contactMap[id]?.avatar,
                          name: contactMap[id]?.nickName,
                        ),
                        title: Text(
                          '${contactMap[id]?.nickName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => ref
                              .read(selectedContactIdsProvider.notifier)
                              .remove(id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactPicker(WidgetRef ref) {
    return SortedContactGroupsWidget(
      itemBuilder: (vo) {
        final selectedIds = ref.watch(selectedContactIdsProvider);
        final checked = selectedIds.contains(vo.contactId);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          child: CheckboxListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
            value: checked,
            onChanged: (_) => ref
                .read(selectedContactIdsProvider.notifier)
                .toggle(vo.contactId!),
            title: Text(
              vo.nickName ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            secondary: AvatarWidget(url: vo.avatar, name: vo.nickName),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        );
      },
    );
  }
}
