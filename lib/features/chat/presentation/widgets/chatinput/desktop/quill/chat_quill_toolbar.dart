import 'package:anoxia/common/utils/quill_embed_util.dart';
import 'package:anoxia/common/utils/shortcut_hint.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/widgets/bubble_dialog.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/chat_emoji_widget.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/chat_ai_assist_popup.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/chat_quill_color_style_button.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/dialogs/code_input_dialog.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/chat_quill_toggle_style_button.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/desktop/quill/location_box.dart';
import 'package:anoxia/framework/provider/chat/input/chat_file_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_image_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/protocol/message/code_payload.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../common/widgets/toast.dart';
import 'colors_box.dart';

/// 富文本编辑器工具栏组件
///
/// 提供丰富的文本格式化工具，包括：
/// - 文本样式：加粗、斜体、下划线、删除线
/// - 段落格式：引用、代码块
/// - 颜色设置：文字颜色、背景颜色
/// - 插入功能：表情、图片、文件
/// - 发送按钮
///
/// [controller] Quill 编辑器控制器
/// [roomId] 当前聊天房间 ID（用于发送贴图等消息）
  /// [onSend] 发送按钮点击回调
  /// [onCodeSubmit] 代码提交回调
  /// [onImagePressed] 图片按钮点击回调
  /// [onFilePressed] 文件按钮点击回调
  class ChatQuillToolbar extends ConsumerWidget {
  final QuillController controller;
  final FocusNode focusNode;
  final String roomId;
  final VoidCallback onSend;
  final ValueChanged<LocationPayload> onLocationSubmit;
  final ValueChanged<CodePayload> onCodeSubmit;
  final VoidCallback? onImagePressed;
  final VoidCallback? onFilePressed;

  const ChatQuillToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.roomId,
    required this.onSend,
    required this.onLocationSubmit,
    required this.onCodeSubmit,
    this.onImagePressed,
    this.onFilePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = colorScheme.onSurfaceVariant;

    final imageState = ref.watch(chatImageUploadControllerProvider);
    final fileState = ref.watch(chatFileUploadControllerProvider);
    final isUploading = [
      ...imageState.values,
      ...fileState.values,
    ].any((e) => e.isUploading);

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Scrollbar(
              thumbVisibility: false,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildActionButton(
                      HugeIcons.strokeRoundedTextBold,
                      Attribute.bold,
                      withShortcut('toolbar_bold'.tr(), shortcut('B')),
                      iconColor,
                    ),
                    _buildActionButton(
                      HugeIcons.strokeRoundedTextItalic,
                      Attribute.italic,
                      withShortcut('toolbar_italic'.tr(), shortcut('I')),
                      iconColor,
                    ),
                    _buildActionButton(
                      HugeIcons.strokeRoundedTextUnderline,
                      Attribute.underline,
                      withShortcut('toolbar_underline'.tr(), shortcut('U')),
                      iconColor,
                    ),
                    _buildActionButton(
                      HugeIcons.strokeRoundedTextStrikethrough,
                      Attribute.strikeThrough,
                      withShortcut(
                        'toolbar_strikethrough'.tr(),
                        shortcut('S', shift: true),
                      ),
                      iconColor,
                    ),
                    _buildActionButton(
                      HugeIcons.strokeRoundedSourceCode,
                      Attribute.inlineCode,
                      withShortcut('toolbar_inline_code'.tr(), shortcut('`')),
                      iconColor,
                    ),

                    // 清除格式按钮
                    IconButton(
                      tooltip: 'toolbar_clear_format'.tr(),
                      visualDensity: VisualDensity.compact,
                      onPressed: _clearAttributes,
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedTextClear,
                        size: 16,
                        color: iconColor,
                      ),
                    ),

                    // _buildActionButton(
                    //   HugeIcons.strokeRoundedTextAlignLeft,
                    //   Attribute.leftAlignment,
                    //   "左对齐",
                    //   iconColor,
                    // ),
                    // _buildActionButton(
                    //   HugeIcons.strokeRoundedTextAlignCenter,
                    //   Attribute.centerAlignment,
                    //   "居中",
                    //   iconColor,
                    // ),
                    // _buildActionButton(
                    //   HugeIcons.strokeRoundedTextAlignRight,
                    //   Attribute.rightAlignment,
                    //   "右对齐",
                    //   iconColor,
                    // ),
                    _buildActionButton(
                      HugeIcons.strokeRoundedQuoteDown,
                      Attribute.blockQuote,
                      withShortcut('toolbar_quote'.tr(), shortcut('B', shift: true)),
                      iconColor,
                    ),
                    Builder(
                      builder: (context) {
                        return IconButton(
                          mouseCursor: SystemMouseCursors.click,
                          tooltip: 'toolbar_code_block'.tr(),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: () async {
                            final code = await showDialog<CodePayload>(
                              context: context,
                              builder: (dialogContext) => CodeInputDialog(
                                onCancel: () =>
                                    Navigator.of(dialogContext).pop(),
                                onSubmit: (value) =>
                                    Navigator.of(dialogContext).pop(value),
                              ),
                            );
                            if (code != null && context.mounted) {
                              onCodeSubmit(code);
                            }
                          },
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedSourceCode,
                            size: 16,
                          ),
                        );
                      },
                    ),
                    Builder(
                      builder: (context) {
                        return ChatQuillColorStyleButton(
                          controller: controller,
                          type: ChatQuillColorStyleType.foreground,
                          tooltip: 'toolbar_text_color'.tr(),
                          onPressed: () {
                            Function? onCancel;
                            onCancel = Toast.showWidget(
                              context,
                              child: ColorsBox.buildColorsWidget(
                                (hex) {
                                  controller.formatSelection(
                                    ColorAttribute(hex),
                                  );
                                  onCancel?.call();
                                  focusNode.requestFocus();
                                },
                                context,
                                selectedColor: ColorsBox.parseColorFromValue(
                                  controller
                                      .getSelectionStyle()
                                      .attributes[Attribute.color.key]
                                      ?.value,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    Builder(
                      builder: (context) {
                        return ChatQuillColorStyleButton(
                          controller: controller,
                          type: ChatQuillColorStyleType.background,
                          tooltip: 'toolbar_bg_color'.tr(),
                          onPressed: () {
                            Function? onCancel;
                            onCancel = Toast.showWidget(
                              context,
                              child: ColorsBox.buildColorsWidget(
                                (hex) {
                                  controller.formatSelection(
                                    BackgroundAttribute(hex),
                                  );
                                  onCancel?.call();
                                  focusNode.requestFocus();
                                },
                                context,
                                selectedColor: ColorsBox.parseColorFromValue(
                                  controller
                                      .getSelectionStyle()
                                      .attributes[Attribute.background.key]
                                      ?.value,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    IconButton(
                      mouseCursor: SystemMouseCursors.click,
                      tooltip: 'toolbar_location'.tr(),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        final location = await showDialog<LocationPayload>(
                          context: context,
                          barrierDismissible: false,
                          builder: (dialogContext) {
                            final content = LocationBox(
                              onCancel: () => Navigator.of(dialogContext).pop(),
                              onSubmit: (value) =>
                                  Navigator.of(dialogContext).pop(value),
                            );
                            if (MediaQuery.sizeOf(dialogContext).width < 700) {
                              return Dialog.fullscreen(child: content);
                            }
                            return Dialog(
                              clipBehavior: Clip.antiAlias,
                              child: SizedBox(
                                width: 760,
                                height: 620,
                                child: content,
                              ),
                            );
                          },
                        );
                        if (location != null && context.mounted) {
                          onLocationSubmit(location);
                        }
                      },
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedLocation01, size: 16),
                    ),
                    // _buildActionButton(
                    //   HugeIcons.strokeRoundedLeftToRightListBullet,
                    //   Attribute.ul,
                    //   "无序列表",
                    //   iconColor,
                    // ),
                    // _buildActionButton(
                    //   HugeIcons.strokeRoundedLeftToRightListNumber,
                    //   Attribute.ol,
                    //   "有序列表",
                    //   iconColor,
                    // ),
                  ],
                ),
              ),
            ),
          ),

          /// 右侧功能按钮区域
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // AI 助手：输入内容润色/扩写/续写/翻译等（有输入内容时可用）
              // 修复：hasContent 必须在 ListenableBuilder 内实时计算，否则
              // 输入内容变化时按钮启用状态不会更新，导致“无法激活”
              ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final hasContent =
                      controller.document.toPlainText().trim().isNotEmpty;
                  return _buildCustomBtn(
                    HugeIcons.strokeRoundedSparkles,
                    'chat_ai.assist_title'.tr(),
                    () => showChatAiAssistBubble(
                      context,
                      controller: controller,
                      editorFocusNode: focusNode,
                    ),
                    colorScheme.primary,
                    enabled: !isUploading && hasContent,
                  );
                },
              ),
              Builder(
                builder: (context) {
                  return _buildCustomBtn(
                    HugeIcons.strokeRoundedRelieved02,
                    'toolbar_emoji'.tr(),
                    () {
                      Function? close;
                      close = Toast.showWidget(
                        context,
                        direction: PreferDirection.topLeft,
                        child: Material(
                          color: Colors.transparent,
                          child: BubbleWidget(
                            arrowDirection: AxisDirection.down,
                            arrowOffset: 115.w,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surface,
                            border: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                              width: 0.5,
                            ),
                            contentBuilder: (context) => Container(
                              constraints: BoxConstraints(
                                maxWidth: 120.w,
                                maxHeight: 500.h,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: ChatEmojiWidget(
                                closeSelected: () {
                                  close?.call();
                                },
                                onEmojiSelected: (emoji) {
                                  QuillEmbedUtil.insertTextAtCursor(
                                    text: emoji,
                                    controller: controller,
                                  );
                                },
                                onStickerSelected: (sticker) {
                                  ref
                                      .read(
                                        chatInputControllerProvider(
                                          roomId,
                                        ).notifier,
                                      )
                                      .sendStickerMessage(sticker);
                                  close?.call();
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    iconColor,
                    enabled: !isUploading,
                  );
                },
              ),
              _buildCustomBtn(
                HugeIcons.strokeRoundedImage02,
                'toolbar_image'.tr(),
                onImagePressed,
                iconColor,
                enabled: !isUploading,
              ),
              _buildCustomBtn(
                HugeIcons.strokeRoundedFiles02,
                'toolbar_file'.tr(),
                onFilePressed,
                iconColor,
                enabled: !isUploading,
              ),
              // 发送按钮通常用主题色突出
              IconButton(
                mouseCursor: SystemMouseCursors.click,
                tooltip: 'toolbar_send'.tr(),
                visualDensity: VisualDensity.compact,
                onPressed: isUploading ? null : onSend,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedSent,
                  size: 20,
                  color: isUploading ? Colors.grey : colorScheme.primary,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建富文本切换按钮
  Widget _buildActionButton(
    List<List<dynamic>> icon,
    Attribute attr,
    String tooltip,
    Color color,
  ) {
    return ChatQuillToggleStyleButton(
      controller: controller,
      focusNode: focusNode,
      icon: icon,
      attribute: attr,
      tooltip: tooltip,
      color: color,
    );
  }

  // 构建普通功能按钮
  Widget _buildCustomBtn(
    List<List<dynamic>> icon,
    String tooltip,
    VoidCallback? action,
    Color color, {
    bool enabled = true,
  }) {
    return IconButton(
      mouseCursor: SystemMouseCursors.click,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: enabled ? action : null,
      icon: HugeIcon(
        icon: icon,
        size: 18,
        color: enabled ? color : Colors.grey.withValues(alpha: 0.5),
        strokeWidth: 2,
      ),
    );
  }

  void _clearAttributes() {
    final attributes = <Attribute>{};
    for (final style in controller.getAllSelectionStyles()) {
      for (final attr in style.attributes.values) {
        attributes.add(attr);
      }
    }
    for (final attribute in attributes) {
      controller.formatSelection(Attribute.clone(attribute, null));
    }
  }
}
