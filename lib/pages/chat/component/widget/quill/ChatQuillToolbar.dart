import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../common/widgets/Toast.dart';
import 'ColorsBox.dart';

class ChatQuillToolbar extends ConsumerWidget {
  final QuillController controller;
  final VoidCallback onSend;
  final VoidCallback? onImagePressed;
  final VoidCallback? onFilePressed;
  final VoidCallback? onEmojiPressed;

  const ChatQuillToolbar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onImagePressed,
    this.onFilePressed,
    this.onEmojiPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(left: 4,right: 4,top: 4),
      child: Row(
        children: [
          // 💡 左侧富文本编辑按钮组，使用 Expanded + SingleChildScrollView 防止溢出
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

                  _buildActionButton(
                    HugeIcons.strokeRoundedTextAlignLeft,
                    Attribute.leftAlignment,
                    "左对齐",
                    iconColor,
                  ),
                  _buildActionButton(
                    HugeIcons.strokeRoundedTextAlignCenter,
                    Attribute.centerAlignment,
                    "居中",
                    iconColor,
                  ),
                  _buildActionButton(
                    HugeIcons.strokeRoundedTextAlignRight,
                    Attribute.rightAlignment,
                    "右对齐",
                    iconColor,
                  ),
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
                              controller.formatSelection(BackgroundAttribute(hex));
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

          // 💡 右侧功能按钮组（表情、图片、文件、发送）
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCustomBtn(
                HugeIcons.strokeRoundedRelieved02,
                "表情",
                onEmojiPressed,
                iconColor,
              ),
              _buildCustomBtn(
                HugeIcons.strokeRoundedImage02,
                "图片",
                onImagePressed,
                iconColor,
              ),
              _buildCustomBtn(
                HugeIcons.strokeRoundedFiles02,
                "文件",
                onFilePressed,
                iconColor,
              ),
              // 发送按钮通常用主题色突出
              IconButton(
                tooltip: "发送",
                visualDensity: VisualDensity.compact,
                onPressed: onSend,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedSent,
                  size: 20,
                  color: colorScheme.primary,
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
        color: isSelected ? Colors.blue : color,
      ),
    );
  }

  // 构建普通功能按钮
  Widget _buildCustomBtn(
    List<List<dynamic>> icon,
    String tooltip,
    VoidCallback? action,
    Color color,
  ) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: action,
      icon: HugeIcon(icon: icon, size: 18, color: color,strokeWidth: 2,),
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
