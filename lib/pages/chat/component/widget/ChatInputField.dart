import 'dart:convert';

import 'package:anoxia/common/widgets/BubbleDialog.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/provider/chat/input/files/chat_file_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/images/chat_image_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/pages/chat/component/widget/MentionListWidget.dart';
import 'package:anoxia/pages/chat/component/widget/quill/ChatQuillToolbar.dart';
import 'package:anoxia/pages/chat/component/widget/quill/QuillStyleConfig.dart';
import 'package:anoxia/pages/chat/component/widget/quill/embedBuilder/QuillFileBuild.dart';
import 'package:anoxia/pages/chat/component/widget/quill/embedBuilder/QuillImageBuild.dart';
import 'package:anoxia/pages/chat/component/widget/quill/embedBuilder/QuillMentionBuild.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
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
  Function? _cancelMentionToast;

  @override
  void initState() {
    super.initState();
    // 使用监听器处理 Mention 弹窗状态
    _initMentionListener();
  }

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
    final mentionUsers = ref
        .read(roomMemberServiceProvider.notifier)
        .getMembersByRoom(room.roomId ?? '')
        .where((m) => m.userId != currentUser?.userId)
        .map(
          (m) => MentionUser(
            id: m.userId.toString(),
            name: m.nickName ?? '未知用户',
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
          placeholder: "输入消息...",
          autoFocus: true,
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
