import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:anoxia/common/utils/QuillEmbedUtil.dart';
import 'package:anoxia/common/utils/fileUtil.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/protocol/message/Attachment.dart';
import 'package:anoxia/framework/provider/chat/input/UploadValidator.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image/image.dart' as img; // 仅使用纯 Dart 图片处理库
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
      QuillController controller, Uint8List imageBytes) async {
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

      // 2. 乐观更新：极速生成本地预览 (直接写入原始字节)
      final File rawFile = File(p.join(Directory.systemTemp.path, "raw_$id.jpg"));
      await rawFile.writeAsBytes(imageBytes);

      // 3. 立即插入 UI
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

      // 4. 后台静默执行：压缩并上传
      unawaited(_backgroundProcessAndUpload(id, imageBytes));

      return null;
    } catch (e, st) {
      log.error("处理粘贴图片失败: $e", st);
      return null;
    }
  }

  /// 后台处理任务
  Future<void> _backgroundProcessAndUpload(String id, Uint8List rawBytes) async {
    try {
      // 在 Isolate 中压缩
      final File compressedFile = await Isolate.run(() async {
        return await _processImageInIsolatePureDart(rawBytes);
      });

      final uploadAttachment = Attachment(
        id: id,
        url: compressedFile.path,
        name: "image_${DateTime.now().millisecondsSinceEpoch}",
        size: await compressedFile.length(),
        type: "jpg",
      );

      // skipCompression = true，因为已经处理过了
      await uploadImages([uploadAttachment], skipCompression: true);
    } catch (e) {
      log.error("后台图片任务失败 [ID: $id]: $e");
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
        url: file.path!, // 初始使用原图路径做预览
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

    if (uploadList.isNotEmpty) {
      // 选择的图片需要经过压缩逻辑
      unawaited(uploadImages(uploadList, skipCompression: false));
    }
  }

  // --- 核心：统一上传逻辑 ---

  /// 统一上传入口
  /// [skipCompression] 为 true 表示文件已经处理好了（如粘贴）；false 表示需要在此方法内进行 Isolate 压缩
  Future<void> uploadImages(List<Attachment> images,
      {bool skipCompression = false}) async {
    ref.read(isUploadingProvider.notifier).start();
    try {
      List<File> filesToUpload;

      if (skipCompression) {
        // 直接上传 (已经由后台任务处理好的文件)
        filesToUpload = images.map((e) => File(e.url!)).toList();
      } else {
        // 还没处理过的文件（点选的文件），在此启动并发压缩
        filesToUpload = await Future.wait(
          images.map((img) async {
            final Uint8List rawBytes = await File(img.url!).readAsBytes();
            // 每张图开启一个 Isolate 进行压缩，不阻塞 UI
            return await Isolate.run(() => _processImageInIsolatePureDart(rawBytes));
          }),
        );
      }

      // 执行 Dio 上传
      final res = await DioClient().uploadFiles(
        "/file/uploadBatch",
        files: filesToUpload,
      );

      if (res.data is List) {
        final List urls = res.data;
        final Map<String, String> resultMap = {};
        for (int i = 0; i < images.length && i < urls.length; i++) {
          resultMap[images[i].id!] = urls[i].toString();
        }
        // 更新状态，使 DeltaProcessor 能够拿到最终 URL
        state = {...state, ...resultMap};
      }
    } catch (e, st) {
      log.error("图片批量处理/上传失败: $e\n$st");
    } finally {
      ref.read(isUploadingProvider.notifier).stop();
    }
  }

  // --- 静态逻辑：Isolate 纯 Dart 压缩 ---

  /// 纯 Dart 图片处理逻辑
  /// 包含了解码、缩放（如果是超大图）、JPG 编码（压缩质量）
  static Future<File> _processImageInIsolatePureDart(Uint8List rawBytes) async {
    // 1. 解码 (识别各种格式)
    img.Image? image = img.decodeImage(rawBytes);
    if (image == null) throw Exception("图片解码失败，格式不受支持");

    // 2. 压缩逻辑 A：降低分辨率
    // 强制限制最大宽度为 1920。
    // 如果是 4K 截图，缩放到 1080P 会减少 75% 的计算量和体积，且速度大幅提升。
    if (image.width > 1920) {
      image = img.copyResize(
        image,
        width: 1920,
        interpolation: img.Interpolation.average, // 平衡速度与画质
      );
    }

    // 3. 压缩逻辑 B：质量编码
    // 将图片编码为 JPG 格式，质量设为 75
    final Uint8List jpgBytes = img.encodeJpg(image, quality: 75);

    // 4. 写入系统临时文件
    final tempDir = Directory.systemTemp;
    final String fileName = "img_${DateTime.now().microsecondsSinceEpoch}.jpg";
    final File tempFile = File(p.join(tempDir.path, fileName));
    await tempFile.writeAsBytes(jpgBytes);

    return tempFile;
  }
}