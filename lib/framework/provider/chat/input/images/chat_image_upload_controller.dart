import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:anoxia/common/utils/QuillEmbedUtil.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/protocol/message/Attachment.dart';
import 'package:anoxia/framework/provider/chat/input/UploadValidator.dart';
import 'package:anoxia/framework/domain/upload_entry.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'chat_image_upload_controller.g.dart';

@Riverpod(keepAlive: true)
class ChatImageUploadController extends _$ChatImageUploadController {
  @override
  Map<String, UploadEntry> build() => {};

  // --- 场景 1：粘贴图片 ---

  Future<void> handlePastedImage(
    QuillController controller,
    Uint8List imageBytes,
  ) async {
    try {
      final tempFile = PlatformFile(
        name: "pasted_image.jpg",
        size: imageBytes.lengthInBytes,
        bytes: imageBytes,
      );
      if (!UploadValidator.validate(controller, [tempFile])) return;
      if (!UploadValidator.validateSingleFile(tempFile)) return;

      final id = const Uuid().v4();
      final rawFile = File(p.join(Directory.systemTemp.path, "pasted_$id.jpg"));
      await rawFile.writeAsBytes(imageBytes);

      final attachment = Attachment(
        id: id,
        url: rawFile.path,
        name: "pasted_image",
        size: imageBytes.lengthInBytes,
        type: "jpg",
      );

      // 立即标记为 uploading，再插入 embed，彻底消灭空窗期
      _markUploading([attachment]);

      QuillEmbedUtil.insertEmbed(
        controller: controller,
        type: BlockEmbed.imageType,
        data: attachment.toJson(),
      );

      unawaited(uploadImages([attachment]));
    } catch (e, st) {
      log.error("处理粘贴图片失败: $e", st);
    }
  }

  // --- 场景 2：选择图片 ---

  Future<void> selectImages(QuillController controller) async {
    // final result = await FilePicker.platform.pickFiles(
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result == null || result.files.isEmpty) return;
    if (!UploadValidator.validate(controller, result.files)) return;

    final List<Attachment> uploadList = [];
    for (final file in result.files.where((f) => f.path != null)) {
      if (!UploadValidator.validateSingleFile(file)) continue;
      uploadList.add(
        Attachment(
          id: const Uuid().v4(),
          url: file.path!,
          name: p.basenameWithoutExtension(file.path!),
          size: file.size,
          type: file.extension ?? 'jpg',
        ),
      );
    }
    if (uploadList.isEmpty) return;

    // 先全部标记 uploading，再插入 embed
    _markUploading(uploadList);

    for (final a in uploadList) {
      QuillEmbedUtil.insertEmbed(
        controller: controller,
        type: BlockEmbed.imageType,
        data: a.toJson(),
      );
    }

    unawaited(uploadImages(uploadList));
  }

  // --- 核心上传逻辑 ---

  Future<void> uploadImages(List<Attachment> images) async {
    if (images.isEmpty) return;

    try {
      final files = images
          .where((i) => i.url != null)
          .map((i) => File(i.url!))
          .toList();
      if (files.isEmpty) return;

      final res = await DioClient().uploadFiles(
        "/file/uploadBatch",
        files: files,
      );

      // 修复：正确解析包装对象
      final rawList = res.data is Map ? res.data['data'] : res.data;

      if (rawList is List && rawList.isNotEmpty) {
        state = {
          ...state,
          for (int i = 0; i < images.length && i < rawList.length; i++)
            images[i].id!: UploadEntry.success(rawList[i].toString()),
        };
      } else {
        _markFailed(images);
      }
    } catch (e, st) {
      log.error("图片上传失败: $e\n$st");
      _markFailed(images);
    }
  }

  // --- 工具方法 ---

  void _markUploading(List<Attachment> images) {
    state = {...state, for (final i in images) i.id!: UploadEntry.uploading};
  }

  void _markFailed(List<Attachment> images) {
    state = {...state, for (final i in images) i.id!: UploadEntry.failed};
  }

  /// 供 DeltaProcessor 使用：只返回上传成功的 id -> url 映射
  Map<String, String> get urlMap => {
    for (final e in state.entries)
      if (e.value.isSuccess) e.key: e.value.serverUrl!,
  };

  /// 消息发送后调用，清理 state
  void clear() => state = {};
}
