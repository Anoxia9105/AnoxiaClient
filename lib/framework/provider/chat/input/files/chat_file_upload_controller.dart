import 'dart:async';
import 'dart:io';

import 'package:anoxia/common/utils/QuillEmbedUtil.dart';
import 'package:anoxia/framework/protocol/message/Attachment.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/provider/chat/input/UploadValidator.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

part 'chat_file_upload_controller.g.dart';

@Riverpod(keepAlive: true)
class ChatFileUploadController extends _$ChatFileUploadController {
  @override
  Map<String, String> build() {
    // fileId -> serverUrl
    return {};
  }

  /// 选择文件并插入编辑器
  Future<void> selectFiles(QuillController controller) async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.any, // 允许所有类型
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
        type: file.extension ?? 'bin', // 默认为二进制流
      );

      // 在编辑器中插入文件节点 (注意这里 type 是 'file')
      QuillEmbedUtil.insertEmbed(
        controller: controller,
        type: 'file',
        data: attachment.toJson(),
      );

      uploadList.add(attachment);
    }

    if (uploadList.isNotEmpty) {
      unawaited(uploadFiles(uploadList));
    }
  }

  /// 批量上传文件逻辑
  Future<void> uploadFiles(List<Attachment> attachments) async {
    ref.read(isUploadingProvider.notifier).start();

    try {
      // 1. 将路径转换为 File 对象列表
      final List<File> filesToUpload = attachments
          .map((a) => File(a.url!))
          .toList();

      // 2. 调用现有的批量上传接口
      final res = await DioClient().uploadFiles(
        "/file/uploadBatch",
        files: filesToUpload,
      );

      if (res.data is List) {
        final List urls = res.data;
        final Map<String, String> resultMap = {};

        // 3. 映射 ID 和服务器 URL
        for (int i = 0; i < attachments.length && i < urls.length; i++) {
          resultMap[attachments[i].id!] = urls[i].toString();
        }

        // 4. 更新状态
        state = {...state, ...resultMap};
      }
    } catch (e, st) {
      log.error("文件批量上传失败: $e\n$st");
    } finally {
      ref.read(isUploadingProvider.notifier).stop();
    }
  }

  /// 清理已上传的映射（建议在消息发送后调用）
  void clear() => state = {};
}
