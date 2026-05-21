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

/// 移动端聊天输入组件
///
/// 提供移动端聊天房间的输入功能，包括：
/// - 文本输入和发送
/// - @提及成员
/// - 表情选择
/// - 图片和文件发送
/// - 语音输入入口
class MobileChatInput extends ConsumerStatefulWidget {
  /// 房间 ID
  final String roomId;

  /// 底部面板关闭回调
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
  /// 文本输入控制器
  final TextEditingController _textController = TextEditingController();

  /// @提及映射，键为用户名，值为用户 ID
  final Map<String, int> _mentionMap = {};

  /// 上一次文本内容，用于检测输入变化
  String _lastText = '';

  /// 文本是否为空
  bool _isTextEmpty = true;

  /// 是否显示更多操作面板
  bool _showMorePanel = false;

  /// 是否显示表情面板
  bool _showEmojiPanel = false;

  /// 输入框焦点节点
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

  /// 焦点变化处理
  ///
  /// 当输入框获得焦点时，关闭所有面板
  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() {
        _showMorePanel = false;
        _showEmojiPanel = false;
      });
    }
  }

  /// 文本变化处理
  ///
  /// 检测 @ 符号输入并弹出提及成员选择面板
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

  /// 显示 @提及成员选择面板
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

  /// 插入 @提及文本
  ///
  /// 将选中的用户名插入到光标位置，替换已输入的 @ 符号
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

  /// 在光标位置插入文本
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

  /// 发送消息
  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // 收集消息中实际包含的 @提及用户 ID
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

  /// 选择并发送文件
  ///
  /// [type] 文件类型
  /// [isImage] 是否为图片
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

  /// 切换更多操作面板显示状态
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

  /// 切换表情面板显示状态
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

  /// 关闭所有面板
  void _closeAllPanels() {
    setState(() {
      _showMorePanel = false;
      _showEmojiPanel = false;
    });
    widget.bottomSheet();
  }

  /// 构建紧凑型图标按钮
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
                        // 更多操作面板
                        ChatMorePanel(
                          roomId: widget.roomId,
                          onPickFile: _pickAndSend,
                          onMentionTap: () {
                            setState(() => _showMorePanel = false);
                            _showMentionSheet();
                          },
                        ),
                        // 表情面板
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
