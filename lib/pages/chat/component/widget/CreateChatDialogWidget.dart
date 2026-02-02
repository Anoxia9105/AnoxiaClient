import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/pages/contact/component/widget/sortedContactGroupsWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../framework/provider/chat/room/create_new_gropu_controller.dart';
import '../../../../framework/provider/chat/room/room_list_service.dart';
import '../../../../framework/provider/contact/contact_list_controller.dart';

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

  @override
  void initState() {
    super.initState();
    // 监听输入框，实时控制按钮状态
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
    // 监听创建状态
    final createStatus = ref.watch(createGroupControllerProvider);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 900, // 稍微调宽
        height: 650,
        child: Column(
          children: [
            // 头部标题栏
            _buildAppBar(context, selectedIds, createStatus),
            // 2. 群名输入区
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: "输入群聊名称...",
                  errorText: _isNameEmpty ? "群聊名称不能为空哦" : null,
                  prefixIcon: const Icon(Icons.edit_note),
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  // 左侧：联系人列表
                  Expanded(flex: 3, child: _buildContactPicker(ref)),

                  // 分割线
                  const VerticalDivider(width: 1, thickness: 1),

                  // 右侧：已选预览
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text(
            "发起群聊",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed:
                (selectedIds.isEmpty ||
                    isLoading ||
                    _nameController.text.isEmpty)
                ? null
                : _submit,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text("完成 (${selectedIds.length})"),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    ref
        .read(createGroupControllerProvider.notifier)
        .createGroup(
          name: name,
          userIds: ref.read(selectedContactIdsProvider).toList(),
          onSuccess: () async {
            // 静默刷新房间列表，让新群组出现在侧边栏
            await ref
                .read(roomListServiceProvider.notifier)
                .refresh(silent: true);

            // 2. 获取刚才创建成功的房间对象（从 state 中取）
            final newRoom = ref.read(createGroupControllerProvider).value;

            if (context.mounted) {
              // 3. 自动跳转到新房间（可选）
              if (newRoom?.roomId != null) {
                ref
                    .read(activeRoomIdProvider.notifier)
                    .setActive(newRoom!.roomId!);
              }
              // 4. 清理并关闭
              ref.read(selectedContactIdsProvider.notifier).clear();
              Toast.showToast("群聊创建成功", type: ToastType.success);
              if (mounted) {
                Navigator.pop(context);
              }
            }
          },
        );
  }

  // 右侧已选成员列表
  Widget _buildSelectedPreview(
    BuildContext context,
    WidgetRef ref,
    Set<int> selectedIds,
  ) {
    final contactMap = ref.watch(contactListServiceProvider).value ?? {};
    return Container(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "已选择 ${selectedIds.length} 人",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView(
              children: selectedIds
                  .map(
                    (id) => ListTile(
                      leading: AvatarWidget(
                        url: contactMap[id]?.avatar,
                        name: contactMap[id]?.nickName,
                      ),
                      title: Text('${contactMap[id]?.nickName}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => ref
                            .read(selectedContactIdsProvider.notifier)
                            .remove(id),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 左侧 picker 逻辑（复用你之前的 SortedContactGroupsWidget）
  Widget _buildContactPicker(WidgetRef ref) {
    return SortedContactGroupsWidget(
      itemBuilder: (vo) {
        final selectedIds = ref.watch(selectedContactIdsProvider);
        final checked = selectedIds.contains(vo.contactId);

        return CheckboxListTile(
          value: checked,
          onChanged: (_) => ref
              .read(selectedContactIdsProvider.notifier)
              .toggle(vo.contactId!),
          title: Text(vo.nickName ?? ''),
          secondary: AvatarWidget(url: vo.avatar, name: vo.nickName),
          controlAffinity: ListTileControlAffinity.leading,
        );
      },
    );
  }

  void _handleCreateGroup(WidgetRef ref) async {
    final ids = ref.read(selectedContactIdsProvider);

    // // 调用 API
    // await ref.read(groupControllerProvider.notifier).createGroup(ids);
    //
    // // 处理结果
    // final state = ref.read(groupControllerProvider);
    // if (!state.hasError) {
    //   // 成功后关闭对话框并重置状态
    //   ref.read(selectedContactIdsProvider.notifier).clear();
    //   Navigator.pop(context);
    //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("群聊创建成功！")));
    // }
  }
}
