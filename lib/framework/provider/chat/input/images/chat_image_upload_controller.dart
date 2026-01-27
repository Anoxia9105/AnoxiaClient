import 'dart:async';
import 'dart:io';

import 'package:anoxia/common/utils/QuillEmbedUtil.dart';
import 'package:anoxia/common/utils/fileUtil.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/protocol/message/Attachment.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/provider/chat/input/UploadValidator.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_compression_flutter/image_compression_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

part 'chat_image_upload_controller.g.dart';

@Riverpod(keepAlive: true)
class ChatImageUploadController extends _$ChatImageUploadController {
  @override
  Map<String, String> build() {
    // imageId -> serverUrl
    ref.onDispose(() {
      log.info("image 上传控制器销毁了！！");
    });
    return {};
  }

  /// 选择并插入预览，后台启动上传
  Future<void> selectImages(QuillController controller) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result == null || result.files.isEmpty) return;

    //使用公共校验逻辑
    if (!UploadValidator.validate(controller, result.files)) return;

    final List<Attachment> uploadList = [];
    for (final file in result.files.where((f) => f.path != null)) {
      //单个文件验证
      if (!UploadValidator.validateSingleFile(file)) continue;
      final attachment = Attachment(
        id: const Uuid().v4(),
        url: file.path!,
        name: p.basenameWithoutExtension(file.path!),
        size: file.size,
        type: file.extension ?? 'jpg',
      );

      QuillEmbedUtil.insertEmbed(
        controller: controller,
        type: BlockEmbed.imageType,
        data: attachment.toJson(),
      );
      uploadList.add(attachment);
    }

    if (uploadList.isNotEmpty) unawaited(uploadImages(uploadList));
  }

  /// 核心上传逻辑
  Future<void> uploadImages(List<Attachment> images) async {
    ref.read(isUploadingProvider.notifier).start();

    try {
      // 1. 并发处理图片预处理（压缩）- 效率更高
      final List<File> filesToUpload = await Future.wait(
        images.map((img) => _prepareImageFile(img.url!)),
      );

      // 2. 调用接口批量上传
      final res = await DioClient().uploadFiles(
        "/file/uploadBatch",
        files: filesToUpload,
      );

      if (res.data is List) {
        final List urls = res.data;
        final Map<String, String> resultMap = {};

        // 3. 利用索引将 ID 和 返回的 URL 关联
        for (int i = 0; i < images.length && i < urls.length; i++) {
          resultMap[images[i].id!] = urls[i].toString();
        }

        state = {...state, ...resultMap};
      }
    } catch (e, st) {
      log.error("图片批量上传失败: $e\n$st");
    } finally {
      ref.read(isUploadingProvider.notifier).stop();
    }
  }

  /// 私有方法：图片压缩预处理
  Future<File> _prepareImageFile(String path) async {
    try {
      final input = ImageFile(
        filePath: path,
        rawBytes: await File(path).readAsBytes(),
      );
      final param = ImageFileConfiguration(
        input: input,
        config: const Configuration(
          outputType: ImageOutputType.webpThenJpg,
          quality: 50,
        ),
      );

      final output = await compressor.compress(param);
      return await FileUtil.writeToTempFile(output.rawBytes, "webp");
    } catch (e) {
      log.warning("图片压缩失败，使用原图: $path, err: $e");
      return File(path); // 压缩失败返回原文件，保证上传流程不中断
    }
  }
}
