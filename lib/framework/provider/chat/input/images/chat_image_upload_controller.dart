import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:anoxia/common/utils/QuillEmbedUtil.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/protocol/message/Attachment.dart';
import 'package:anoxia/framework/provider/chat/input/UploadValidator.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'chat_image_upload_controller.g.dart';

@Riverpod(keepAlive: true)
class ChatImageUploadController extends _$ChatImageUploadController {
  @override
  Map<String, String> build() {
    return {}; // imageId -> serverUrl
  }

  // --- 场景 1：粘贴图片 (Ctrl + V) ---

  Future<String?> handlePastedImage(
    QuillController controller,
    Uint8List imageBytes,
  ) async {
    try {
      // 1. 基础校验 (复用 UploadValidator)
      final tempPlatformFile = PlatformFile(
        name: "pasted_image.jpg",
        size: imageBytes.lengthInBytes,
        bytes: imageBytes,
      );
      
      if (!UploadValidator.validate(controller, [tempPlatformFile])) return null;
      if (!UploadValidator.validateSingleFile(tempPlatformFile)) return null;

      final String id = const Uuid().v4();

      // 2. 将字节写入临时文件，用于 UI 预览和上传
      final File rawFile = File(
        p.join(Directory.systemTemp.path, "pasted_$id.jpg"),
      );
      await rawFile.writeAsBytes(imageBytes);

      // 3. 立即插入 UI 预览
      final previewAttachment = Attachment(
        id: id,
        url: rawFile.path,
        name: "pasted_image",
        size: imageBytes.lengthInBytes,
        type: "jpg",
      );
      
      QuillEmbedUtil.insertEmbed(
        controller: controller,
        type: BlockEmbed.imageType,
        data: previewAttachment.toJson(),
      );

      // 4. 后台直接上传原文件
      unawaited(uploadImages([previewAttachment]));

      return null;
    } catch (e, st) {
      log.error("处理粘贴图片失败: $e", st);
      return null;
    }
  }

  // --- 场景 2：手动选择图片 (点击图标) ---

  Future<void> selectImages(QuillController controller) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    
    if (result == null || result.files.isEmpty) return;
    if (!UploadValidator.validate(controller, result.files)) return;

    final List<Attachment> uploadList = [];
    for (final file in result.files.where((f) => f.path != null)) {
      if (!UploadValidator.validateSingleFile(file)) continue;

      final attachment = Attachment(
        id: const Uuid().v4(),
        url: file.path!, // 使用原图路径
        name: p.basenameWithoutExtension(file.path!),
        size: file.size,
        type: file.extension ?? 'jpg',
      );

      // 插入编辑器预览
      QuillEmbedUtil.insertEmbed(
        controller: controller,
        type: BlockEmbed.imageType,
        data: attachment.toJson(),
      );
      uploadList.add(attachment);
    }

    if (uploadList.isNotEmpty) {
      unawaited(uploadImages(uploadList));
    }
  }

  // --- 核心：统一上传逻辑 ---

  /// 统一上传入口（不再包含压缩逻辑）
  Future<void> uploadImages(List<Attachment> images) async {
    if (images.isEmpty) return;
    
    // 设置全局上传状态（例如显示进度条或加载中指示）
    ref.read(isUploadingProvider.notifier).start();

    try {
      // 准备待上传的文件列表
      final List<File> filesToUpload = images
          .where((img) => img.url != null)
          .map((img) => File(img.url!))
          .toList();

      if (filesToUpload.isEmpty) return;

      // 执行 Dio 批量上传
      final res = await DioClient().uploadFiles(
        "/file/uploadBatch",
        files: filesToUpload,
      );

      // 处理返回结果
      if (res.data is List) {
        final List urls = res.data;
        final Map<String, String> resultMap = {};
        
        for (int i = 0; i < images.length && i < urls.length; i++) {
          resultMap[images[i].id!] = urls[i].toString();
        }
        
        // 更新 State，让 DeltaProcessor 将本地路径替换为远程 URL
        state = {...state, ...resultMap};
      }
    } catch (e, st) {
      log.error("图片上传失败: $e\n$st");
    } finally {
      ref.read(isUploadingProvider.notifier).stop();
    }
  }
}