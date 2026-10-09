import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:anoxia/domain/models/upload_file_result.dart';
import 'package:anoxia/common/utils/media_url_util.dart';
import 'package:anoxia/domain/repositories/upload_repository.dart';
import 'package:anoxia/framework/core/toast_service.dart';
import 'package:anoxia/framework/provider/chat/input/chat_file_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_image_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/delta_processor.dart';
import 'package:anoxia/framework/provider/core/toast_service_provider.dart';
import 'package:anoxia/framework/provider/core/upload_repository_provider.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Uploads implements UploadRepository {
  final completer = Completer<List<UploadFileResult>>();
  final ids = <String>[];
  final files = <XFile>[];
  int remainingFailures = 0;
  @override
  Future<List<UploadFileResult>> uploadFiles(
    List<XFile> files, {
    required List<String> clientFileIds,
    UploadProgressCallback? onProgress,
    UploadCompletedCallback? onCompleted,
    int? noteId,
  }) {
    this.files.addAll(files);
    ids.addAll(clientFileIds);
    if (remainingFailures > 0) {
      remainingFailures--;
      return Future.value([
        for (final id in clientFileIds)
          UploadFileResult(
            clientFileId: id,
            isSuccess: false,
            errorCode: 'NETWORK_ERROR',
          ),
      ]);
    }
    return completer.future.then(
      (_) => [
        for (final id in clientFileIds)
          UploadFileResult(
            clientFileId: id,
            isSuccess: true,
            url: 'https://files.test/$id',
          ),
      ],
    );
  }

  @override
  void cancelUpload(String clientFileId) {}
}

class _Toasts implements ToastService {
  final messages = <String>[];
  @override
  void showToast(
    String message, {
    ToastType type = ToastType.info,
    Alignment align = Alignment.bottomCenter,
    Duration duration = const Duration(seconds: 3),
  }) => messages.add(message);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late QuillController editor;
  late _Uploads uploads;
  late _Toasts toasts;
  setUp(() {
    uploads = _Uploads();
    toasts = _Toasts();
    container = ProviderContainer(
      overrides: [
        uploadRepositoryProvider.overrideWithValue(uploads),
        toastServiceProvider.overrideWithValue(toasts),
      ],
    );
    editor = QuillController.basic();
  });
  tearDown(() {
    editor.dispose();
    container.dispose();
  });

