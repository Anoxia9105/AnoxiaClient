import 'dart:ui' as ui;

import 'package:anoxia/framework/domain/sticker_pack.dart';
import 'package:anoxia/framework/provider/chat/sticker/sticker_packs_provider.dart';
import 'package:anoxia/framework/provider/core/sticker_repository_provider.dart';
import 'package:anoxia/framework/provider/core/upload_repository_provider.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:cross_file/cross_file.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 自定义表情包上传结果
class StickerUploadResult {
  final bool success;
  final int addedCount;
  final String? errorKey;

  const StickerUploadResult({
    this.success = false,
    this.addedCount = 0,
    this.errorKey,
  });
}

/// 自定义表情包操作状态
class CustomStickerState {
  /// 是否正在上传（含文件选择后的上传/入库过程）
  final bool uploading;

  /// 是否正在删除
  final bool deleting;

  const CustomStickerState({this.uploading = false, this.deleting = false});

  CustomStickerState copyWith({bool? uploading, bool? deleting}) {
    return CustomStickerState(
      uploading: uploading ?? this.uploading,
      deleting: deleting ?? this.deleting,
    );
  }
}

/// 用户自定义表情包控制器
///
/// 负责从本地选择图片、上传图片文件、创建/追加用户自定义表情包
/// 以及删除自定义表情包与单个表情。
///
/// 跨平台一致性：图片选择统一走 [FilePicker]（Web 端 bytes 已就绪，
/// 原生端按路径读取），上传走 [UploadRepository]（内部按平台转换
/// XFile），宽高由本地解码得出，表情面板与聊天气泡据此等比渲染。
class CustomStickerController extends Notifier<CustomStickerState> {
  static const int maxStickerCount = 20;
  static const int maxStickerBytes = 8 * 1024 * 1024;

  static const List<String> _imageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];

  @override
  CustomStickerState build() => const CustomStickerState();

  /// 选择图片并上传到自定义表情包
  ///
  /// 首次上传会创建一个「我的表情包」，后续上传追加到该包内。
  /// 成功后使 [stickerPacksProvider] 失效，表情面板自动刷新。
  Future<StickerUploadResult> uploadStickers() async {
    if (state.uploading) {
      return const StickerUploadResult();
    }

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _imageExtensions,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) {
      return const StickerUploadResult();
    }

    final files = result.files.where(_isImageFile).toList();
    if (files.isEmpty) {
      return const StickerUploadResult(
        errorKey: 'settings_sticker_no_image',
      );
    }
    if (files.length > maxStickerCount) {
      files.removeRange(maxStickerCount, files.length);
    }

    final xFiles = <XFile>[];
    for (final f in files) {
      xFiles.add(
        f.bytes != null
            ? XFile.fromData(f.bytes!, name: f.name)
            : XFile(f.path!),
      );
    }

    state = state.copyWith(uploading: true);
    try {
      final urls = await ref.read(uploadRepositoryProvider).uploadFiles(xFiles);
      if (urls.isEmpty) {
        return const StickerUploadResult(
          errorKey: 'settings_sticker_upload_failed',
        );
      }

      final packId = await _ensureCustomPack(urls.first);
      if (packId <= 0) {
        return const StickerUploadResult(
          errorKey: 'settings_sticker_upload_failed',
        );
      }

      var added = 0;
      final repository = ref.read(stickerRepositoryProvider);
      for (var i = 0; i < urls.length && i < xFiles.length; i++) {
        final (width, height) = await _decodeDimensions(xFiles[i]);
        final ok = await repository.addCustomSticker(
          packId,
          urls[i],
          width: width,
          height: height,
        );
        if (ok) added++;
      }
      if (added == 0) {
        return const StickerUploadResult(
          errorKey: 'settings_sticker_upload_failed',
        );
      }

      ref.invalidate(stickerPacksProvider);
      return StickerUploadResult(success: true, addedCount: added);
    } catch (e, st) {
      log.error('自定义表情包上传失败: $e\n$st');
      return const StickerUploadResult(
        errorKey: 'settings_sticker_upload_failed',
      );
    } finally {
      state = state.copyWith(uploading: false);
    }
  }

  /// 获取用户自定义表情包（未创建则新建）
  Future<int> _ensureCustomPack(String iconUrl) async {
    final repository = ref.read(stickerRepositoryProvider);
    try {
      final packs = await ref.refresh(stickerPacksProvider.future);
      for (final pack in packs) {
        if (pack.isCustom && pack.id > 0) return pack.id;
      }
    } catch (e, st) {
      log.warning('刷新表情包列表失败，将直接创建新表情包: $e\n$st');
    }
    return repository.createCustomPack(
      'settings_sticker_default_pack_name'.tr(),
      iconUrl: iconUrl,
    );
  }

  /// 删除用户自定义表情包
  Future<bool> deletePack(StickerPack pack) async {
    if (state.deleting || !pack.isCustom) return false;
    state = state.copyWith(deleting: true);
    try {
      final ok = await ref
          .read(stickerRepositoryProvider)
          .deleteCustomPack(pack.id);
      if (ok) ref.invalidate(stickerPacksProvider);
      return ok;
    } catch (e, st) {
      log.error('删除自定义表情包失败: $e\n$st');
      return false;
    } finally {
      state = state.copyWith(deleting: false);
    }
  }

  /// 删除用户自定义表情包内的单个表情
  Future<bool> deleteSticker(int stickerId) async {
    if (state.deleting) return false;
    state = state.copyWith(deleting: true);
    try {
      final ok = await ref
          .read(stickerRepositoryProvider)
          .deleteCustomSticker(stickerId);
      if (ok) ref.invalidate(stickerPacksProvider);
      return ok;
    } catch (e, st) {
      log.error('删除自定义表情失败: $e\n$st');
      return false;
    } finally {
      state = state.copyWith(deleting: false);
    }
  }

  bool _isImageFile(PlatformFile file) {
    // Web 端 bytes 已就绪、path 为 null；原生端 path 有值、bytes 为 null。
    final hasContent = file.bytes != null ||
        (file.path != null && file.path!.isNotEmpty);
    if (!hasContent || file.size > maxStickerBytes) return false;
    final name = file.name.toLowerCase();
    return _imageExtensions.any(name.endsWith);
  }

  /// 解码图片宽高（跨平台：Web/原生统一走 dart:ui 解码）
  Future<(int, int)> _decodeDimensions(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      try {
        final frame = await codec.getNextFrame();
        final image = frame.image;
        final size = (image.width, image.height);
        image.dispose();
        return size;
      } finally {
        codec.dispose();
      }
    } catch (_) {
      return (0, 0);
    }
  }
}

final customStickerControllerProvider = NotifierProvider.autoDispose<
    CustomStickerController, CustomStickerState>(CustomStickerController.new);
