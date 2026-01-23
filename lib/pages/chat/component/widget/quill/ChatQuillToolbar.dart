import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:anoxia/common/utils/QuillEmbedUtil.dart';
import 'package:anoxia/framework/provider/chat/chat_upload_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_compression_flutter/image_compression_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../../common/widgets/Toast.dart';
import 'ColorsBox.dart';

class ChatQuillToolbar extends ConsumerWidget {
  final QuillController controller;
  final VoidCallback onSend;
  final VoidCallback? onFilePressed;
  final VoidCallback? onEmojiPressed;

  const ChatQuillToolbar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onFilePressed,
    this.onEmojiPressed,
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

          // 💡 右侧功能按钮组（表情、图片、文件、发送）
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCustomBtn(
                HugeIcons.strokeRoundedRelieved02,
                "表情",
                onEmojiPressed,
                iconColor,
                enabled: !isUploading,
              ),
              _buildCustomBtn(
                HugeIcons.strokeRoundedImage02,
                "图片",
                () => _handleImageButtonPress(ref, context),
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
        color: isSelected ? Colors.blue : color,
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

  Future<void> _handleImageButtonPress(
    WidgetRef ref,
    BuildContext context,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );
      if (result == null) return;
      // 先标记上传中
      ref.read(isUploadingProvider.notifier).start();
      final List<PendingImage> pendingImages = [];

      // 1️⃣ 插入占位 Embed 并准备 PendingImage
      for (final filePath in result.paths) {
        if (filePath == null) continue;

        final uuid = const Uuid().v4();

        // 插入本地占位
        QuillEmbedUtil.insertEmbed(
          controller: controller,
          type: BlockEmbed.imageType,
          data: {"id": uuid, "url": filePath, "local": true},
        );

        pendingImages.add(PendingImage(id: uuid, file: File(filePath)));
      }

      // 2️⃣ 压缩所有文件（按原列表顺序）
      for (int i = 0; i < pendingImages.length; i++) {
        final originFile = pendingImages[i].file;
        try {
          final param = ImageFileConfiguration(
            input: ImageFile(
              filePath: originFile.path,
              rawBytes: await originFile.readAsBytes(),
            ),
            config: Configuration(
              outputType: ImageOutputType.webpThenJpg,
              useJpgPngNativeCompressor: false,
              quality: 50,
            ),
          );

          final output = await compressor.compress(param);
          final tempFile = await _writeToTempFile(output.rawBytes, "webp");

          // 替换压缩文件
          pendingImages[i] = PendingImage(
            id: pendingImages[i].id,
            file: tempFile,
          );
        } catch (_) {
          // 保留原文件
        }
      }

      // 上传（返回 uuid -> url）
      final Map<String, String> resultMap = await ref
          .read(chatUploadControllerProvider.notifier)
          .uploadImages(pendingImages); // 注意：返回 Map<id,url>

      // 精准替换 Embed
      resultMap.forEach((id, url) {
        QuillEmbedUtil.replaceEmbedById(
          controller: controller,
          embedType: BlockEmbed.imageType,
          id: id,
          newData: {"id": id, "url": url, "local": false},
        );
      });
    } catch (e) {
      debugPrint("选择或上传图片失败: $e");
    }
  }

  Future<File> _writeToTempFile(Uint8List bytes, String ext) async {
    final dir = await getTemporaryDirectory();
    print("写入临时文件：${dir.path}");
    final file = File(
      p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.$ext'),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
