import 'dart:convert';

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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../framework/provider/chat/room/room_list_service.dart';

class ChatInputField extends ConsumerStatefulWidget {
  final VoidCallback bottomSheet;

  const ChatInputField({super.key, required this.bottomSheet});

  @override
  ConsumerState<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends ConsumerState<ChatInputField> {
  final GlobalKey _editorKey = GlobalKey();
  Function? _mentionListClose;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupMentionListener();
    });
  }

  @override
  void dispose() {
    _closeMentionList();
    super.dispose();
  }

  void _setupMentionListener() {
    ref.listenManual(mentionStateProvider, (previous, next) {
      if (next.isShowing && !previous!.isShowing) {
        // 延迟一帧，确保 RenderEditor 已经更新
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showMentionList(next);
        });
      } else if (!next.isShowing && previous!.isShowing) {
        _closeMentionList();
      }
    });
  }

  void _showMentionList(MentionStateData mentionState) {
    _closeMentionList(); // 先关闭之前的

    final room = ref.read(activeRoomProvider);
    if (room == null) return;

    final controller = ref.read(chatInputControllerProvider(room.roomId!));

    // 获取光标位置
    final cursorOffset = _getCursorScreenPosition(controller);
    print("光标位置: $cursorOffset");

    if (cursorOffset == null) {
      print("无法获取光标位置");
      return;
    }

    // 获取当前用户
    final currentUser = ref.read(authControllerProvider).value;

    // 从 room_member_service 获取真实的成员列表
    final rawMembers = ref
        .read(roomMemberServiceProvider.notifier)
        .getMembersByRoom(room.roomId ?? '');

    // 排除自己，并转换为 MentionUser
    final mentionUsers = rawMembers
        .where((m) => m.userId != currentUser?.userId) // 排除自己
        .map(
          (m) => MentionUser(
            id: m.userId.toString(),
            name: m.nickName ?? '未知用户',
            avatar: m.avatar,
          ),
        )
        .toList();

    // 使用 Toast.showWidgetOffset 在光标位置显示列表
    _mentionListClose = Toast.showWidgetOffset(
      target: cursorOffset,
      direction: PreferDirection.topLeft,
      child: MentionListWidget(
        users: mentionUsers,
        onUserSelected: (user) {
          _insertMention(user, mentionState.cursorPosition);
        },
      ),
      onClose: () {
        _mentionListClose = null;
      },
    );
  }

  void _closeMentionList() {
    if (_mentionListClose != null) {
      final closeFunc = _mentionListClose;
      _mentionListClose = null;
      closeFunc!();
    }
  }

  /// 获取光标在屏幕上的位置（正确版本）
  Offset? _getCursorScreenPosition(QuillController controller) {
    try {
      // 1. 获取 QuillEditorState
      final quillEditorState = _editorKey.currentState as QuillEditorState?;
      if (quillEditorState == null) {
        print("❌ QuillEditorState 为 null");
        return null;
      }

      // 2. 通过 QuillEditorState 的 editableTextKey 获取内部的 EditorState
      // 根据源码：QuillEditorState 有一个 editableTextKey 属性
      final editorState = quillEditorState.editableTextKey.currentState;
      if (editorState == null) {
        print("❌ EditorState 为 null");
        return null;
      }

      // 3. 从 EditorState 获取 RenderEditor
      final renderEditor = editorState.renderEditor;
      if (renderEditor == null) {
        print("❌ renderEditor 为 null");
        return null;
      }

      // 4. 获取当前光标位置
      final selection = controller.selection;
      if (!selection.isValid || selection.baseOffset < 0) {
        print("❌ selection 无效: $selection");
        return null;
      }

      final cursorPosition = TextPosition(offset: selection.baseOffset);

      // 5. 使用 getLocalRectForCaret 获取光标矩形
      final caretRect = renderEditor.getLocalRectForCaret(cursorPosition);

      print("✅ 光标局部位置: ${caretRect.bottomLeft}");

      // 6. 转换为全局坐标
      final globalOffset = renderEditor.localToGlobal(caretRect.bottomLeft);

      print("✅ 光标全局位置: $globalOffset");

      return globalOffset;
    } catch (e, stackTrace) {
      print('❌ 获取光标位置失败: $e');
      print('堆栈: $stackTrace');
      return null;
    }
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

    // 在 mention 后插入一个空格，方便继续输入
    controller.document.insert(atPosition, ' ');

    // 设置光标位置到空格后面
    final newPosition = atPosition + 1;
    controller.updateSelection(
      TextSelection.collapsed(offset: newPosition),
      ChangeSource.local,
    );

    // 关闭提及列表
    ref.read(mentionStateProvider.notifier).hide();
    _closeMentionList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final room = ref.watch(activeRoomProvider);
    if (room == null) return const SizedBox.shrink();

    final controller = ref.watch(chatInputControllerProvider(room.roomId!));
    final focusNode = ref.watch(chatFocusNodeProvider(room.roomId!));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          width: 1,
          color: colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChatQuillToolbar(
            controller: controller,
            onSend: () {
              ref
                  .read(chatInputControllerProvider(room.roomId!).notifier)
                  .sendMessage();
              widget.bottomSheet();
            },
            onEmojiPressed: () => print("点击表情"),
            onImagePressed: () => ref
                .read(chatImageUploadControllerProvider.notifier)
                .selectImages(controller),
            onFilePressed: () => ref
                .read(chatFileUploadControllerProvider.notifier)
                .selectFiles(controller),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200, minHeight: 50),
            child: QuillEditor.basic(
              key: _editorKey,
              focusNode: focusNode,
              controller: controller,
              config: QuillEditorConfig(
                characterShortcutEvents: const [], // 禁掉输入字符的自动转换
                spaceShortcutEvents: const [], // 禁掉空格触发的自动转换
                enableSelectionToolbar: false, // 禁用弹出菜单
                onKeyPressed: (event, node) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter &&
                      !HardwareKeyboard.instance.isShiftPressed) {
                    ref
                        .read(
                          chatInputControllerProvider(room.roomId!).notifier,
                        )
                        .sendMessage();
                    widget.bottomSheet();
                    return KeyEventResult.handled;
                  }
                  // 拦截 Ctrl + F (搜索)
                  if ((HardwareKeyboard.instance.isControlPressed ||
                          HardwareKeyboard.instance.isMetaPressed) &&
                      event.logicalKey == LogicalKeyboardKey.keyF) {
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                textSelectionThemeData: TextSelectionThemeData(
                  cursorColor: colorScheme.primary,
                  selectionColor: colorScheme.primary.withValues(alpha: 0.5),
                ),
                customStyles: QuillStyleConfig.get(context),
                scrollBottomInset: 10,
                scrollable: true,
                placeholder: "输入消息...",
                autoFocus: true,
                padding: const EdgeInsets.all(8),
                embedBuilders: [
                  QuillImageBuild(),
                  QuillFileBuild(),
                  QuillMentionBuild(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
