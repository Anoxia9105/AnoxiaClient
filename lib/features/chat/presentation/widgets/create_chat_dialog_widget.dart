import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/contact/presentation/widgets/sorted_contacts/sorted_contact_groups_widget.dart';
import 'package:anoxia/framework/provider/chat/room/create_new_group_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'group_avatar_picker.dart';

/// 创建群聊对话框组件
///
/// 提供创建新群聊的界面，支持：
/// - 输入群聊名称
/// - 从联系人列表中选择群成员
/// - 实时预览已选成员
/// - 显示创建状态（加载中、成功、失败）
class CreateChatDialogWidget extends ConsumerStatefulWidget {
  final bool asPage;

  const CreateChatDialogWidget({super.key, this.asPage = false});

  @override
  ConsumerState<CreateChatDialogWidget> createState() =>
      _CreateChatDialogWidgetState();
}

class _CreateChatDialogWidgetState
    extends ConsumerState<CreateChatDialogWidget> {
  final _nameController = TextEditingController();
  bool _isNameEmpty = true;
  bool _showNameError = false;
  int _joinPolicy = 1;
  String? _avatarUrl;
  bool _avatarBusy = false;

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
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760 || widget.asPage;
        final short = constraints.maxHeight < 500;
        return Column(
          children: [
            _buildAppBar(context, selectedIds, createStatus),
            Flexible(
              flex: short ? 2 : 0,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(compact ? 12 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GroupAvatarPicker(
                      disabled: createStatus.isLoading,
                      onChanged: (url) => setState(() => _avatarUrl = url),
                      onBusyChanged: (busy) =>
                          setState(() => _avatarBusy = busy),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      enabled: !createStatus.isLoading,
                      maxLength: 30,
                      decoration: InputDecoration(
                        labelText: 'chat_group_name'.tr(),
                        hintText: 'create_group_name_hint'.tr(),
                        errorText: _showNameError && _isNameEmpty
                            ? 'create_group_name_empty'.tr()
                            : null,
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(RadiusToken.lg),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'create_group_join_label'.tr(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final policy in [0, 1])
                          ChoiceChip(
                            label: Text(
                              (policy == 0
                                      ? 'create_group_join_free'
                                      : 'create_group_join_approval')
                                  .tr(),
                            ),
                            labelStyle: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: _joinPolicy == policy
                                      ? colorScheme.onSecondaryContainer
                                      : colorScheme.onSurfaceVariant,
                                ),
                            selectedColor: colorScheme.secondaryContainer,
                            backgroundColor: colorScheme.surfaceContainerLow,
                            checkmarkColor: colorScheme.onSecondaryContainer,
                            selected: _joinPolicy == policy,
                            onSelected: createStatus.isLoading
                                ? null
                                : (_) => setState(() => _joinPolicy = policy),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (_joinPolicy == 0
                              ? 'create_group_join_free_hint'
                              : 'create_group_join_approval_hint')
                          .tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: colorScheme.outlineVariant),
            Expanded(
              flex: short ? 3 : 1,
              child: compact
                  ? _buildMobileContent(context, ref, selectedIds)
                  : _buildDesktopContent(context, ref, selectedIds),
            ),
          ],
        );
      },
    );

    if (widget.asPage) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(child: content),
      );
    }
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusToken.xl),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      child: SizedBox(width: 1040, height: 760, child: content),
    );
  }

  Widget _buildDesktopContent(
    BuildContext context,
    WidgetRef ref,
    Set<int> selectedIds,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 10, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(RadiusToken.xl),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(RadiusToken.xl),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.65),
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
    );
  }

  Widget _buildMobileContent(
    BuildContext context,
    WidgetRef ref,
    Set<int> selectedIds,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(RadiusToken.xl),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(RadiusToken.xl),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: _buildContactPicker(ref),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(RadiusToken.lg),
          ),
          child: Text(
            'create_group_selected_count'.tr(
              args: [selectedIds.length.toString()],
            ),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
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
          Expanded(
            child: Text(
              'create_group_title'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          TextButton(
            onPressed: isLoading || _avatarBusy
                ? null
                : () => Navigator.pop(context),
            child: Text('dialog_cancel'.tr()),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed:
                (selectedIds.isEmpty ||
                    _avatarBusy ||
                    isLoading ||
                    _isNameEmpty)
                ? null
                : _submit,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RadiusToken.lg),
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
    if (_avatarBusy || ref.read(createGroupControllerProvider).isLoading) {
      return;
    }
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
          joinPolicy: _joinPolicy,
          avatarUrl: _avatarUrl,
          onSuccess: (newRoom) async {
            if (!mounted) return;
            await ref
                .read(roomListServiceProvider.notifier)
                .refresh(silent: true);

            if (context.mounted) {
              if (newRoom.roomId != null) {
                ref
                    .read(activeRoomIdProvider.notifier)
                    .setActive(newRoom.roomId!);
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
        borderRadius: BorderRadius.circular(RadiusToken.xl),
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
                      'create_group_select_members_hint'.tr(),
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
                          borderRadius: BorderRadius.circular(RadiusToken.lg),
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
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedCancel01,
                            size: 18,
                          ),
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
              borderRadius: BorderRadius.circular(RadiusToken.lg),
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
