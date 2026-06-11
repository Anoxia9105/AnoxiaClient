import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupEditNamePage extends ConsumerStatefulWidget {
  final String roomId;
  final String initialName;

  const GroupEditNamePage({
    super.key,
    required this.roomId,
    required this.initialName,
  });

  @override
  ConsumerState<GroupEditNamePage> createState() => _GroupEditNamePageState();
}

class _GroupEditNamePageState extends ConsumerState<GroupEditNamePage> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nextName = _controller.text.trim();
    if (nextName.isEmpty) {
      BotToast.showText(text: 'create_group_name_empty'.tr());
      return;
    }
    if (nextName == widget.initialName.trim()) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _saving = true);
    final ok = await ref
        .read(roomListServiceProvider.notifier)
        .updateGroupName(widget.roomId, nextName);
    if (!mounted) return;
    setState(() => _saving = false);

    BotToast.showText(
      text: ok ? 'chat_group_name_update_success'.tr() : 'chat_operation_retry_failed'.tr(),
    );
    if (ok) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('chat_group_name'.tr()),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                : Text('chat_confirm_btn'.tr()),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          maxLength: 30,
          autofocus: true,
          enabled: !_saving,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: 'create_group_name_hint'.tr(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
