import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:anoxia/common/utils/quill_embed_util.dart';
import 'package:anoxia/framework/provider/core/toast_service_provider.dart';
import 'package:anoxia/framework/provider/core/upload_repository_provider.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:anoxia/framework/provider/chat/input/upload_validator.dart';
import 'package:anoxia/framework/domain/upload_entry.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'chat_image_upload_controller.g.dart';

/// 聊天图片上传控制器
///
/// 处理图片选择、粘贴和上传功能。采用 keepAlive 模式确保跨页面共享状态。
///
/// 核心流程：
/// 1. 用户选择/粘贴图片 → 2. 创建 Attachment 对象 → 3. 标记为上传中 →
/// 4. 插入编辑器 → 5. 后台上传 → 6. 更新上传状态
///
/// 状态管理：Map<文件ID, UploadEntry>，支持同时处理多个文件上传
@Riverpod(keepAlive: true)
class ChatImageUploadController extends _$ChatImageUploadController {
  static const int _maxUploadRetries = 3;

  /// Web 端 PlatformFile.path 为 null，文件内容在 bytes 中，
  /// 按附件 ID 暂存，供上传时构建 XFile 使用
  final Map<String, PlatformFile> _filesById = {};

  @override
  Map<String, UploadEntry> build() => {};

  /// 处理粘贴图片
  ///
  /// [controller] Quill 编辑器控制器
  /// [imageBytes] 粘贴的图片字节数据
  ///
  /// 流程：验证 → 保存临时文件 → 创建 Attachment → 标记上传中 → 插入编辑器 → 后台上传
  Future<void> handlePastedImage(
    QuillController controller,
    Uint8List imageBytes,
  ) async {
    try {
      final tempFile = PlatformFile(
        name: 'pasted_image.jpg',
        size: imageBytes.lengthInBytes,
        bytes: imageBytes,
      );
      final toast = ref.read(toastServiceProvider);
      if (!UploadValidator.validate(toast, controller, [tempFile])) return;
      if (!UploadValidator.validateSingleFile(toast, tempFile)) return;

      final id = const Uuid().v4();
      final imageSize = await _readImageSizeFromBytes(imageBytes);
      String? localUrl;
      if (kIsWeb) {
        _filesById[id] = tempFile;
      } else {
        final rawFile = File(
          p.join(Directory.systemTemp.path, 'pasted_$id.jpg'),
        );
        await rawFile.writeAsBytes(imageBytes);
        localUrl = rawFile.path;
      }

      final attachment = Attachment(
        id: id,
        kind: 'IMAGE',
        url: localUrl,
        name: 'pasted_image',
        size: imageBytes.lengthInBytes,
        type: 'image/jpeg',
        width: imageSize.$1,
        height: imageSize.$2,
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
      debugLog('处理粘贴图片失败: $e', st);
    }
  }

  /// 从相册选择图片
  ///
  /// [controller] Quill 编辑器控制器
  ///
  /// 弹出文件选择器，允许用户选择多张图片，验证通过后插入编辑器并后台上传
  Future<void> selectImages(QuillController controller) async {
    // final result = await FilePicker.platform.pickFiles(
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.image,
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
      final imageSize = file.path != null
          ? await _readImageSizeFromFile(file.path!)
          : await _readImageSizeFromBytes(file.bytes ?? Uint8List(0));
      uploadList.add(
        Attachment(
          id: id,
          kind: 'IMAGE',
          url: file.path,
          name: file.name,
          size: file.size,
          type: _imageMimeType(file.extension),
          width: imageSize.$1,
          height: imageSize.$2,
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

  /// 上传图片到服务器
  ///
  /// [images] 要上传的图片附件列表
  ///
  /// 使用批量上传接口，上传成功后更新状态为成功，失败则标记为失败
  Future<void> uploadImages(
    List<Attachment> images, {
    Map<String, PlatformFile>? pickedFiles,
  }) async {
    if (images.isEmpty) return;
    if (pickedFiles != null) _filesById.addAll(pickedFiles);
    _markUploading(images);

    var pendingFiles = <XFile>[];
    var pendingImages = <Attachment>[];
    for (final i in images) {
      final local = _filesById[i.id];
      if (local?.bytes != null) {
        pendingFiles.add(
          XFile.fromData(local!.bytes!, name: i.name ?? local.name),
        );
        pendingImages.add(i);
      } else if (i.url != null && i.url!.isNotEmpty) {
        pendingFiles.add(XFile(i.url!));
        pendingImages.add(i);
      }
    }
    if (pendingFiles.isEmpty) {
      _markFailed(images);
      return;
    }

    for (int attempt = 1; attempt <= _maxUploadRetries; attempt++) {
      final bool isLastAttempt = attempt == _maxUploadRetries;
      try {
        final results = await ref
            .read(uploadRepositoryProvider)
            .uploadFiles(
              pendingFiles,
              clientFileIds: pendingImages.map((image) => image.id!).toList(),
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

        final failedIds = results
            .where(
              (result) => !result.isSuccess && result.errorCode != 'CANCELLED',
            )
            .map((result) => result.clientFileId)
            .toSet();
        final nextFiles = <XFile>[];
        final nextImages = <Attachment>[];
        for (var i = 0; i < pendingImages.length; i++) {
          if (failedIds.contains(pendingImages[i].id)) {
            nextFiles.add(pendingFiles[i]);
            nextImages.add(pendingImages[i]);
          }
        }
        pendingFiles = nextFiles;
        pendingImages = nextImages;
        if (pendingFiles.isEmpty) return;
        if (isLastAttempt) _markFailed(pendingImages);
      } catch (e, st) {
        debugLog('[ImageUpload] 第$attempt次上传异常: $e', st);
        if (isLastAttempt) {
          _markFailed(pendingImages);
          return;
        }
      }

      final delayMs = 400 * (1 << (attempt - 1));
      await Future.delayed(Duration(milliseconds: delayMs));
    }
  }

  /// 标记图片为上传中状态
  void _markUploading(List<Attachment> images) {
    state = {...state, for (final i in images) i.id!: UploadEntry.uploading};
  }

  /// 标记图片为上传失败状态
  void _markFailed(List<Attachment> images) {
    final failed = <String, UploadEntry>{
      for (final i in images)
        if (state.containsKey(i.id)) i.id!: UploadEntry.failed,
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
    }
    state = Map.of(state)..removeWhere((id, _) => !ids.contains(id));
  }

  /// 供 DeltaProcessor 使用：只返回上传成功的 id -> url 映射
  Map<String, String> get urlMap => {
    for (final e in state.entries)
      if (e.value.isSuccess) e.key: e.value.serverUrl!,
  };

  /// 获取附件对应的内存字节（Web 端本地预览用），无则返回 null
  Uint8List? bytesOf(String? id) => _filesById[id]?.bytes;

  /// 消息发送后调用，清理 state
  void clear() => state = {};

  Future<(int?, int?)> _readImageSizeFromBytes(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final size = (image.width, image.height);
      image.dispose();
      codec.dispose();
      return size;
    } catch (_) {
      return (null, null);
    }
  }

  Future<(int?, int?)> _readImageSizeFromFile(String path) async {
    try {
      return _readImageSizeFromBytes(await File(path).readAsBytes());
    } catch (_) {
      return (null, null);
    }
  }

  String _imageMimeType(String? extension) {
    final ext = extension?.toLowerCase();
    if (ext == null || ext.isEmpty) return 'image/jpeg';
    if (ext == 'jpg') return 'image/jpeg';
    return 'image/$ext';
  }
}
