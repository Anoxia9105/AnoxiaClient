import 'package:alphabet_list_view/alphabet_list_view.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/pages/contact/component/ContactList.dart';
import 'package:anoxia/pages/contact/component/widget/sortedContactGroupsWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hugeicons/hugeicons.dart';

final selectedContactIdsProvider =
    StateNotifierProvider<SelectedContactIdsNotifier, Set<int>>(
      (ref) => SelectedContactIdsNotifier(),
    );

class SelectedContactIdsNotifier extends StateNotifier<Set<int>> {
  SelectedContactIdsNotifier() : super(<int>{});

  void toggle(int userId) {
    final next = {...state};
    if (next.contains(userId)) {
      next.remove(userId);
    } else {
      next.add(userId);
    }
    state = next;
  }

  void clear() => state = {};
}

class CreateChatDialogWidget extends ConsumerWidget {
  const CreateChatDialogWidget({super.key});

  Widget _buildHeader(BuildContext context, String tag) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      width: double.infinity,
      child: Text(
        tag,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(sortedContactGroupsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // 确保子组件不会超出圆角边界
      child: SizedBox(
        width: 800, // 宽度大幅提升
        height: 600, // 固定高度
        child: Stack(
          children: [
            // --- 对话框主体内容 ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "创建新的群聊",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SortedContactGroupsWidget(
                      itemBuilder: (vo) {
                        final selectedIds = ref.watch(
                          selectedContactIdsProvider,
                        );
                        final notifier = ref.read(
                          selectedContactIdsProvider.notifier,
                        );

                        final checked = selectedIds.contains(vo.contactId);

                        return CheckboxListTile(
                          value: checked,
                          onChanged: (_) => notifier.toggle(vo.contactId!),
                          title: Text(vo.nickName ?? ''),
                          secondary: CircleAvatar(
                            child: Text((vo.nickName ?? '').substring(0, 1)),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // --- 右上角关闭按钮 ---
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  size: 20,
                  color: Colors.grey,
                ),
                hoverColor: Colors.red.withValues(alpha: 0.1), // 悬停变淡红
                splashRadius: 20,
                tooltip: "关闭",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
