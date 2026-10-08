import 'dart:async';
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/forward_message.dart';
import 'package:anoxia/framework/provider/chat/message/forwarding_controller.dart';
import 'package:anoxia/framework/provider/chat/message/forward_selection_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/layout/layout_controller.dart';
import 'package:anoxia/framework/provider/chat/chat_focus_mode_controller.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_room_detail_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../chat_room_picker_dialog.dart';

Future<void> showForwardMessages(
  BuildContext context,
  WidgetRef ref,
  List<ChatMessage> messages, {
  required bool merged,
}) async {
  if (messages.isEmpty) return;
  final source = messages.first.roomId;
  if (source == null ||
      messages.any((m) => m.roomId != source || !canForwardMessage(m))) {
    return;
  }
  final target = await showChatRoomPicker(context);
  if (!context.mounted || target?.roomId == null) return;
  final result = await showDialog<ForwardResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ForwardDialog(
      source: source,
      target: target!.roomId!,
      targetName: target.roomName ?? '',
      ids: messages.map((m) => m.messageId!).toList(),
      merged: merged,
    ),
  );
  if (!context.mounted || result == null || !result.isSuccess) return;
  // 用户已主动换房时不让旧请求抢走导航。
  if (ref.read(activeRoomIdProvider) != source) {
    Toast.showToast('chat_forward_success'.tr(), type: ToastType.success);
    return;
  }
  ref.read(forwardSelectionControllerProvider(source).notifier).clear();
  final maxSeq = result.items
      .map((i) => i.seq!)
      .reduce((a, b) => a > b ? a : b);
  await ref
      .read(chatMessagesProvider.notifier)
      .syncRoomMessages(result.targetRoomId, maxSeq);
  if (!context.mounted || ref.read(activeRoomIdProvider) != source) return;
  final active = ref.read(activeRoomIdProvider.notifier);
  final navigator = Navigator.of(context);
  ref.read(layoutControllerProvider.notifier).setIndex(0);
  active.setActive(result.targetRoomId);
  if (DeviceUtil.useSingleColumnPush(context) &&
      result.targetRoomId != source) {
    ref.read(chatFocusModeProvider.notifier).setEnabled(false);
    unawaited(
      navigator
          .push<void>(
            MaterialPageRoute(
              builder: (_) => ChatRoomDetail(
                roomId: result.targetRoomId,
                initialMessageId: result.items.first.messageId,
              ),
            ),
          )
          .then((_) {
            if (context.mounted &&
                ref.read(activeRoomIdProvider) == result.targetRoomId) {
              active.setActive(source);
            }
          }),
    );
  } else {
    ref
        .read(forwardNavigationTargetControllerProvider.notifier)
        .setTarget(result.targetRoomId, result.items.first.messageId);
  }
}

class _ForwardDialog extends ConsumerStatefulWidget {
  final String source;
  final String target;
  final String targetName;
  final List<String> ids;
  final bool merged;
  const _ForwardDialog({
    required this.source,
    required this.target,
    required this.targetName,
    required this.ids,
    required this.merged,
  });
  @override
  ConsumerState<_ForwardDialog> createState() => _ForwardDialogState();
}

class _ForwardDialogState extends ConsumerState<_ForwardDialog> {
  bool _busy = false;
  bool _pendingOther = false;
  String? _error;
  Future<void> _send({bool resumePrevious = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(forwardingControllerProvider.notifier)
          .send(
            widget.source,
            widget.target,
            widget.ids,
            widget.merged ? 'MERGED' : 'INDIVIDUAL',
            resumePrevious: resumePrevious,
          );
      if (mounted) Navigator.pop(context, result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _pendingOther = error is PendingForwardException;
        _error =
            (error is PendingForwardException
                    ? 'chat_forward_previous_pending'
                    : error is TimeoutException
                    ? 'chat_forward_pending'
                    : error is ForwardFailedException
                    ? 'chat_forward_failed'
                    : 'chat_forward_error')
                .tr();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(forwardingControllerProvider).value;
    final completed = progress?.items.where((i) => i.seq != null).length ?? 0;
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(
          (widget.merged ? 'chat_forward_merged' : 'chat_forward_individual')
              .tr(),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'chat_forward_confirm'.tr(
                args: ['${widget.ids.length}', widget.targetName],
              ),
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'chat_forward_progress'.tr(
                  args: [
                    '$completed',
                    '${progress?.items.length ?? widget.ids.length}',
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text('dialog_cancel'.tr()),
          ),
          FilledButton(
            onPressed: _busy
                ? null
                : () => _send(resumePrevious: _pendingOther),
            child: Text(
              (_pendingOther
                      ? 'chat_forward_resume_previous'
                      : 'chat_forward_send')
                  .tr(),
            ),
          ),
        ],
      ),
    );
  }
}
