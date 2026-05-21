import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/chat_emoji_widget.dart';
import 'package:anoxia/features/chat/presentation/widgets/mention_list_widget.dart';

// 引入新抽离的面板
import 'chat_more_panel.dart'; 

class MobileChatInput extends ConsumerStatefulWidget {
  final String roomId;
  final VoidCallback bottomSheet;

  const MobileChatInput({
    super.key,
    required this.roomId,
    required this.bottomSheet,
  });

  @override
  ConsumerState<MobileChatInput> createState() => _MobileChatInputState();
}

class _MobileChatInputState extends ConsumerState<MobileChatInput> {
  final TextEditingController _textController = TextEditingController();
  final Map<String, int> _mentionMap = {};
  String _lastText = '';
  bool _isTextEmpty = true;
  bool _showMorePanel = false;
  bool _showEmojiPanel = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode = ref.read(chatFocusNodeProvider(widget.roomId));
      _focusNode.addListener(_onFocusChange);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() {
        _showMorePanel = false;
        _showEmojiPanel = false;
      });
    }
  }

  void _handleTextChanged(String value) {
    if (_isTextEmpty != value.isEmpty) {
      setState(() => _isTextEmpty = value.isEmpty);
    }
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

    if (_isTextEmpty) setState(() => _isTextEmpty = false);
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final mentionIds = <int>{};
    for (final entry in _mentionMap.entries) {
      if (text.contains('@${entry.key}')) mentionIds.add(entry.value);
    }

    ref.read(chatInputControllerProvider(widget.roomId).notifier).sendPlainTextMessage(text, mentionIds: mentionIds.toList());

    _textController.clear();
    _mentionMap.clear();
    _lastText = '';
    setState(() => _isTextEmpty = true);
    _closeAllPanels();
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
    _closeAllPanels();
  }

  void _toggleMorePanel() {
    if (_showMorePanel) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      setState(() {
        _showEmojiPanel = false;
        _showMorePanel = true;
      });
    }
  }

  void _toggleEmojiPanel() {
    if (_showEmojiPanel) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      setState(() {
        _showMorePanel = false;
        _showEmojiPanel = true;
      });
    }
  }

  void _closeAllPanels() {
    setState(() {
      _showMorePanel = false;
      _showEmojiPanel = false;
    });
    widget.bottomSheet();
  }

  Widget _buildCompactButton({required String tooltipMessage, required VoidCallback onTap, required dynamic icon, Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltipMessage,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: HugeIcon(icon: icon, size: 24, color: color ?? colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final focusNode = ref.watch(chatFocusNodeProvider(widget.roomId));
    final isAnyPanelOpen = _showMorePanel || _showEmojiPanel;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildCompactButton(
                tooltipMessage: 'toolbar_mic'.tr(),
                onTap: () {},
                icon: HugeIcons.strokeRoundedMic01,
              ),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  ),
                  onChanged: _handleTextChanged,
                ),
              ),
              _buildCompactButton(
                tooltipMessage: 'toolbar_emoji'.tr(),
                onTap: _toggleEmojiPanel,
                icon: _showEmojiPanel ? HugeIcons.strokeRoundedKeyboard : HugeIcons.strokeRoundedRelieved02,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
                child: _isTextEmpty
                    ? Row(
                        key: const ValueKey('empty_state_buttons'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCompactButton(
                            tooltipMessage: 'toolbar_more'.tr(),
                            onTap: _toggleMorePanel,
                            icon: HugeIcons.strokeRoundedAddSquare,
                          ),
                        ],
                      )
                    : Row(
                        key: const ValueKey('typing_state_button'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCompactButton(
                            tooltipMessage: 'toolbar_send'.tr(),
                            onTap: _handleSend,
                            icon: HugeIcons.strokeRoundedSent,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        if (isAnyPanelOpen) Divider(height: 1, thickness: 0.5, color: colorScheme.outlineVariant),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn,
          height: isAnyPanelOpen ? (260.0 + MediaQuery.of(context).padding.bottom) : 0.0,
          color: colorScheme.surfaceContainerLow,
          child: Visibility(
            visible: isAnyPanelOpen,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: IndexedStack(
                      index: _showMorePanel ? 0 : (_showEmojiPanel ? 1 : 0),
                      children: [
                        // 1. 使用全新抽离的更多操作面板，并传入回调
                        ChatMorePanel(
                          roomId: widget.roomId,
                          onPickFile: _pickAndSend,
                          onMentionTap: () {
                            setState(() => _showMorePanel = false);
                            _showMentionSheet();
                          },
                        ),
                        // 2. 表情面板保持原样
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: ChatEmojiWidget(
                            closeSelected: _closeAllPanels,
                            onEmojiSelected: _insertTextAtCursor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}