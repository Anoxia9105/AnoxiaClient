import 'dart:convert';
import 'package:anoxia/framework/extensions/QuillCursorX.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/provider/chat/input/files/chat_file_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/images/chat_image_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/features/chat/presentation/widgets/mention_list_widget.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/chat_quill_toolbar.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/embedBuilder/quill_file_build.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/embedBuilder/quill_image_build.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/embedBuilder/quill_mention_build.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_style_config.dart';

/// 桌面端聊天输入组件
///
/// 基于 flutter_quill 实现的富文本编辑器，提供以下功能：
/// - 富文本编辑（加粗、斜体、下划线等）
/// - 图片和文件插入
/// - @提及成员
/// - 键盘快捷键支持（Enter 发送，Ctrl+V 粘贴）
class DesktopChatInput extends ConsumerStatefulWidget {
  /// 房间 ID
  final String roomId;

  /// 底部面板关闭回调
  final VoidCallback bottomSheet;

  const DesktopChatInput({
    super.key,
    required this.roomId,
    required this.bottomSheet,
  });

  @override
  ConsumerState<DesktopChatInput> createState() => _DesktopChatInputState();
}

class _DesktopChatInputState extends ConsumerState<DesktopChatInput> {
  /// Quill 编辑器的 GlobalKey
  final GlobalKey<QuillEditorState> _editorKey = GlobalKey();

  /// @提及弹窗的关闭函数
  Function? _cancelMentionToast;

  @override
  void initState() {
    super.initState();
    _initMentionListener();
  }

  /// 初始化 @提及状态监听器
  void _initMentionListener() {
    ref.listenManual(mentionStateProvider, (previous, next) {
      if (next.isShowing) {
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

  /// 显示 @提及成员选择列表
  void _showMentionList(MentionStateData state) {
    _closeMentionList();
    final offset = _editorKey.getCaretClientPosition();
    if (offset == null) return;

    final currentUser = ref.read(authControllerProvider).value;
    final roomMembers = ref.read(roomMembersProvider(widget.roomId));
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

    _cancelMentionToast = Toast.showWidgetOffset(
      target: offset,
      direction: PreferDirection.topLeft,
      child: MentionListWidget(
        users: mentionUsers,
        onUserSelected: (user) => _insertMention(user, state.cursorPosition),
      ),
    );
  }

  /// 关闭 @提及成员选择列表
  void _closeMentionList() {
    _cancelMentionToast?.call();
    _cancelMentionToast = null;
  }

  /// 插入 @提及内容
  ///
  /// 将选中的用户以 BlockEmbed 形式插入到编辑器中
  void _insertMention(MentionUser user, int atPosition) {
    final controller = ref.read(chatInputControllerProvider(widget.roomId));
    final currentPosition = controller.selection.baseOffset;
    final deleteLength = currentPosition - atPosition + 1;

    controller.replaceText(atPosition - 1, deleteLength, '', null);
    controller.document.insert(
      atPosition - 1,
      BlockEmbed(
        'mention',
        jsonEncode({'userId': user.id, 'userName': user.name}),
      ),
    );
    controller.document.insert(atPosition, ' ');
    controller.updateSelection(
      TextSelection.collapsed(offset: atPosition + 1),
      ChangeSource.local,
    );

    ref.read(mentionStateProvider.notifier).hide();
    ref.read(chatFocusNodeProvider(widget.roomId)).requestFocus();
  }

  /// 处理键盘按键事件
  ///
  /// - Enter：发送消息（非 Shift 组合）
  /// - Ctrl/Cmd + V：处理粘贴操作
  KeyEventResult _handleKeyPress(KeyEvent event, QuillController controller) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      ref
          .read(chatInputControllerProvider(widget.roomId).notifier)
          .sendMessage();
      widget.bottomSheet();
      return KeyEventResult.handled;
    }

    final isPaste =
        event is KeyDownEvent &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed) &&
        event.logicalKey == LogicalKeyboardKey.keyV;

    if (isPaste) {
      _handlePaste(controller);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// 处理粘贴操作
  ///
  /// 优先处理图片粘贴，其次处理文本粘贴
  Future<void> _handlePaste(QuillController controller) async {
    final imageBytes = await Pasteboard.image;
    if (imageBytes != null) {
      ref
          .read(chatImageUploadControllerProvider.notifier)
          .handlePastedImage(controller, imageBytes);
      return;
    }

    final textData = await Clipboard.getData(Clipboard.kTextPlain);
    if (textData?.text != null && textData!.text!.isNotEmpty) {
      final text = textData.text!;
      final selection = controller.selection;
      final start = selection.baseOffset;

      if (start < 0) {
        controller.document.insert(controller.document.length - 1, text);
      } else {
        if (!selection.isCollapsed) {
          controller.replaceText(
            selection.start,
            selection.end - selection.start,
            text,
            null,
          );
        } else {
          controller.document.insert(start, text);
        }
        final newOffset =
            (selection.isCollapsed ? start : selection.start) + text.length;
        controller.updateSelection(
          TextSelection.collapsed(offset: newOffset),
          ChangeSource.local,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(chatInputControllerProvider(widget.roomId));
    final focusNode = ref.watch(chatFocusNodeProvider(widget.roomId));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// 聊天工具栏
        ChatQuillToolbar(
          controller: controller,
          onSend: () {
            ref
                .read(chatInputControllerProvider(widget.roomId).notifier)
                .sendMessage();
            widget.bottomSheet();
          },
          onImagePressed: () => ref
              .read(chatImageUploadControllerProvider.notifier)
              .selectImages(controller),
          onFilePressed: () => ref
              .read(chatFileUploadControllerProvider.notifier)
              .selectFiles(controller),
        ),
        ConstrainedBox(
          /// 限制输入框的最小和最大高度，确保在内容较少时不会过于紧凑，内容较多时不会无限扩展
          constraints: const BoxConstraints(maxHeight: 200, minHeight: 50),
          child: QuillEditor.basic(
            key: _editorKey,
            focusNode: focusNode,
            controller: controller,
            config: QuillEditorConfig(
              enableSelectionToolbar: false,
              placeholder: 'chat_input_placeholder'.tr(),
              autoFocus: false,
              padding: const EdgeInsets.all(8),
              customStyles: QuillStyleConfig.get(context),
              // ignore: experimental_member_use
              onKeyPressed: (event, node) => _handleKeyPress(event, controller),
              embedBuilders: [
                QuillImageBuild(),
                QuillFileBuild(),
                QuillMentionBuild(),
              ],
              customShortcuts: const {
                // 关闭 Ctrl+K / Cmd+K
                SingleActivator(LogicalKeyboardKey.keyK, control: true):
                    DoNothingIntent(),
                SingleActivator(LogicalKeyboardKey.keyK, meta: true):
                    DoNothingIntent(),
                // 关闭 Ctrl+F / Cmd+F
                SingleActivator(LogicalKeyboardKey.keyF, control: true):
                    DoNothingIntent(),
                SingleActivator(LogicalKeyboardKey.keyF, meta: true):
                    DoNothingIntent(),
              },
            ),
          ),
        ),
      ],
    );
  }
}
