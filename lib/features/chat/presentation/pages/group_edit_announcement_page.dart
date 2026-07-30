/// 群组公告编辑页面，用于修改群组的公告内容。
///
/// 提供文本输入框用于编辑公告，支持提交更新到服务器。
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 群组公告编辑页面。
///
/// 通过 [roomId] 标识目标群组，[initialAnnouncement] 为当前公告内容作为初始值。
class GroupEditAnnouncementPage extends ConsumerStatefulWidget {
  /// 群组房间 ID。
  final String roomId;

  /// 当前公告内容，作为编辑的初始值。
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

  /// 提交公告更新。
  ///
  /// 如果公告内容未变化则直接返回，否则调用服务更新公告。
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