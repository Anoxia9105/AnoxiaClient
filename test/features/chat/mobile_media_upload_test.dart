import 'dart:io';
import 'package:anoxia/common/widgets/attachment_image_view.dart';
import 'package:flutter/painting.dart';

import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:anoxia/framework/provider/chat/input/chat_image_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_file_upload_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anoxia/domain/repositories/upload_repository.dart';
import 'package:anoxia/domain/models/upload_file_result.dart';
import 'package:anoxia/framework/provider/core/upload_repository_provider.dart';
import 'package:cross_file/cross_file.dart';

class _Uploads implements UploadRepository {
  final contents = <List<int>>[];
  @override
  Future<List<UploadFileResult>> uploadFiles(
    List<XFile> files, {
    required List<String> clientFileIds,
    UploadProgressCallback? onProgress,
    UploadCompletedCallback? onCompleted,
    int? noteId,
  }) async {
    for (final file in files) {
      contents.add(await file.readAsBytes());
    }
    return [
      for (final id in clientFileIds)
        UploadFileResult(
          clientFileId: id,
          isSuccess: true,
          url: 'https://files.test/$id',
        ),
    ];
  }

  @override
  void cancelUpload(String clientFileId) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final image in [true, false]) {
    test('本地 file URI ${image ? "图片" : "文件"}可上传而非立即失败', () async {
      final directory = Directory.systemTemp.createTempSync('mobile_upload_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final file = File('${directory.path}/带空格 image.png')
        ..writeAsBytesSync([1, 2, 3]);
      final preview = AttachmentImageView.resolveImageProvider(
        file.uri.toString(),
      );
      expect(preview, isA<FileImage>());
      expect((preview! as FileImage).file.uri, file.uri);
      final uploads = _Uploads();
      final container = ProviderContainer(
        overrides: [uploadRepositoryProvider.overrideWithValue(uploads)],
      );
      addTearDown(container.dispose);
      final attachment = Attachment(
        id: 'mobile',
        name: image ? 'image.png' : 'file.txt',
        url: file.uri.toString(),
      );
      if (image) {
        await container
            .read(chatImageUploadControllerProvider.notifier)
            .uploadImages([attachment]);
        expect(
          container
              .read(chatImageUploadControllerProvider)['mobile']!
              .isSuccess,
          isTrue,
        );
      } else {
        await container
            .read(chatFileUploadControllerProvider.notifier)
            .uploadFiles([attachment]);
        expect(
          container.read(chatFileUploadControllerProvider)['mobile']!.isSuccess,
          isTrue,
        );
      }
      expect(uploads.contents, [
        [1, 2, 3],
      ]);
    });
  }
}
