import 'dart:convert';

import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/provider/chat/input/files/chat_file_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/images/chat_image_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/features/chat/presentation/widgets/chat_emoji_widget.dart';
import 'package:anoxia/features/chat/presentation/widgets/mention_list_widget.dart';
import 'package:anoxia/features/chat/presentation/widgets/quill/chat_quill_toolbar.dart';
import 'package:anoxia/features/chat/presentation/widgets/quill/embedBuilder/quill_file_build.dart';
import 'package:anoxia/features/chat/presentation/widgets/quill/embedBuilder/quill_image_build.dart';
import 'package:anoxia/features/chat/presentation/widgets/quill/embedBuilder/quill_mention_build.dart';
import 'package:anoxia/features/chat/presentation/widgets/quill/quill_style_config.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pasteboard/pasteboard.dart';

import '../../../../framework/extensions/QuillCursorX.dart';
import '../../../../framework/provider/chat/room/room_list_service.dart';

class ChatInputField extends ConsumerStatefulWidget {
  final VoidCallback bottomSheet;

  const ChatInputField({super.key, required this.bottomSheet});

  @override
  ConsumerState<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends ConsumerState<ChatInputField> {
  final GlobalKey<QuillEditorState> _editorKey = GlobalKey();
  final TextEditingController _androidTextController = TextEditingController();
  Function? _cancelMentionToast;
  final Map<String, int> _androidMentionMap = {};
  String _lastAndroidText = '';

  @override
  void initState() {
    super.initState();
    if (!_isAndroidMode) {
      // 使用监听器处理 Mention 弹窗状态
      _initMentionListener();
    }
  }

  bool get _isAndroidMode =>
      DeviceUtil.isRealMobile() &&
      defaultTargetPlatform == TargetPlatform.android;

  void _initMentionListener() {
    // 监听 mentionStateProvider 的变化
    ref.listenManual(mentionStateProvider, (previous, next) {
      if (next.isShowing) {
        // 延迟一帧确保 UI 已渲染，坐标计算才准
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _showMentionList(next),
        );
      } else {
        _closeMentionList();
      }
    });
  }

  @override
  void dispose() {
    _closeMentionList();
    _androidTextController.dispose();
    super.dispose();
  }

  // --- 逻辑处理：提及列表 ---

  void _showMentionList(MentionStateData state) {
    _closeMentionList();

    final offset = _editorKey.getCaretClientPosition();
    if (offset == null) return;

    final room = ref.read(activeRoomProvider);
    if (room == null) return;

    // 获取并过滤成员列表（排除自己）
    final currentUser = ref.read(authControllerProvider).value;
    final roomMembers = ref.read(roomMembersProvider(room.roomId!));
    final mentionUsers = roomMembers
        .where((m) => m.userId != currentUser?.userId)
        .map(
          (m) => MentionUser(
            id: m.userId ?? -1,
            name: m.nickName ?? 'chat_unknown_user_label'.tr(),
            avatar: m.avatar,
          ),
        )
        .toList();

    // 弹出悬浮列表
    _cancelMentionToast = Toast.showWidgetOffset(
      target: offset,
      direction: PreferDirection.topLeft,
      child: MentionListWidget(
        users: mentionUsers,
        onUserSelected: (user) => _insertMention(user, state.cursorPosition),
      ),
    );
  }

  void _closeMentionList() {
    _cancelMentionToast?.call();
    _cancelMentionToast = null;
  }

  /// 插入提及的用户
  void _insertMention(MentionUser user, int atPosition) {
    final room = ref.read(activeRoomProvider);
    if (room == null) return;

    final controller = ref.read(chatInputControllerProvider(room.roomId!));

    // 获取当前位置和 @ 位置之间的文本长度
    final currentPosition = controller.selection.baseOffset;
    final deleteLength = currentPosition - atPosition + 1;

    // 删除 @ 和搜索文本
    controller.replaceText(atPosition - 1, deleteLength, '', null);

    // 插入用户提及
    controller.document.insert(
      atPosition - 1,
      BlockEmbed(
        'mention',
        jsonEncode({'userId': user.id, 'userName': user.name}),
      ),
    );

    controller.document.insert(atPosition, ' ');

    // 设置光标位置到空格后面
    final newPosition = atPosition + 1;
    controller.updateSelection(
      TextSelection.collapsed(offset: newPosition),
      ChangeSource.local,
    );

    // 关闭提及列表
    ref.read(mentionStateProvider.notifier).hide();
    ref.read(chatFocusNodeProvider(room.roomId!)).requestFocus();
  }

