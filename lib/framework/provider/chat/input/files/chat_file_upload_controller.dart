import 'dart:async';
import 'dart:io';

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

part 'chat_file_upload_controller.g.dart';

/// 聊天文件上传控制器
///
/// 处理文件选择和上传功能。采用 keepAlive 模式确保跨页面共享状态。
///
/// 核心流程：
/// 1. 用户选择文件 → 2. 创建 Attachment 对象 → 3. 标记为上传中 → 
/// 4. 插入编辑器 → 5. 后台上传 → 6. 更新上传状态
///
/// 状态管理：Map<文件ID, UploadEntry>，支持同时处理多个文件上传
@Riverpod(keepAlive: true)
class ChatFileUploadController extends _$ChatFileUploadController {
  @override
  Map<String, UploadEntry> build() => {};

  /// 从本地选择文件
  ///
  /// [controller] Quill 编辑器控制器
  ///
  /// 弹出文件选择器，允许用户选择多个文件，验证通过后插入编辑器并后台上传
  Future<void> selectFiles(QuillController controller) async {
    // final result = await FilePicker.platform.pickFiles(
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.any,
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
          type: file.extension ?? 'bin',
        ),
      );
    }
    if (uploadList.isEmpty) return;

    _markUploading(uploadList);

    for (final a in uploadList) {
      QuillEmbedUtil.insertEmbed(
        controller: controller,
        type: 'file',
        data: a.toJson(),
      );
    }

    unawaited(uploadFiles(uploadList));
  }

  /// 上传文件到服务器
  ///
  /// [attachments] 要上传的文件附件列表
  ///
  /// 使用批量上传接口，上传成功后更新状态为成功，失败则标记为失败
  Future<void> uploadFiles(List<Attachment> attachments) async {
    if (attachments.isEmpty) return;

    try {
      final files = attachments.map((a) => File(a.url!)).toList();
      final res = await DioClient().uploadFiles(
        "/file/uploadBatch",
        files: files,
      );

      // 修复：正确解析包装对象（与图片控制器一致）
      final rawList = res.data is Map ? res.data['data'] : res.data;

      if (rawList is List && rawList.isNotEmpty) {
        state = {
          ...state,
          for (int i = 0; i < attachments.length && i < rawList.length; i++)
            attachments[i].id!: UploadEntry.success(rawList[i].toString()),
        };
      } else {
        _markFailed(attachments);
      }
    } catch (e, st) {
      log.error("文件上传失败: $e\n$st");
      _markFailed(attachments);
    }
  }

  /// 标记文件为上传中状态
  void _markUploading(List<Attachment> attachments) {
    state = {
      ...state,
      for (final a in attachments) a.id!: UploadEntry.uploading,
    };
  }

  /// 标记文件为上传失败状态
  void _markFailed(List<Attachment> attachments) {
    state = {...state, for (final a in attachments) a.id!: UploadEntry.failed};
  }

  /// 供 DeltaProcessor 使用：只返回上传成功的 id -> url 映射
  Map<String, String> get urlMap => {
    for (final e in state.entries)
      if (e.value.isSuccess) e.key: e.value.serverUrl!,
  };

  /// 消息发送后调用，清理状态
  void clear() => state = {};
}
