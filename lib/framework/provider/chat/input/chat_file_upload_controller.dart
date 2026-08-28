import 'dart:async';
import 'dart:typed_data';

import 'package:anoxia/common/utils/quill_embed_util.dart';
import 'package:anoxia/common/utils/video_metadata_util.dart';
import 'package:anoxia/domain/models/upload_file_result.dart';
import 'package:anoxia/framework/provider/core/toast_service_provider.dart';
import 'package:anoxia/framework/provider/core/upload_repository_provider.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
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

  /// 视频附件的真实元数据（时长/宽高），上传完成后异步提取。
  /// 发送视频消息时同步读取，避免服务端 VIDEO 守卫的 durationMs 占位。
  final Map<String, VideoMetadata> _videoMetadata = {};

  /// 服务端返回的可信媒体元数据，以附件 ID 关联到发送链路。
  final Map<String, UploadFileResult> _uploadResults = {};

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
    if (!UploadValidator.validate(
      ref.read(toastServiceProvider),
      controller,
      result.files,
    )) {
      return;
    }

    final List<Attachment> uploadList = [];
    for (final file in result.files) {
      if (!UploadValidator.validateSingleFile(
        ref.read(toastServiceProvider),
        file,
      )) {
        continue;
      }
      final id = const Uuid().v4();
      if (file.bytes != null) {
        _filesById[id] = file;
      }
      final ext = file.extension?.toLowerCase();
      final isVideo = _isVideoExtension(ext, file.name);
      final mime = isVideo ? _mimeForVideo(ext) : (file.extension ?? 'bin');
      final kind = isVideo ? 'VIDEO' : 'FILE';
      uploadList.add(
        Attachment(
          id: id,
          kind: kind,
          url: file.path,
          name: file.name,
          size: file.size,
          type: mime,
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
    _markUploading(attachments);

    var pendingFiles = <XFile>[];
    var pendingAttachments = <Attachment>[];
    for (final a in attachments) {
      final local = _filesById[a.id];
      if (local?.bytes != null) {
        pendingFiles.add(
          XFile.fromData(local!.bytes!, name: a.name ?? local.name),
        );
        pendingAttachments.add(a);
      } else if (a.url != null && a.url!.isNotEmpty) {
        pendingFiles.add(XFile(a.url!));
        pendingAttachments.add(a);
      }
    }
    if (pendingFiles.isEmpty) {
      _markFailed(attachments);
      return;
    }

    for (int attempt = 1; attempt <= _maxUploadRetries; attempt++) {
      final bool isLastAttempt = attempt == _maxUploadRetries;
      try {
        final results = await ref
            .read(uploadRepositoryProvider)
            .uploadFiles(
              pendingFiles,
              clientFileIds: pendingAttachments.map((a) => a.id!).toList(),
              onProgress: _updateProgress,
            );
        state = {
          ...state,
          for (final result in results)
            if (result.isSuccess &&
                result.url != null &&
                state.containsKey(result.clientFileId))
              result.clientFileId: UploadEntry.success(result.url!),
        };
        for (final result in results) {
          if (result.isSuccess && result.url != null) {
            _uploadResults[result.clientFileId] = result;
          }
        }

        // 上传成功的视频：异步提取真实时长/宽高，供发送时同步读取
        for (final a in pendingAttachments) {
          if (a.isVideo && state[a.id]?.isSuccess == true) {
            unawaited(_extractVideoMetadata(a));
          }
        }

        final failedIds = results
            .where(
              (result) => !result.isSuccess && result.errorCode != 'CANCELLED',
            )
            .map((result) => result.clientFileId)
            .toSet();
        final nextFiles = <XFile>[];
        final nextAttachments = <Attachment>[];
        for (var i = 0; i < pendingAttachments.length; i++) {
          if (failedIds.contains(pendingAttachments[i].id)) {
            nextFiles.add(pendingFiles[i]);
            nextAttachments.add(pendingAttachments[i]);
          }
        }
        pendingFiles = nextFiles;
        pendingAttachments = nextAttachments;
        if (pendingFiles.isEmpty) return;
        if (isLastAttempt) _markFailed(pendingAttachments);
      } catch (e, st) {
        if (isLastAttempt) {
          debugLog('文件上传失败: $e\n$st');
          _markFailed(pendingAttachments);
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
    final failed = <String, UploadEntry>{
      for (final a in attachments)
        if (state.containsKey(a.id)) a.id!: UploadEntry.failed,
    };
    if (failed.isEmpty) return;
    state = {...state, ...failed};
  }

  void _updateProgress(String id, int sent, int total) {
    if (!state.containsKey(id)) return;
    state = {...state, id: UploadEntry.uploadingProgress(sent, total)};
  }

  void cancelUpload(String id) {
    ref.read(uploadRepositoryProvider).cancelUpload(id);
    if (state.containsKey(id)) state = {...state, id: UploadEntry.failed};
  }

  /// 只保留仍在编辑器中的附件上传状态
  ///
  /// 用户退格删除正在上传/已失败的 embed 时，若不清理对应记录，
  /// 工具栏发送按钮会一直处于禁用状态（Web/桌面端）。
  void retain(Set<String> ids) {
    final removed = state.keys.where((id) => !ids.contains(id)).toList();
    if (removed.isEmpty) return;
    for (final id in removed) {
      ref.read(uploadRepositoryProvider).cancelUpload(id);
      _filesById.remove(id);
      _videoMetadata.remove(id);
      _uploadResults.remove(id);
    }
    state = Map.of(state)..removeWhere((id, _) => !ids.contains(id));
  }

  /// 供 DeltaProcessor 使用：只返回上传成功的 id -> url 映射
  Map<String, String> get urlMap => {
    for (final e in state.entries)
      if (e.value.isSuccess) e.key: e.value.serverUrl!,
  };

  /// 消息发送后调用，清理状态
  void clear() {
    state = {};
    _filesById.clear();
    _videoMetadata.clear();
    _uploadResults.clear();
  }

  /// 获取附件对应的内存字节（Web 端本地预览用），无则返回 null
  Uint8List? bytesOf(String? id) => _filesById[id]?.bytes;

  /// 获取视频附件的真实元数据（发送时同步读取），无则返回 null
  VideoMetadata? videoMetadataOf(String? id) =>
      id == null ? null : _videoMetadata[id];

  /// 获取服务端确认的上传结果及媒体元数据。
  UploadFileResult? uploadResultOf(String? id) =>
      id == null ? null : _uploadResults[id];

  /// 确保给定视频附件的元数据已提取完成（发送前置调用，可 await）
  Future<void> ensureVideoMetadata(List<Attachment> videos) async {
    for (final v in videos) {
      if (_videoMetadata.containsKey(v.id)) continue;
      final local = _filesById[v.id];
      final uploadUrl = state[v.id]?.isSuccess == true
          ? state[v.id]!.serverUrl
          : v.url;
      final isHttp =
          v.url != null &&
          (v.url!.startsWith('http://') || v.url!.startsWith('https://'));
      // 优先用磁盘本地文件规避远程加载失败：本地 path（或非 http 的 url）
      // 仅当确实是本地文件时使用；服务器 URL 交给 remoteUrl。
      final localFile = local?.path ?? (isHttp ? null : v.url);
      final meta = await VideoMetadataUtil.extract(
        bytes: local?.bytes,
        mimeType: v.type,
        localPath: localFile,
        remoteUrl: isHttp || localFile == null ? uploadUrl : null,
      );
      if (meta.durationMs != null && meta.durationMs! > 0) {
        _videoMetadata[v.id!] = meta;
      }
    }
  }

  Future<void> _extractVideoMetadata(Attachment a) async {
    final local = _filesById[a.id];
    final uploadUrl = state[a.id]?.isSuccess == true
        ? state[a.id]!.serverUrl
        : a.url;
    final isHttp =
        a.url != null &&
        (a.url!.startsWith('http://') || a.url!.startsWith('https://'));
    final meta = await VideoMetadataUtil.extract(
      bytes: local?.bytes,
      mimeType: a.type,
      localPath: !isHttp ? a.url : null,
      remoteUrl: isHttp ? a.url : uploadUrl,
    );
    if (meta.durationMs == null || meta.durationMs! <= 0) return;
    _videoMetadata[a.id!] = meta;
  }

  bool _isVideoExtension(String? ext, String fileName) {
    const videoExts = {
      'mp4',
      'mov',
      'avi',
      'mkv',
      'webm',
      'm4v',
      'flv',
      '3gp',
      'wmv',
      'mpeg',
      'mpg',
    };
    final lowerExt = ext?.toLowerCase();
    if (lowerExt != null && videoExts.contains(lowerExt)) return true;
    final lowerName = fileName.toLowerCase();
    for (final v in videoExts) {
      if (lowerName.endsWith('.$v')) return true;
    }
    return false;
  }

  String _mimeForVideo(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      case 'mkv':
        return 'video/x-matroska';
      case 'avi':
        return 'video/x-msvideo';
      case 'm4v':
        return 'video/x-m4v';
      case 'flv':
        return 'video/x-flv';
      case '3gp':
        return 'video/3gpp';
      case 'wmv':
        return 'video/x-ms-wmv';
      default:
        return 'video/${ext ?? 'mp4'}';
    }
  }
}