  // --- UI 构建 ---

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(activeRoomProvider);
    if (room == null) return const SizedBox.shrink();

    if (_isAndroidMode) {
      return _buildAndroidInput(context, room.roomId!);
    }

    final controller = ref.watch(chatInputControllerProvider(room.roomId!));
    final focusNode = ref.watch(chatFocusNodeProvider(room.roomId!));

    return Container(
      decoration: _buildBoxDecoration(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolbar(room.roomId!, controller),
          _buildEditor(controller, focusNode, room.roomId!),
        ],
      ),
    );
  }

  Widget _buildToolbar(String roomId, QuillController controller) {
    return ChatQuillToolbar(
      controller: controller,
      onSend: () => _handleSend(roomId),
      onImagePressed: () => ref
          .read(chatImageUploadControllerProvider.notifier)
          .selectImages(controller),
      onFilePressed: () => ref
          .read(chatFileUploadControllerProvider.notifier)
          .selectFiles(controller),
    );
  }

  Widget _buildEditor(
    QuillController controller,
    FocusNode focusNode,
    String roomId,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200, minHeight: 50),
      child: QuillEditor.basic(
        key: _editorKey,
        focusNode: focusNode,
        controller: controller,
        config: QuillEditorConfig(
          characterShortcutEvents: const [],
          spaceShortcutEvents: const [],
          enableSelectionToolbar: false,
          placeholder: 'chat_input_placeholder'.tr(),
          autoFocus: false,
          padding: const EdgeInsets.all(8),
          customStyles: QuillStyleConfig.get(context),
          onKeyPressed: (event, node) => _handleKeyPress(event, roomId),
          embedBuilders: [
            QuillImageBuild(),
            QuillFileBuild(),
            QuillMentionBuild(),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidInput(BuildContext context, String roomId) {
    final colorScheme = Theme.of(context).colorScheme;
    final focusNode = ref.watch(chatFocusNodeProvider(roomId));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: _buildBoxDecoration(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _androidTextController,
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
              onChanged: (value) => _handleAndroidTextChanged(value, roomId),
            ),
          ),
          IconButton(
            tooltip: 'toolbar_more'.tr(),
            onPressed: () => _showAndroidActionSheet(roomId),
            icon: Icon(
              Icons.add_circle_outline,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          IconButton(
            tooltip: 'toolbar_send'.tr(),
            onPressed: () => _handleAndroidSend(roomId),
            icon: Icon(Icons.send_rounded, color: colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Future<void> _showAndroidActionSheet(String roomId) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Wrap(
              runSpacing: 8,
              children: [
                _buildAndroidActionTile(
                  context,
                  icon: Icons.emoji_emotions_outlined,
                  label: 'toolbar_emoji'.tr(),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showAndroidEmojiSheet();
                  },
                ),
                _buildAndroidActionTile(
                  context,
                  icon: Icons.image_outlined,
                  label: 'toolbar_image'.tr(),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _pickAndSendImages(roomId);
                  },
                ),
                _buildAndroidActionTile(
                  context,
                  icon: Icons.insert_drive_file_outlined,
                  label: 'toolbar_file'.tr(),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _pickAndSendFiles(roomId);
                  },
                ),
                _buildAndroidActionTile(
                  context,
                  icon: Icons.alternate_email,
                  label: '@',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showAndroidMentionSheet(roomId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAndroidActionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
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

  void _showAndroidEmojiSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ChatEmojiWidget(
                closeSelected: () => Navigator.of(ctx).pop(),
                onEmojiSelected: (emoji) {
                  _insertAndroidTextAtCursor(emoji);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndSendImages(String roomId) async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;

    await ref
        .read(chatInputControllerProvider(roomId).notifier)
        .sendPickedImages(result.files);
    widget.bottomSheet();
  }

  Future<void> _pickAndSendFiles(String roomId) async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;

    await ref
        .read(chatInputControllerProvider(roomId).notifier)
        .sendPickedFiles(result.files);
    widget.bottomSheet();
  }

  void _handleAndroidTextChanged(String value, String roomId) {
    ref
        .read(chatInputControllerProvider(roomId).notifier)
        .handlePlainTextChanged(value);

    final selection = _androidTextController.selection;
    final cursor = selection.baseOffset;
    final isAppend = value.length > _lastAndroidText.length;
    final typedAt =
        isAppend &&
        cursor > 0 &&
        cursor <= value.length &&
        value[cursor - 1] == '@';

    _lastAndroidText = value;

    if (typedAt) {
      _showAndroidMentionSheet(roomId);
    }
  }

  void _showAndroidMentionSheet(String roomId) {
    final currentUser = ref.read(authControllerProvider).value;
    final roomMembers = ref.read(roomMembersProvider(roomId));
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
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: MentionListWidget(
              users: users,
              onUserSelected: (user) {
                Navigator.of(ctx).pop();
                _insertAndroidMention(user);
              },
            ),
          ),
        );
      },
    );
  }

  void _insertAndroidMention(MentionUser user) {
    final text = _androidTextController.text;
    final selection = _androidTextController.selection;
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

    _androidTextController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
    _androidMentionMap[user.name] = user.id;
    _lastAndroidText = newText;
  }

  void _insertAndroidTextAtCursor(String insertText) {
    final text = _androidTextController.text;
    final selection = _androidTextController.selection;
    final cursor = selection.baseOffset < 0
        ? text.length
        : selection.baseOffset;

    final newText =
        '${text.substring(0, cursor)}$insertText${text.substring(cursor)}';
    final newOffset = cursor + insertText.length;

    _androidTextController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
    _lastAndroidText = newText;
  }

  List<int> _extractAndroidMentionIds(String text) {
    final ids = <int>{};
    for (final entry in _androidMentionMap.entries) {
      if (text.contains('@${entry.key}')) {
        ids.add(entry.value);
      }
    }
    return ids.toList();
  }

  void _handleAndroidSend(String roomId) {
    final text = _androidTextController.text.trim();
    if (text.isEmpty) return;

    final mentionIds = _extractAndroidMentionIds(text);
    ref
        .read(chatInputControllerProvider(roomId).notifier)
        .sendPlainTextMessage(text, mentionIds: mentionIds);

    _androidTextController.clear();
    _androidMentionMap.clear();
    _lastAndroidText = '';
    widget.bottomSheet();
  }

  // --- 辅助方法 ---

  BoxDecoration _buildBoxDecoration(BuildContext context) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        width: 1,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
      ),
    );
  }

  KeyEventResult _handleKeyPress(KeyEvent event, String? roomId) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      _handleSend(roomId ?? '');
      return KeyEventResult.handled;
    }
    final isPaste =
        event is KeyDownEvent &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed) &&
        event.logicalKey == LogicalKeyboardKey.keyV;

    if (isPaste) {
      // 拦截事件，手动处理
      _handlePaste(roomId ?? '');
      return KeyEventResult.handled; // 告诉 Quill 不要再处理这个按键了
    }

    return KeyEventResult.ignored;
  }

  void _handleSend(String roomId) {
    ref.read(chatInputControllerProvider(roomId).notifier).sendMessage();
    widget.bottomSheet();
  }

  /// 手动处理粘贴逻辑
  Future<void> _handlePaste(String roomId) async {
    final controller = ref.read(chatInputControllerProvider(roomId));

    // A. 尝试从剪贴板读取图片 (使用 pasteboard 插件)
    final imageBytes = await Pasteboard.image;

    if (imageBytes != null) {
      // 如果读到了图片，调用你 Controller 里写好的逻辑
      ref
          .read(chatImageUploadControllerProvider.notifier)
          .handlePastedImage(controller, imageBytes);
      return;
    }

    // B. 如果没有图片，尝试读取纯文本
    // 因为我们拦截了 Ctrl+V，必须手动把文本塞回去，否则文本粘贴也会失效
    final textData = await Clipboard.getData(Clipboard.kTextPlain);
    if (textData != null &&
        textData.text != null &&
        textData.text!.isNotEmpty) {
      final text = textData.text!;

      // 获取当前光标位置
      final selection = controller.selection;
      final start = selection.baseOffset;

      if (start < 0) {
        // 如果没有焦点或位置无效，追加到末尾
        controller.document.insert(controller.document.length - 1, text);
      } else {
        // 在光标处插入文本
        // 如果有选中文本，先删除选中文本 (selection.start 到 selection.end)
        if (!selection.isCollapsed) {
          final len = selection.end - selection.start;
          controller.replaceText(selection.start, len, text, null);
        } else {
          controller.document.insert(start, text);
        }

        // 移动光标到插入文本的后面
        final newOffset =
            (selection.isCollapsed ? start : selection.start) + text.length;
        controller.updateSelection(
          TextSelection.collapsed(offset: newOffset),
          ChangeSource.local,
        );
      }
    }
  }
}
