import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/chat_emoji_widget.dart';
import 'package:anoxia/features/chat/presentation/widgets/mention_list_widget.dart';

class AndroidChatInput extends ConsumerStatefulWidget {
  final String roomId;
  final VoidCallback bottomSheet;

  const AndroidChatInput({super.key, required this.roomId, required this.bottomSheet});

  @override
  ConsumerState<AndroidChatInput> createState() => _AndroidChatInputState();
}

class _AndroidChatInputState extends ConsumerState<AndroidChatInput> {
  final TextEditingController _textController = TextEditingController();
  final Map<String, int> _mentionMap = {};
  String _lastText = '';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleTextChanged(String value) {
    ref.read(chatInputControllerProvider(widget.roomId).notifier).handlePlainTextChanged(value);

    final selection = _textController.selection;
    final cursor = selection.baseOffset;
    final isAppend = value.length > _lastText.length;
    final typedAt = isAppend && cursor > 0 && cursor <= value.length && value[cursor - 1] == '@';

    _lastText = value;
    if (typedAt) _showMentionSheet();
  }

  void _showMentionSheet() {
    final currentUser = ref.read(authControllerProvider).value;
    final roomMembers = ref.read(roomMembersProvider(widget.roomId));
    final users = roomMembers
        .where((m) => m.userId != null && m.userId != currentUser?.userId)
        .map((m) => MentionUser(
              id: m.userId!,
              name: m.nickName ?? 'chat_unknown_user_label'.tr(),
              avatar: m.avatar,
            ))
        .toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          child: MentionListWidget(
            users: users,
            onUserSelected: (user) {
              Navigator.of(ctx).pop();
              _insertMention(user);
            },
          ),
        ),
      ),
    );
  }

  void _insertMention(MentionUser user) {
    final text = _textController.text;
    final selection = _textController.selection;
    final cursor = selection.baseOffset < 0 ? text.length : selection.baseOffset;
    final lookupIndex = cursor > 0 ? cursor - 1 : 0;
    final atIndex = text.lastIndexOf('@', lookupIndex);

    String newText;
    int newOffset;

    if (atIndex >= 0 && atIndex <= cursor) {
      newText = '${text.substring(0, atIndex)}@${user.name} ${text.substring(cursor)}';
      newOffset = atIndex + user.name.length + 2;
    } else {
      newText = '${text.substring(0, cursor)}@${user.name} ${text.substring(cursor)}';
      newOffset = cursor + user.name.length + 2;
    }

    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
    _mentionMap[user.name] = user.id;
    _lastText = newText;
  }

  void _insertTextAtCursor(String insertText) {
    final text = _textController.text;
    final selection = _textController.selection;
    final cursor = selection.baseOffset < 0 ? text.length : selection.baseOffset;

    final newText = '${text.substring(0, cursor)}$insertText${text.substring(cursor)}';
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + insertText.length),
    );
    _lastText = newText;
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final mentionIds = <int>{};
    for (final entry in _mentionMap.entries) {
      if (text.contains('@${entry.key}')) mentionIds.add(entry.value);
    }

    ref
        .read(chatInputControllerProvider(widget.roomId).notifier)
        .sendPlainTextMessage(text, mentionIds: mentionIds.toList());

    _textController.clear();
    _mentionMap.clear();
    _lastText = '';
    widget.bottomSheet();
  }

  Future<void> _pickAndSend(FileType type, bool isImage) async {
    final result = await FilePicker.pickFiles(allowMultiple: true, type: type);
    if (result == null || result.files.isEmpty || !mounted) return;

    final notifier = ref.read(chatInputControllerProvider(widget.roomId).notifier);
    if (isImage) {
      await notifier.sendPickedImages(result.files);
    } else {
      await notifier.sendPickedFiles(result.files);
    }
    widget.bottomSheet();
  }

  void _showActionSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          child: Wrap(
            runSpacing: 8,
            children: [
              _buildActionTile(Icons.emoji_emotions_outlined, 'toolbar_emoji'.tr(), () {
                Navigator.of(ctx).pop();
                _showEmojiSheet();
              }),
              _buildActionTile(Icons.image_outlined, 'toolbar_image'.tr(), () {
                Navigator.of(ctx).pop();
                _pickAndSend(FileType.image, true);
              }),
              _buildActionTile(Icons.insert_drive_file_outlined, 'toolbar_file'.tr(), () {
                Navigator.of(ctx).pop();
                _pickAndSend(FileType.any, false);
              }),
              _buildActionTile(Icons.alternate_email, '@', () {
                Navigator.of(ctx).pop();
                _showMentionSheet();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String label, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Icon(icon, color: colorScheme.onPrimaryContainer),
      ),
      title: Text(label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showEmojiSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: ChatEmojiWidget(
              closeSelected: () => Navigator.of(ctx).pop(),
              onEmojiSelected: _insertTextAtCursor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final focusNode = ref.watch(chatFocusNodeProvider(widget.roomId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'chat_input_placeholder'.tr(),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: _handleTextChanged,
            ),
          ),
          IconButton(
            tooltip: 'toolbar_more'.tr(),
            onPressed: _showActionSheet,
            icon: Icon(Icons.add_circle_outline, color: colorScheme.onSurfaceVariant),
          ),
          IconButton(
            tooltip: 'toolbar_send'.tr(),
            onPressed: _handleSend,
            icon: Icon(Icons.send_rounded, color: colorScheme.primary),
          ),
        ],
      ),
    );
  }
}