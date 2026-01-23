import 'dart:io';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:anoxia/framework/network/DioClient.dart';

part 'chat_upload_provider.g.dart';

/// 上传状态（UI 用）
@Riverpod(keepAlive: true)
class IsUploading extends _$IsUploading {
  @override
  bool build() => false;

  void start() => state = true;
  void stop() => state = false;
}

@Riverpod(keepAlive: true)
class ChatUploadController extends _$ChatUploadController {
  @override
  void build() {}

  /// 上传多个文件，返回 uuid -> url
  Future<Map<String, String>> uploadImages(List<PendingImage> images) async {
    Toast.showToast("文件上传中...");

    try {
      final res = await DioClient().uploadFiles(
        "/file/uploadBatch",
        files: images.map((e) => e.file).toList(),
      );

      if (res.data is! List) return {};

      final List data = res.data as List;
      final Map<String, String> result = {};

      for (int i = 0; i < images.length && i < data.length; i++) {
        result[images[i].id] = data[i].toString();
      }

      return result;
    } catch (e) {
      log.error("上传失败");
      return {};
    } finally {
      ref.read(isUploadingProvider.notifier).stop();
    }
  }
}

class PendingImage {
  final String id;
  final File file;

  PendingImage({required this.id, required this.file});
}
