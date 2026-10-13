import 'dart:convert';
import 'package:anoxia/framework/extensions/quill_cursor_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/common/utils/quill_embed_util.dart';
import 'package:anoxia/common/constants/storage_keys.dart';
import 'package:anoxia/common/utils/sp_util.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_limit.dart';
import 'package:anoxia/framework/provider/chat/input/chat_file_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_image_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/reply_target_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/reply_preview_bar.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/ai/smart_reply_bar.dart';
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

    final sendShortcut = SPUtil.instance.get(StorageKeys.chatSendShortcut, defValue: 'enter');
    final isCtrlEnterMode = sendShortcut == 'ctrlEnter';
    final isEnter = event.logicalKey == LogicalKeyboardKey.enter;
    final isCtrlPressed = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
    final shouldSend = isEnter && (isCtrlEnterMode ? isCtrlPressed : !HardwareKeyboard.instance.isShiftPressed && !isCtrlPressed);
    // Ctrl+Enter 模式下，单独 Enter 换行；Enter 模式下 Ctrl+Enter 也允许换行
    final isNewLine = isEnter && !shouldSend;
    if (isNewLine) return KeyEventResult.ignored;
    if (shouldSend) {
      ref.read(chatInputControllerProvider(widget.roomId).notifier).sendMessage();
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
      // 统一换行符：Windows/Web 剪贴板的 CRLF 会把字面量 \r 带进代码块
      final text = textData.text!
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n');
      if (!ChatInputLimit.canPaste(controller, text)) {
        Toast.showToast(
          'chat_input_length_limit'.tr(
            args: [ChatInputLimit.maxCharacters.toString()],
          ),
          type: ToastType.warning,
        );
        return;
      }
      final selection = controller.selection;

      // 代码块（含语言）由 flutter_quill 自带的 PreserveBlockStyleOnInsertRule
      // 处理，无需自定义 Delta 分支；自定义分支会把选区偏移重复计数，导致光标定
      // 位错误并触发渲染层 targetChild 崩溃，故此处统一走原生 replaceText。
      if (!selection.isValid) {
        controller.replaceText(
          controller.document.length - 1,
          0,
          text,
          TextSelection.collapsed(
            offset: controller.document.length - 1 + text.length,
          ),
        );
        return;
      }

      // 使用 replaceText 原子式写入：flutter_quill 会自动按选区保留代码块属性
      // 并正确计算光标偏移，避免 wasm 渲染时序下 render children 与 document
      // 不同步导致的 childAtPosition null 崩溃。
      final start = selection.start;
      final deleteLen = selection.isCollapsed
          ? 0
          : selection.end - selection.start;
      controller.replaceText(
        start,
        deleteLen,
        text,
        TextSelection.collapsed(offset: start + text.length),
      );
    }
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

        /// 智能回复建议条（手动触发，点击 chip 填入输入框）
        SmartReplyBar(
          roomId: widget.roomId,
          onPick: (text) {
            QuillEmbedUtil.insertTextAtCursor(
              text: text,
              controller: controller,
            );
          },
        ),

        /// 聊天工具栏
        ChatQuillToolbar(
          controller: controller,
          focusNode: focusNode,
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
          onCodeSubmit: (code) {
            ref
                .read(chatInputControllerProvider(widget.roomId).notifier)
                .sendCodeMessage(code);
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
              customStyles: QuillStyleConfig.get(context, forEditing: true),
              // flutter_quill 的 onKeyPressed 仍是 experimental，但这是当前版本
              // 处理键盘快捷键（Ctrl+B/I/U 等）的唯一入口，故忽略该提示。
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
