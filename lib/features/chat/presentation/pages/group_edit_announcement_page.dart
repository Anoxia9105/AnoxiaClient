import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupEditAnnouncementPage extends ConsumerStatefulWidget {
  final String roomId;
  final String initialAnnouncement;

  const GroupEditAnnouncementPage({
    super.key,
    required this.roomId,
    required this.initialAnnouncement,
  });

  @override
  ConsumerState<GroupEditAnnouncementPage> createState() =>
      _GroupEditAnnouncementPageState();
}

class _GroupEditAnnouncementPageState
    extends ConsumerState<GroupEditAnnouncementPage> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAnnouncement);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nextAnnouncement = _controller.text.trim();
    final oldAnnouncement = widget.initialAnnouncement.trim();

    if (nextAnnouncement == oldAnnouncement) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _saving = true);
    final ok = await ref
        .read(roomListServiceProvider.notifier)
        .updateGroupAnnouncement(widget.roomId, nextAnnouncement);
    if (!mounted) return;
    setState(() => _saving = false);

    BotToast.showText(
      text: ok
          ? 'chat_group_announcement_update_success'.tr()
          : 'chat_operation_retry_failed'.tr(),
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
        title: Text('chat_group_announcement'.tr()),
        centerTitle: DeviceUtil.isRealMobile(),
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
          maxLength: 200,
          maxLines: 6,
          autofocus: true,
          enabled: !_saving,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: 'chat_group_announcement_hint'.tr(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
