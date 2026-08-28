import 'dart:typed_data';

import 'package:anoxia/domain/models/upload_file_result.dart';
import 'package:anoxia/domain/repositories/upload_repository.dart';
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:anoxia/framework/provider/chat/input/chat_file_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_image_upload_controller.dart';
import 'package:anoxia/framework/provider/core/upload_repository_provider.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SuccessfulUploadRepository implements UploadRepository {
  @override
  Future<List<UploadFileResult>> uploadFiles(
    List<XFile> files, {
    required List<String> clientFileIds,
    UploadProgressCallback? onProgress,
  }) async => [
    for (var index = 0; index < files.length; index++)
      UploadFileResult(
        clientFileId: clientFileIds[index],
        isSuccess: true,
        url: 'https://example.test/upload-$index',
        coverUrl: 'https://example.test/cover-$index.jpg',
        durationMs: 42000,
        width: 1920,
        height: 1080,
        bitrate: 2000000,
      ),
  ];

  @override
  void cancelUpload(String clientFileId) {}
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        uploadRepositoryProvider.overrideWithValue(
          _SuccessfulUploadRepository(),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test(
    'direct image upload registers picked bytes and publishes its URL',
    () async {
      final picked = PlatformFile(
        name: 'photo.png',
        size: 3,
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      const attachment = Attachment(
        id: 'image-id',
        kind: 'IMAGE',
        name: 'photo.png',
        type: 'image/png',
      );

      await container
          .read(chatImageUploadControllerProvider.notifier)
          .uploadImages([attachment], pickedFiles: {'image-id': picked});

      expect(
        container.read(chatImageUploadControllerProvider.notifier).urlMap,
        {'image-id': 'https://example.test/upload-0'},
      );
    },
  );

  test(
    'direct file upload registers state before publishing its URL',
    () async {
      final picked = PlatformFile(
        name: 'notes.txt',
        size: 3,
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      const attachment = Attachment(
        id: 'file-id',
        kind: 'FILE',
        name: 'notes.txt',
        type: 'txt',
      );

      await container
          .read(chatFileUploadControllerProvider.notifier)
          .uploadFiles([attachment], pickedFiles: {'file-id': picked});

      expect(container.read(chatFileUploadControllerProvider.notifier).urlMap, {
        'file-id': 'https://example.test/upload-0',
      });
    },
  );

  test('video upload preserves server media metadata', () async {
    final picked = PlatformFile(
      name: 'clip.mp4',
      size: 3,
      bytes: Uint8List.fromList([1, 2, 3]),
    );
    const attachment = Attachment(
      id: 'video-id',
      kind: 'VIDEO',
      name: 'clip.mp4',
      type: 'video/mp4',
    );

    await container
        .read(chatFileUploadControllerProvider.notifier)
        .uploadFiles([attachment], pickedFiles: {'video-id': picked});

    final result = container
        .read(chatFileUploadControllerProvider.notifier)
        .uploadResultOf('video-id');
    expect(result?.coverUrl, 'https://example.test/cover-0.jpg');
    expect(result?.durationMs, 42000);
    expect(result?.width, 1920);
    expect(result?.height, 1080);
    expect(result?.bitrate, 2000000);
  });
}
