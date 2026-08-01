import 'dart:async';

import 'package:anoxia/common/utils/quill_embed_util.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:anoxia/framework/provider/chat/input/upload_validator.dart';
import 'package:anoxia/framework/domain/upload_entry.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';
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
  static const int _maxUploadRetries = 3;

  /// Web 端 PlatformFile.path 为 null，文件内容在 bytes 中，
  /// 按附件 ID 暂存，供上传时构建 XFile 使用
  final Map<String, PlatformFile> _filesById = {};

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
    for (final file in result.files) {
      if (!UploadValidator.validateSingleFile(file)) continue;
      final id = const Uuid().v4();
      if (file.bytes != null) _filesById[id] = file;
      uploadList.add(
        Attachment(
          id: id,
          url: file.path,
          name: file.name,
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
  /// [pickedFiles] 外部传入的文件选择结果（Web 端必传，否则无法读取 bytes）
  ///
  /// 使用批量上传接口，上传成功后更新状态为成功，失败则标记为失败
  Future<void> uploadFiles(
    List<Attachment> attachments, {
    Map<String, PlatformFile>? pickedFiles,
  }) async {
    if (attachments.isEmpty) return;
    if (pickedFiles != null) _filesById.addAll(pickedFiles);

    final files = <XFile>[];
    for (final a in attachments) {
      final local = _filesById[a.id];
      if (local?.bytes != null) {
        files.add(
          XFile.fromData(local!.bytes!, name: a.name ?? local.name),
        );
      } else if (a.url != null && a.url!.isNotEmpty) {
        files.add(XFile(a.url!));
      }
    }
    if (files.isEmpty) {
      _markFailed(attachments);
      return;
    }

    for (int attempt = 1; attempt <= _maxUploadRetries; attempt++) {
      final bool isLastAttempt = attempt == _maxUploadRetries;
      try {
        final res = await DioClient().uploadFiles(
          '/file/uploadBatch',
          files: files,
        );

        final rawList = res.data is Map ? res.data['data'] : res.data;
        if (rawList is List && rawList.isNotEmpty) {
          state = {
            ...state,
            for (int i = 0; i < attachments.length && i < rawList.length; i++)
              attachments[i].id!: UploadEntry.success(rawList[i].toString()),
          };
          return;
        }

        if (isLastAttempt) {
          _markFailed(attachments);
          return;
        }
      } catch (e, st) {
        if (isLastAttempt) {
          log.error('文件上传失败: $e\n$st');
          _markFailed(attachments);
          return;
        }
      }

      final delayMs = 400 * (1 << (attempt - 1));
      await Future.delayed(Duration(milliseconds: delayMs));
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
