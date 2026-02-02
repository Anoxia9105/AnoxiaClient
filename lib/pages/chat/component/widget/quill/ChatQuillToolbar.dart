import 'package:anoxia/common/utils/QuillEmbedUtil.dart';
import 'package:anoxia/common/widgets/BubbleDialog.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/pages/chat/component/widget/ChatEmojiWidget.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../common/widgets/Toast.dart';
import 'ColorsBox.dart';

class ChatQuillToolbar extends ConsumerWidget {
  final QuillController controller;
  final VoidCallback onSend;
  final VoidCallback? onImagePressed;
  final VoidCallback? onFilePressed;

  const ChatQuillToolbar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onImagePressed,
    this.onFilePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = colorScheme.onSurfaceVariant;

    final isUploading = ref.watch(isUploadingProvider);

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildActionButton(
                    HugeIcons.strokeRoundedTextBold,
                    Attribute.bold,
                    "加粗",
                    iconColor,
                  ),
                  _buildActionButton(
                    HugeIcons.strokeRoundedTextItalic,
                    Attribute.italic,
                    "斜体",
                    iconColor,
                  ),
                  _buildActionButton(
                    HugeIcons.strokeRoundedTextUnderline,
                    Attribute.underline,
                    "下划线",
                    iconColor,
                  ),
                  _buildActionButton(
                    HugeIcons.strokeRoundedTextStrikethrough,
                    Attribute.strikeThrough,
                    "删除线",
                    iconColor,
                  ),

                  // 清除格式按钮
                  IconButton(
                    tooltip: "清除格式",
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
                    "引用",
                    iconColor,
                  ),
                  _buildActionButton(
                    HugeIcons.strokeRoundedSourceCode,
                    Attribute.codeBlock,
                    "代码块",
                    iconColor,
                  ),
                  Builder(
                    builder: (context) {
                      return IconButton(
                        tooltip: "文字颜色",
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          Function? onCancel;
                          onCancel = Toast.showWidget(
                            context,
                            child: ColorsBox.buildColorsWidget((hex) {
                              controller.formatSelection(ColorAttribute(hex));
                              onCancel?.call();
                            }, context),
                          );
                        },
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedTextColor,
                          size: 14,
                        ),
                      );
                    },
                  ),
                  Builder(
                    builder: (context) {
                      return IconButton(
                        tooltip: "背景颜色",
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          Function? onCancel;
                          onCancel = Toast.showWidget(
                            context,
                            child: ColorsBox.buildColorsWidget((hex) {
                              controller.formatSelection(
                                BackgroundAttribute(hex),
                              );
                              onCancel?.call();
                            }, context),
                          );
                        },
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedBackground,
                          size: 14,
                        ),
                      );
                    },
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(
                builder: (context) {
                  return _buildCustomBtn(
                    HugeIcons.strokeRoundedRelieved02,
                    "表情",
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
                "图片",
                onImagePressed,
                iconColor,
                enabled: !isUploading,
              ),
              _buildCustomBtn(
                HugeIcons.strokeRoundedFiles02,
                "文件",
                onFilePressed,
                iconColor,
                enabled: !isUploading,
              ),
              // 发送按钮通常用主题色突出
              IconButton(
                tooltip: "发送",
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
    final isSelected = controller.getSelectionStyle().attributes.containsKey(
      attr.key,
    );
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: () {
        controller.formatSelection(
          isSelected ? Attribute.clone(attr, null) : attr,
        );
      },
      // 选中状态可以给个背景色或改变颜色
      icon: HugeIcon(
        icon: icon,
        size: 16,
        color: color
      ),
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
