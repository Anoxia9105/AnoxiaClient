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

class DesktopChatInput extends ConsumerStatefulWidget {
  final String roomId;
  final VoidCallback bottomSheet;

  const DesktopChatInput({super.key, required this.roomId, required this.bottomSheet});

  @override
  ConsumerState<DesktopChatInput> createState() => _DesktopChatInputState();
}

class _DesktopChatInputState extends ConsumerState<DesktopChatInput> {
  final GlobalKey<QuillEditorState> _editorKey = GlobalKey();
  Function? _cancelMentionToast;

  @override
  void initState() {
    super.initState();
    _initMentionListener();
  }

  void _initMentionListener() {
    ref.listenManual(mentionStateProvider, (previous, next) {
      if (next.isShowing) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showMentionList(next));
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

  void _showMentionList(MentionStateData state) {
    _closeMentionList();
    final offset = _editorKey.getCaretClientPosition();
    if (offset == null) return;

    final currentUser = ref.read(authControllerProvider).value;
    final roomMembers = ref.read(roomMembersProvider(widget.roomId));
    final mentionUsers = roomMembers
        .where((m) => m.userId != currentUser?.userId)
        .map((m) => MentionUser(
              id: m.userId ?? -1,
              name: m.nickName ?? 'chat_unknown_user_label'.tr(),
              avatar: m.avatar,
            ))
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

  void _closeMentionList() {
    _cancelMentionToast?.call();
    _cancelMentionToast = null;
  }

  void _insertMention(MentionUser user, int atPosition) {
    final controller = ref.read(chatInputControllerProvider(widget.roomId));
    final currentPosition = controller.selection.baseOffset;
    final deleteLength = currentPosition - atPosition + 1;

    controller.replaceText(atPosition - 1, deleteLength, '', null);
    controller.document.insert(
      atPosition - 1,
      BlockEmbed('mention', jsonEncode({'userId': user.id, 'userName': user.name})),
    );
    controller.document.insert(atPosition, ' ');
    controller.updateSelection(TextSelection.collapsed(offset: atPosition + 1), ChangeSource.local);

    ref.read(mentionStateProvider.notifier).hide();
    ref.read(chatFocusNodeProvider(widget.roomId)).requestFocus();
  }

  KeyEventResult _handleKeyPress(KeyEvent event, QuillController controller) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      ref.read(chatInputControllerProvider(widget.roomId).notifier).sendMessage();
      widget.bottomSheet();
      return KeyEventResult.handled;
    }
    
    final isPaste = event is KeyDownEvent &&
        (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed) &&
        event.logicalKey == LogicalKeyboardKey.keyV;

    if (isPaste) {
      _handlePaste(controller);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _handlePaste(QuillController controller) async {
    final imageBytes = await Pasteboard.image;
    if (imageBytes != null) {
      ref.read(chatImageUploadControllerProvider.notifier).handlePastedImage(controller, imageBytes);
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
          controller.replaceText(selection.start, selection.end - selection.start, text, null);
        } else {
          controller.document.insert(start, text);
        }
        final newOffset = (selection.isCollapsed ? start : selection.start) + text.length;
        controller.updateSelection(TextSelection.collapsed(offset: newOffset), ChangeSource.local);
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
        ChatQuillToolbar(
          controller: controller,
          onSend: () {
            ref.read(chatInputControllerProvider(widget.roomId).notifier).sendMessage();
            widget.bottomSheet();
          },
          onImagePressed: () => ref.read(chatImageUploadControllerProvider.notifier).selectImages(controller),
          onFilePressed: () => ref.read(chatFileUploadControllerProvider.notifier).selectFiles(controller),
        ),
        ConstrainedBox(
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
              onKeyPressed: (event, node) => _handleKeyPress(event, controller),
              embedBuilders: [QuillImageBuild(), QuillFileBuild(), QuillMentionBuild()],
            ),
          ),
        ),
      ],
    );
  }
}