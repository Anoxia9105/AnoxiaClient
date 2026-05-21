import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/chat_emoji_widget.dart';
import 'package:anoxia/features/chat/presentation/widgets/mention_list_widget.dart';
import 'package:hugeicons/hugeicons.dart';

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

  /// 用于追踪输入框是否为空
  bool _isTextEmpty = true;

  /// 新增状态：控制“更多操作面板”的显示与隐藏
  bool _showMorePanel = false;

  /// 新增状态：控制“表情面板”的显示与隐藏
  bool _showEmojiPanel = false;

  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    // 从 Riverpod 中拉取或使用本地 FocusNode
    // 为了更好地控制键盘与自定义面板的切换，我们在 initState 中绑定监听
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focusNode = ref.read(chatFocusNodeProvider(widget.roomId));
      _focusNode = focusNode;
      _focusNode.addListener(_onFocusChange);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  /// 监听输入框焦点变化：当用户点击输入框唤起软键盘时，应该自动关闭底部自定义面板
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
      setState(() {
        _isTextEmpty = value.isEmpty;
      });
    }
    ref
        .read(chatInputControllerProvider(widget.roomId).notifier)
        .handlePlainTextChanged(value);

    final selection = _textController.selection;
    final cursor = selection.baseOffset;
    final isAppend = value.length > _lastText.length;
    final typedAt =
        isAppend &&
        cursor > 0 &&
        cursor <= value.length &&
        value[cursor - 1] == '@';

    _lastText = value;
    // @成员面板仍然保留底层弹窗，因为其属于临时搜索选取
    if (typedAt) _showMentionSheet();
  }

  /// 保留 @ 选取面板
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
    final cursor = selection.baseOffset < 0
        ? text.length
        : selection.baseOffset;
    final lookupIndex = cursor > 0 ? cursor - 1 : 0;
    final atIndex = text.lastIndexOf('@', lookupIndex);

    String newText;
    int newOffset;

    if (atIndex >= 0 && atIndex <= cursor) {
      newText =
          '${text.substring(0, atIndex)}@${user.name} ${text.substring(cursor)}';
      newOffset = atIndex + user.name.length + 2;
    } else {
      newText =
          '${text.substring(0, cursor)}@${user.name} ${text.substring(cursor)}';
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
    final cursor = selection.baseOffset < 0
        ? text.length
        : selection.baseOffset;

    final newText =
        '${text.substring(0, cursor)}$insertText${text.substring(cursor)}';
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + insertText.length),
    );
    _lastText = newText;

    // 插入表情后文字不为空，同步刷新状态
    if (_isTextEmpty) {
      setState(() {
        _isTextEmpty = false;
      });
    }
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
    setState(() {
      _isTextEmpty = true;
    });
    // 发送后关闭所有面板
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

  /// 切换“更多”面板的显示状态
  void _toggleMorePanel() {
    if (_showMorePanel) {
      // 如果当前已经是打开状态，则聚焦回输入框弹出键盘
      _focusNode.requestFocus();
    } else {
      // 如果没有打开，先收起键盘，再安全打开面板
      _focusNode.unfocus();
      setState(() {
        _showEmojiPanel = false; // 互斥关闭表情面板
        _showMorePanel = true;
      });
    }
  }

  /// 切换“表情”面板的显示状态
  void _toggleEmojiPanel() {
    if (_showEmojiPanel) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      setState(() {
        _showMorePanel = false; // 互斥关闭更多面板
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

  /// 内置网格条目的构建方法
  Widget _buildGridActionItem({
    required dynamic icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: HugeIcon(icon: icon, color: colorScheme.onSurface, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final focusNode = ref.watch(chatFocusNodeProvider(widget.roomId));

    // 统一定义一个构建紧凑圆圈水波纹按钮的方法
    Widget buildCompactButton({
      required String tooltipMessage,
      required VoidCallback onTap,
      required dynamic icon,
      Color? color,
    }) {
      return Tooltip(
        message: tooltipMessage,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
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

    // 检查是否有任意一个自定义面板正处于打开状态
    final isAnyPanelOpen = _showMorePanel || _showEmojiPanel;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// 1. 输入栏主体区域
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// 语音输入按钮
              buildCompactButton(
                tooltipMessage: 'toolbar_mic'.tr(),
                onTap: () {},
                icon: HugeIcons.strokeRoundedMic01,
              ),

              /// 输入框
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                  ),
                  onChanged: _handleTextChanged,
                ),
              ),

              /// 表情按钮（绑定自定义容器切换事件）
              buildCompactButton(
                tooltipMessage: 'toolbar_emoji'.tr(),
                onTap: _toggleEmojiPanel,
                icon: _showEmojiPanel
                    ? HugeIcons
                          .strokeRoundedKeyboard // 打开时图标切换为键盘
                    : HugeIcons.strokeRoundedRelieved02,
              ),

              /// 动画切换部分（更多按钮 vs 发送按钮）
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: _isTextEmpty
                    ? Row(
                        key: const ValueKey('empty_state_buttons'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildCompactButton(
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
                          buildCompactButton(
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

        /// Divider 分割线，让聊天框和内容区边界更清晰
        if (isAnyPanelOpen)
          Divider(height: 1, thickness: 0.5, color: colorScheme.outlineVariant),

        /// 2. 底部弹性容器（通过配置 height 实现丝滑推拉动画）
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn,
          // 动态计算高度：打开时为 260 + 底部安全区，关闭时为 0
          height: isAnyPanelOpen
              ? (260.0 + MediaQuery.of(context).padding.bottom)
              : 0.0,
          color: colorScheme.surfaceContainerLow,
          child: Visibility(
            visible: isAnyPanelOpen, // 关键：关闭时彻底隐藏内部组件，防止计算溢出
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    // 关键：让内容区域弹性伸缩，绝不撑破外层固定高度
                    child: IndexedStack(
                      index: _showMorePanel ? 0 : (_showEmojiPanel ? 1 : 0),
                      children: [
                        /// 选项布局：更多操作面板 (Grid 网格)
                        GridView.count(
                          crossAxisCount: 4,
                          padding: const EdgeInsets.all(16),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          physics:
                              const NeverScrollableScrollPhysics(), // 禁用网格自身滚动
                          children: [
                            _buildGridActionItem(
                              icon: HugeIcons.strokeRoundedImage02,
                              label: 'toolbar_image'.tr(),
                              onTap: () => _pickAndSend(FileType.image, true),
                            ),
                            _buildGridActionItem(
                              icon: HugeIcons.strokeRoundedFiles02,
                              label: 'toolbar_file'.tr(),
                              onTap: () => _pickAndSend(FileType.any, false),
                            ),
                            _buildGridActionItem(
                              icon: HugeIcons.strokeRoundedAt,
                              label: '@',
                              onTap: () {
                                setState(() => _showMorePanel = false);
                                _showMentionSheet();
                              },
                            ),
                          ],
                        ),

                        /// 选项布局：表情面板
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
