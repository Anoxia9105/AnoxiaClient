import 'dart:async';
import 'dart:convert';

import 'package:anoxia/common/utils/QuillEmbedUtil.dart';
import 'package:anoxia/pages/chat/component/widget/quill/ChatQuillToolbar.dart';
import 'package:anoxia/pages/chat/component/widget/quill/QuillStyleConfig.dart';
import 'package:anoxia/pages/chat/component/widget/quill/builder/QuillImageBuild.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../framework/provider/ws/ws_controller.dart';
import '../../../../framework/services/room_list_service.dart';

class ChatInputField extends ConsumerStatefulWidget {
  final VoidCallback onSend;

  const ChatInputField({super.key, required this.onSend});

  @override
  ConsumerState<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends ConsumerState<ChatInputField> {
  late QuillController _controller;
  late FocusNode _focusNode;
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
    _focusNode = FocusNode();

    _controller.document.changes.listen((event) {
      final delta = event.change;
      final source = event.source;
      if (source == ChangeSource.local) {
        final plain = _controller.document.toPlainText().trim();
        for (var op in delta.toList()) {
          if (op.isInsert && op.data is String) {
            final inserted = op.data as String;
            final newLength = plain.length + inserted.length;
            if (newLength > 50) {
              return;
            }
          }
        }
      }
    });
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    // 检查内容是否为空（quill 默认有一个 \n，所以不能单纯判断 text.isEmpty）
    final bool hasContent = _controller.document.length > 1;

    if (hasContent && !_isTyping) {
      _isTyping = true;
      _sendTypingStatus(true); // 发送“正在输入”开始
    }

    // 防抖逻辑：停止打字 2 秒后发送结束状态
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        _sendTypingStatus(false); // 发送“正在输入”结束
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    // 获取纯文本
    final text = _controller.document.toPlainText().trim();
    if (text.isEmpty) return;

    final room = ref.read(activeRoomProvider);
    if (room == null) return;

    ref
        .read(wsControllerProvider.notifier)
        .sendMessage(
          jsonEncode({
            "topic": "MESSAGE",
            "data": {
              "messageId": "msg-${DateTime.now().millisecondsSinceEpoch}",
              "roomId": room.roomId,
              "targetId": room.peerId,
              "type": "TEXT",
              "payload": {"content": text},
            },
          }),
        );

    // 发送完立即重置输入状态
    _isTyping = false;
    _sendTypingStatus(false);
    _controller.clear();
    //调用回调函数  滚动到底部

    // 💡 关键：延迟一小下重新获取焦点，确保 UI 已更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    widget.onSend();
  }

  void _sendTypingStatus(bool isTyping) {
    final room = ref.read(activeRoomProvider);
    if (room == null) return;

    final msg = {
      "topic": "HIGH_FREQUENCY",
      "data": {
        "targetId": room.peerId,
        "roomId": room.roomId,
        "type": "TYPING_STATUS",
        "content": isTyping.toString(),
      },
    };

    ref.read(wsControllerProvider.notifier).sendMessage(jsonEncode(msg));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
            controller: _controller,
            onSend: () => _handleSend(),
            onEmojiPressed: () => print("点击表情"),
            onImagePressed: () => QuillEmbedUtil.insertEmber(
              controller: _controller,
              type: BlockEmbed.imageType,
              data: {
                "url":'https://pic4.zhimg.com/v2-29d4e1070c864ac3a78d885f0b9cc2bf_r.jpg'
                // "url":'https://www.keaitupian.cn/cjpic/frombd/2/253/2990600787/3256164520.jpg'
                // "url":'https://cdn.pixabay.com/photo/2018/04/05/14/09/sunflowers-3292932_1280.jpg'
                // "url":'https://th.bing.com/th/id/R.92dbeb2fe76391bcd5baed283e9172c1?rik=7KBwJuZuvYAFtw&riu=http%3a%2f%2fpic.imeitou.com%2fuploads%2fallimg%2f220909%2f3-220Z9140Q8.jpg&ehk=SoHVW4z21u3FroHenrXC9WjnXEdRQj5yE0zllpl9AJs%3d&risl=&pid=ImgRaw&r=0'
              },
            ),
            onFilePressed: () => print("选择文件"),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 200, // 💡 限制最大高度，防止无限延伸
              minHeight: 40, // 💡 设置一个基础高度
            ),
            child: QuillEditor.basic(
              focusNode: _focusNode,
              controller: _controller,
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
                    _handleSend();
                    return KeyEventResult.handled; // 拦截事件，防止换行
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
