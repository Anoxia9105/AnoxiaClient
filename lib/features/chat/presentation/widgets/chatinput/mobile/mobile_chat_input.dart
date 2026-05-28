import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/input/input_panel_provider.dart';
import 'package:anoxia/framework/provider/chat/input/mobile_text_input_controller.dart';
import 'package:anoxia/framework/provider/chat/input/voice_record_controller.dart';
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
  bool _isVoiceMode = false;

  late final FocusNode _focusNode;
  late final MobileTextInputController _inputController;
  late final VoiceRecordController _voiceController;

  @override
  void initState() {
    super.initState();
    _focusNode = ref.read(chatFocusNodeProvider(widget.roomId));
    _focusNode.addListener(_onFocusChange);
    _inputController = MobileTextInputController();
    _voiceController = VoiceRecordController();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _voiceController.dispose();
    _focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // 只关面板，不 unfocus，否则键盘弹不出来
      ref.read(inputPanelProvider.notifier).closePanel();
    }
  }

  void _handleTextChanged(String value) {
    final triggered = _inputController.checkMentionTrigger(value);
    _inputController.handleTextChanged(value);
    ref
        .read(chatInputControllerProvider(widget.roomId).notifier)
        .handlePlainTextChanged(value);
    if (triggered) _showMentionSheet();
  }

  void _showMentionSheet() {
    final currentUser = ref.read(authControllerProvider).value;
    final roomMembers = ref.read(roomMembersProvider(widget.roomId));
    final users = roomMembers
        .where((m) => m.userId != null && m.userId != currentUser?.userId)
        .map(
          (m) => MentionUser(
            id: m.userId!,
            name: m.nickName ?? 'chat_unknown_user_label'.tr(),
            avatar: m.avatar,
          ),
        )
        .toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          width: double.infinity,
          child: MentionListWidget(
            users: users,
            onUserSelected: (user) {
              Navigator.of(ctx).pop();
              _inputController.insertMention(user.id, user.name);
            },
          ),
        ),
      ),
    );
  }

  void _handleSend() {
    final data = _inputController.buildSendData();
    if (data == null) return;

    ref
        .read(chatInputControllerProvider(widget.roomId).notifier)
        .sendPlainTextMessage(data.text, mentionIds: data.mentionIds);

    _inputController.clear();
    _closeAllPanels();
  }

  Future<void> _pickAndSend(FileType type, bool isImage) async {
    final result = await FilePicker.pickFiles(allowMultiple: true, type: type);
    if (result == null || result.files.isEmpty || !mounted) return;

    final notifier = ref.read(
      chatInputControllerProvider(widget.roomId).notifier,
    );
    if (isImage) {
      await notifier.sendPickedImages(result.files);
    } else {
      await notifier.sendPickedFiles(result.files);
    }
    _closeAllPanels();
  }

  void _closeAllPanels() {
    ref.read(inputPanelProvider.notifier).closeAll(_focusNode);
    widget.bottomSheet();
  }

  void _toggleVoiceMode() {
    setState(() => _isVoiceMode = !_isVoiceMode);
    if (_isVoiceMode) {
      ref.read(inputPanelProvider.notifier).closeAll(_focusNode);
    } else {
      _focusNode.requestFocus();
    }
  }

  Widget _buildCompactButton({
    required String tooltipMessage,
    required VoidCallback onTap,
    required dynamic icon,
    Color? color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(8);
    return Tooltip(
      message: tooltipMessage,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: HugeIcon(
              icon: icon,
              size: 24,
              color: color ?? colorScheme.onSurfaceVariant,
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
    final panel = ref.watch(inputPanelProvider);
    final isAnyPanelOpen = panel != InputPanel.none;

    final isInPipMode = ref.watch(
      mobileCallSessionControllerProvider.select(
        (s) => s?.isInPipMode ?? false,
      ),
    );
    if (isInPipMode) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 语音/键盘切换按钮
              _buildCompactButton(
                tooltipMessage: _isVoiceMode
                    ? 'toolbar_keyboard'.tr()
                    : 'toolbar_mic'.tr(),
                onTap: _toggleVoiceMode,
                icon: _isVoiceMode
                    ? HugeIcons.strokeRoundedKeyboard
                    : HugeIcons.strokeRoundedMic01,
              ),
              Expanded(
                child: _isVoiceMode
                    ? GestureDetector(
                        onLongPressStart: (d) {
                          _voiceController.onStart(d);
                          _voiceController.showOverlay(context);
                        },
                        onLongPressMoveUpdate: _voiceController.onUpdate,
                        onLongPressEnd: (d) {
                          _voiceController.onEnd(d);
                          _voiceController.hideOverlay();
                        },
                        child: ListenableBuilder(
                          listenable: _voiceController,
                          builder: (_, _) => Container(
                            height: 40,
                            alignment: Alignment.center,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: _voiceController.isRecording
                                  ? colorScheme.surfaceContainerHighest
                                  : colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _voiceController.isRecording
                                    ? colorScheme.outline
                                    : Colors.transparent,
                                width: 0.5,
                              ),
                            ),
                            child: Text('hold_to_talk'.tr()),
                          ),
                        ),
                      )
                    : TextField(
                        controller: _inputController.textController,
                        focusNode: focusNode,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'chat_input_placeholder'.tr(),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        onChanged: _handleTextChanged,
                        onTap: () async {
                          if (panel != InputPanel.none) {
                            ref
                                .read(inputPanelProvider.notifier)
                                .closeAll(_focusNode);
                            await Future.delayed(
                              const Duration(milliseconds: 250),
                            );
                            if (mounted) _focusNode.requestFocus();
                          }
                        },
                      ),
              ),
              // 表情按钮
              _buildCompactButton(
                tooltipMessage: 'toolbar_emoji'.tr(),
                onTap: () => ref
                    .read(inputPanelProvider.notifier)
                    .toggle(InputPanel.emoji, _focusNode),
                icon: panel == InputPanel.emoji
                    ? HugeIcons.strokeRoundedKeyboard
                    : HugeIcons.strokeRoundedRelieved02,
              ),
              // 发送/更多按钮
              ListenableBuilder(
                listenable: _inputController,
                builder: (_, _) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: _inputController.isEmpty
                      ? Row(
                          key: const ValueKey('empty_state_buttons'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCompactButton(
                              tooltipMessage: 'toolbar_more'.tr(),
                              onTap: () => ref
                                  .read(inputPanelProvider.notifier)
                                  .toggle(InputPanel.more, _focusNode),
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
              ),
            ],
          ),
        ),
        // 分割线
        if (isAnyPanelOpen)
          Divider(height: 1, thickness: 0.5, color: colorScheme.outlineVariant),
        // 面板区域
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn,
          height: isAnyPanelOpen
              ? (260.0 + MediaQuery.of(context).padding.bottom)
              : 0.0,
          color: colorScheme.surfaceContainerLow,
          child: Visibility(
            visible: isAnyPanelOpen,
            child: SafeArea(
              top: false,
              child: IndexedStack(
                index: panel == InputPanel.more ? 0 : 1,
                children: [
                  ChatMorePanel(
                    roomId: widget.roomId,
                    onPickFile: _pickAndSend,
                    onMentionTap: () {
                      ref
                          .read(inputPanelProvider.notifier)
                          .closeAll(_focusNode);
                      _showMentionSheet();
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: ChatEmojiWidget(
                      closeSelected: _closeAllPanels,
                      onEmojiSelected: _inputController.insertTextAtCursor,
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
