import 'dart:convert';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_code_line_number.dart';
import 'package:anoxia/framework/extensions/quill_cursor_x.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/quill_syntax_highlighter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_limit.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:anoxia/framework/provider/chat/input/chat_file_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_image_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/reply_target_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/reply_preview_bar.dart';
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

  /// 构建可提及用户列表（排除自己；群聊顶部固定「@所有人」项）
  List<MentionUser> _buildMentionUsers() {
    final currentUser = ref.read(authControllerProvider).value;
    final roomMembers = ref.read(roomMembersProvider(widget.roomId));
    final room = ref.read(currentRoomProvider(widget.roomId));
    return [
      // 仅群聊支持 @所有人，单聊不展示
      if (room?.roomType == 1) MentionUser.atAll(),
      ...roomMembers
          .where((m) => m.userId != currentUser?.userId)
          .map(
            (m) => MentionUser(
              id: m.userId ?? -1,
              name: m.nickName ?? 'chat_unknown_user_label'.tr(),
              avatar: m.avatar,
            ),
          ),
    ];
  }

  /// 显示 @提及成员选择列表
  void _showMentionList(MentionStateData state) {
    _closeMentionList();
    final offset = _editorKey.getCaretClientPosition();
    if (offset == null) return;

    _cancelMentionToast = Toast.showWidgetOffset(
      target: offset,
      direction: PreferDirection.topLeft,
      child: MentionListWidget(
        users: _buildMentionUsers(),
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
  /// - 上下键：@提及列表弹窗显示时切换选中用户
  /// - Enter：@提及列表显示时选中高亮用户（等价于鼠标点击），否则发送消息（非 Shift 组合）
  /// - Ctrl/Cmd + V：处理粘贴操作
  KeyEventResult _handleKeyPress(KeyEvent event, QuillController controller) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final mentionState = ref.read(mentionStateProvider);
    if (mentionState.isShowing) {
      final filtered = MentionUser.filterUsers(
        _buildMentionUsers(),
        mentionState.searchText,
      );

      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (filtered.isNotEmpty) {
          final delta = event.logicalKey == LogicalKeyboardKey.arrowDown
              ? 1
              : -1;
          final next =
              (mentionState.selectedIndex + delta + filtered.length) %
              filtered.length;
          ref.read(mentionStateProvider.notifier).updateSelectedIndex(next);
        }
        return KeyEventResult.handled;
      }

      if (event.logicalKey == LogicalKeyboardKey.enter &&
          !HardwareKeyboard.instance.isShiftPressed) {
        final index = mentionState.selectedIndex;
        if (index >= 0 && index < filtered.length) {
          _insertMention(filtered[index], mentionState.cursorPosition);
          return KeyEventResult.handled;
        }
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      ref
          .read(chatInputControllerProvider(widget.roomId).notifier)
          .sendMessage();
      widget.bottomSheet();
      return KeyEventResult.handled;
    }

    final isPaste =
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
      if (!ChatInputLimit.canPaste(controller, text)) {
        Toast.showToast(
          'chat_input_length_limit'.tr(
            args: [ChatInputLimit.maxCharacters.toString()],
          ),
        );
        return;
      }
      final selection = controller.selection;

      // 粘贴到代码块内时，绕过 flutter_quill 的启发式插入规则，显式构造携带
      // code-block（含语言）属性的 Delta。否则 Web/wasm 下粘贴多行文本会临时
      // 产生「空代码块」，渲染时序中 RenderEditor 对其查询 childAtPosition 时
      // 抛出 `targetChild should not be null`，并表现为代码块消失。
      if (selection.baseOffset >= 0) {
        final block = _codeBlockAt(controller, selection.baseOffset);
        if (block != null) {
          final language = block.style.attributes[Attribute.codeBlock.key]?.value;
          final delta = _buildCodeBlockDelta(text, language);
          final start = selection.start;
          final deleteLen =
              selection.isCollapsed ? 0 : selection.end - selection.start;
          controller.replaceText(
            start,
            deleteLen,
            delta,
            TextSelection.collapsed(offset: start + text.length),
          );
          return;
        }
      }

      // 使用 replaceText 原子式写入，避免 document.insert + updateSelection
      // 两段式操作在 wasm 渲染时序下导致 render children 与 document 不同步，
      // 触发 flutter_quill 的 childAtPosition null 崩溃。
      final start = selection.baseOffset;
      if (start < 0) {
        controller.replaceText(
          controller.document.length - 1,
          0,
          text,
          TextSelection.collapsed(
            offset: controller.document.length - 1 + text.length,
          ),
        );
      } else if (!selection.isCollapsed) {
        controller.replaceText(
          selection.start,
          selection.end - selection.start,
          text,
          TextSelection.collapsed(offset: selection.start + text.length),
        );
      } else {
        controller.replaceText(
          start,
          0,
          text,
          TextSelection.collapsed(offset: start + text.length),
        );
      }
    }
  }

  /// 返回包含 [offset] 处的代码块节点（向上查找祖先），不在代码块内则返回 null。
  Node? _codeBlockAt(QuillController controller, int offset) {
    final res = controller.document.queryChild(offset);
    var node = res.node;
    while (node != null) {
      if (node.style.containsKey(Attribute.codeBlock.key)) {
        return node;
      }
      node = node.parent;
    }
    return null;
  }

  /// 将纯文本按换行拆分为代码块行，构造携带 code-block（含语言）属性的 Delta。
  ///
  /// 每行的换行符都带上 code-block 属性，确保 flutter_quill 的插入规则不会
  /// 把代码块降级为普通文本或临时产生空代码块。
  Delta _buildCodeBlockDelta(String text, dynamic language) {
    final codeAttr = <String, dynamic>{Attribute.codeBlock.key: language};
    final lines = text.split('\n');
    final delta = Delta();
    delta.insert(lines.first);
    for (var i = 1; i < lines.length; i++) {
      delta.insert('\n', codeAttr);
      delta.insert(lines[i]);
    }
    return delta;
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(chatInputControllerProvider(widget.roomId));
    final focusNode = ref.watch(chatFocusNodeProvider(widget.roomId));
    final replyTarget = ref.watch(replyTargetProvider(widget.roomId));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (replyTarget != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: ReplyPreviewBar(
              message: replyTarget,
              onClear: () {
                ref
                    .read(replyTargetControllerProvider.notifier)
                    .clear(widget.roomId);
              },
            ),
          ),

        /// 聊天工具栏
        ChatQuillToolbar(
          controller: controller,
          roomId: widget.roomId,
          onSend: () {
            ref
                .read(chatInputControllerProvider(widget.roomId).notifier)
                .sendMessage();
            widget.bottomSheet();
          },
          onLocationSubmit: (location) {
            ref
                .read(chatInputControllerProvider(widget.roomId).notifier)
                .sendLocationMessage(location);
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
              textSpanBuilder: QuillSyntaxHighlighter.buildSpan,
              // ignore: experimental_member_use
              customLeadingBlockBuilder: (node, config) =>
                  QuillCodeLineNumber.build(
                    node,
                    config,
                    controller: controller,
                  ),
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