  test('桌面拖入的磁盘文件无需 bytes 也会发起上传', () async {
    final directory = Directory.systemTemp.createTempSync('drop_upload_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/anoxiaclient.lib')
      ..writeAsBytesSync([1, 2, 3]);
    await container
        .read(chatFileUploadControllerProvider.notifier)
        .insertPickedFiles(editor, [
          PlatformFile(name: 'anoxiaclient.lib', path: file.path, size: 3),
        ]);
    expect(uploads.files, hasLength(1));
    expect(await uploads.files.single.readAsBytes(), [1, 2, 3]);
    uploads.completer.complete([]);
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(chatFileUploadControllerProvider).values.single.isSuccess,
      isTrue,
    );
  });

  test('磁盘路径与待上传占位、网络地址区分', () {
    for (final path in [r'C:\Users\报告.pdf', 'C:/Users/报告.pdf', '/tmp/a.pdf']) {
      expect(isLocalMediaFilePath(path), isTrue);
    }
    for (final path in [
      null,
      '',
      'local-pending://id',
      'blob:id',
      'https://files.test/a',
      'file:///tmp/a',
    ]) {
      expect(isLocalMediaFilePath(path), isFalse);
    }
  });

  test('文档监听裁剪上传记录时，多文件插入保留每份源数据', () async {
    final uploader = container.read(chatFileUploadControllerProvider.notifier);
    editor.addListener(
      () => uploader.retain(
        DeltaProcessor(editor.document.toDelta(), {}).attachmentIds,
      ),
    );
    await uploader.insertPickedFiles(editor, [
      for (var i = 0; i < 2; i++)
        PlatformFile(name: '$i.txt', size: 1, bytes: Uint8List.fromList([i])),
    ]);
    expect(uploads.files, hasLength(2));
    expect(await uploads.files[1].readAsBytes(), [1]);
    uploads.completer.complete([]);
    await Future<void>.delayed(Duration.zero);
    expect(uploader.urlMap, hasLength(2));
  });

  test('失败附件可重试，连续点击不会重复请求或新增 embed', () async {
    uploads.remainingFailures = 3;
    final uploader = container.read(chatFileUploadControllerProvider.notifier);
    await uploader.insertPickedFiles(editor, [
      PlatformFile(name: 'file.txt', size: 1, bytes: Uint8List.fromList([1])),
    ]);
    final attachment = DeltaProcessor(
      editor.document.toDelta(),
      {},
    ).files.single;
    for (
      var i = 0;
      i < 100 &&
          container
                  .read(chatFileUploadControllerProvider)[attachment.id]
                  ?.isFailed !=
              true;
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    expect(
      container.read(chatFileUploadControllerProvider)[attachment.id]!.isFailed,
      isTrue,
    );
    final retry = uploader.retryUpload(attachment);
    await uploader.retryUpload(attachment);
    expect(uploads.files, hasLength(4));
    expect(uploads.ids.toSet(), {attachment.id});
    expect(DeltaProcessor(editor.document.toDelta(), {}).files, hasLength(1));
    expect(
      container
          .read(chatFileUploadControllerProvider)[attachment.id]!
          .isUploading,
      isTrue,
    );
    uploads.completer.complete([]);
    await retry;
    expect(
      container
          .read(chatFileUploadControllerProvider)[attachment.id]!
          .isSuccess,
      isTrue,
    );
    uploader.release(attachment.id!);
    await uploader.retryUpload(attachment);
    expect(uploads.files, hasLength(4));
  });

  test('桌面拖入的磁盘图片无需 bytes 也会发起上传', () async {
    final directory = Directory.systemTemp.createTempSync('drop_image_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/image.png')
      ..writeAsBytesSync([1, 2, 3]);
    await container
        .read(chatFileUploadControllerProvider.notifier)
        .insertPickedFiles(editor, [
          PlatformFile(name: 'image.png', path: file.path, size: 3),
        ]);
    expect(uploads.files, hasLength(1));
    expect(await uploads.files.single.readAsBytes(), [1, 2, 3]);
    uploads.completer.complete([]);
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(chatImageUploadControllerProvider).values.single.isSuccess,
      isTrue,
    );
  });

  test('拖入图片和文件保留原文，分流上传并等待上传完成', () async {
    editor.replaceText(0, 0, '草稿', const TextSelection.collapsed(offset: 2));
    await container
        .read(chatFileUploadControllerProvider.notifier)
        .insertPickedFiles(editor, [
          PlatformFile(
            name: '报告.pdf',
            size: 3,
            bytes: Uint8List.fromList([1, 2, 3]),
          ),
          // 无效图片字节允许回退未知尺寸，仍必须使用图片 embed 和图片上传链路。
          PlatformFile(
            name: '图片.png',
            size: 3,
            bytes: Uint8List.fromList([1, 2, 3]),
          ),
        ]);
    var processor = DeltaProcessor(editor.document.toDelta(), {});
    expect(editor.document.toPlainText(), contains('草稿'));
    expect(processor.images, hasLength(1));
    expect(processor.files, hasLength(1));
    expect(processor.isAllUploaded, isFalse);
    expect(uploads.files.map((f) => f.name), containsAll(['报告.pdf', '图片.png']));
    uploads.completer.complete([]);
    await Future<void>.delayed(Duration.zero);
    processor = DeltaProcessor(editor.document.toDelta(), {
      ...container.read(chatImageUploadControllerProvider.notifier).urlMap,
      ...container.read(chatFileUploadControllerProvider.notifier).urlMap,
    });
    expect(processor.isAllUploaded, isTrue);
    expect(processor.images.single.url, startsWith('https://files.test/'));
    expect(processor.files.single.url, startsWith('https://files.test/'));
  });

  test('数量、单文件和总大小限制在拖放入口生效', () async {
    final uploader = container.read(chatFileUploadControllerProvider.notifier);
    await uploader.insertPickedFiles(editor, [
      for (var i = 0; i < 11; i++) PlatformFile(name: '$i.txt', size: 1),
    ]);
    expect(editor.document.isEmpty(), isTrue);
    await uploader.insertPickedFiles(editor, [
      PlatformFile(name: 'large.txt', size: 51 * 1024 * 1024),
    ]);
    expect(editor.document.isEmpty(), isTrue);
    await uploader.insertPickedFiles(editor, [
      for (var i = 0; i < 3; i++)
        PlatformFile(name: '$i.txt', size: 40 * 1024 * 1024),
    ]);
    expect(editor.document.isEmpty(), isTrue);
    expect(toasts.messages, hasLength(3));
    expect(uploads.files, isEmpty);
  });

  test('图片元数据异步读取期间失效，整批附件不插入或上传', () async {
    var active = true;
    final future = container
        .read(chatFileUploadControllerProvider.notifier)
        .insertPickedFiles(editor, [
          PlatformFile(
            name: 'file.txt',
            size: 1,
            bytes: Uint8List.fromList([1]),
          ),
          PlatformFile(
            name: 'image.png',
            size: 1,
            bytes: Uint8List.fromList([1]),
          ),
        ], isActive: () => active);
    active = false;
    await future;
    expect(editor.document.isEmpty(), isTrue);
    expect(uploads.files, isEmpty);
    expect(container.read(chatFileUploadControllerProvider), isEmpty);
    expect(container.read(chatImageUploadControllerProvider), isEmpty);
  });

  test('编辑器没有光标时文件追加到现有草稿末尾', () async {
    editor.replaceText(0, 0, '原文', const TextSelection.collapsed(offset: 2));
    editor.updateSelection(
      const TextSelection.collapsed(offset: -1),
      ChangeSource.local,
    );
    await container
        .read(chatFileUploadControllerProvider.notifier)
        .insertPickedFiles(editor, [
          PlatformFile(
            name: 'file.txt',
            size: 1,
            bytes: Uint8List.fromList([1]),
          ),
        ]);
    expect(editor.document.toPlainText(), startsWith('原文'));
    expect(DeltaProcessor(editor.document.toDelta(), {}).files, hasLength(1));
    uploads.completer.complete([]);
    await Future<void>.delayed(Duration.zero);
  });
}
