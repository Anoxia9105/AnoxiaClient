import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/provider/chat/message/forward_selection_controller.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'forward_message_dialog.dart';

class ForwardSelectionRow extends ConsumerWidget {
  final ChatMessage message;
  final Widget child;
  const ForwardSelectionRow({
    super.key,
    required this.message,
    required this.child,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = message.roomId;
    if (roomId == null) return child;
    final selection = ref.watch(forwardSelectionControllerProvider(roomId));
    if (!selection.active) return child;
    final enabled = canForwardMessage(message);
    void toggle() {
      if (!ref
              .read(forwardSelectionControllerProvider(roomId).notifier)
              .toggle(message) &&
          enabled) {
        Toast.showToast('chat_forward_limit'.tr(), type: ToastType.warning);
      }
    }

    return Semantics(
      selected: selection.messages.containsKey(message.messageId),
      child: InkWell(
        onTap: enabled ? toggle : null,
        child: Row(
          children: [
            Checkbox(
              value: selection.messages.containsKey(message.messageId),
              onChanged: enabled ? (_) => toggle() : null,
            ),
            Expanded(child: IgnorePointer(child: child)),
          ],
        ),
      ),
    );
  }
}

class ForwardSelectionBar extends ConsumerWidget {
  final String roomId;
  const ForwardSelectionBar({super.key, required this.roomId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(forwardSelectionControllerProvider(roomId));
    final messages = selection.messages.values.toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'chat_forward_selected_count'.tr(args: ['${messages.length}']),
            ),
            TextButton(
              onPressed: () => ref
                  .read(forwardSelectionControllerProvider(roomId).notifier)
                  .clear(),
              child: Text('dialog_cancel'.tr()),
            ),
            OutlinedButton(
              onPressed: messages.isEmpty
                  ? null
                  : () => showForwardMessages(
                      context,
                      ref,
                      messages,
                      merged: false,
                    ),
              child: Text('chat_forward_individual'.tr()),
            ),
            FilledButton(
              onPressed: messages.isEmpty
                  ? null
                  : () => showForwardMessages(
                      context,
                      ref,
                      messages,
                      merged: true,
                    ),
              child: Text('chat_forward_merged'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
