import 'package:anoxia/framework/provider/chat/chat_input_controller.dart';
import 'package:anoxia/pages/chat/component/widget/quill/ChatQuillToolbar.dart';
import 'package:anoxia/pages/chat/component/widget/quill/QuillStyleConfig.dart';
import 'package:anoxia/pages/chat/component/widget/quill/builder/QuillImageBuild.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../framework/services/room_list_service.dart';

class ChatInputField extends ConsumerWidget {
  final VoidCallback bottomSheet;

  const ChatInputField({super.key, required this.bottomSheet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChatQuillToolbar(
            controller: controller,
            onSend: () {
              ref
                  .read(chatInputControllerProvider(room.roomId!).notifier)
                  .sendMessage();
              bottomSheet();
            },
            onEmojiPressed: () => print("点击表情"),
            onFilePressed: () => print("选择文件"),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 200, minHeight: 40),
            child: QuillEditor.basic(
              focusNode: focusNode,
              controller: controller,
              config: QuillEditorConfig(
                enableSelectionToolbar: false,
                //禁用搜索
                textSelectionThemeData: TextSelectionThemeData(
                  //光标颜色
                  cursorColor: colorScheme.primary,
                  //选择颜色
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
                  // AtBuilder(),
                  // FileBuilder(controller: value.controller),
                ],

                onKeyPressed: (event, node) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter &&
                      !HardwareKeyboard.instance.isShiftPressed) {
                    ref
                        .read(
                          chatInputControllerProvider(room.roomId!).notifier,
                        )
                        .sendMessage();
                    bottomSheet();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
