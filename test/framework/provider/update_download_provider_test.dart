import 'dart:async';
import 'dart:io';

import 'package:anoxia/framework/domain/app_update_info.dart';
import 'package:anoxia/framework/provider/setting/update_check_provider.dart';
import 'package:anoxia/framework/provider/setting/update_download_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoUpdateChecker extends AppUpdateCheckerNotifier {
  @override
  AppUpdateInfo? build() => null;
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late HttpServer server;
  late ProviderContainer container;
  final bytes = List<int>.generate(16384, (i) => i % 251);
  setUp(() async {
    HttpOverrides.global = null;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    directory = await Directory.systemTemp.createTemp(
      'anoxia-update-provider-',
    );
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  });
  tearDown(() async {
    container.dispose();
    await server.close(force: true);
    await directory.delete(recursive: true);
    debugDefaultTargetPlatformOverride = null;
  });

  void createContainer(Future<String> Function() resolveSaveDir) {
    container = ProviderContainer(
      overrides: [
        appUpdateCheckerProvider.overrideWith(_NoUpdateChecker.new),
        updateDownloadControllerProvider.overrideWith(
          () => UpdateDownloadController(resolveSaveDir: resolveSaveDir),
        ),
      ],
    );
  }

  AppUpdateInfo info(String version, {String hash = ''}) => AppUpdateInfo(
    hasUpdate: true,
    latestVersion: version,
    downloadUrl: 'http://${server.address.address}:${server.port}/app.apk',
    releaseNotes: '',
    fileSize: bytes.length,
    fileHash: hash,
  );

  test('目录解析期间重复点击只创建一个任务，reset 后旧任务不能回写', () async {
    final resolve = Completer<String>();
    var resolves = 0;
    createContainer(() {
      resolves++;
      return resolve.future;
    });
    final controller = container.read(
      updateDownloadControllerProvider.notifier,
    );
    final first = controller.startDownload(info('1.0.0'));
    await controller.startDownload(info('1.0.0'));
    await Future<void>.delayed(Duration.zero);
    expect(resolves, 1);
    controller.reset();
    resolve.complete(directory.path);
    await first;
    expect(
      container.read(updateDownloadControllerProvider).phase,
      UpdateDownloadPhase.idle,
    );
  });

  test('下载中切换版本，旧取消回调不能覆盖新版本进度或就绪状态', () async {
    createContainer(() async => directory.path);
    var requests = 0;
    server.listen((request) async {
      requests++;
      request.response.bufferOutput = false;
      request.response.contentLength = bytes.length;
      if (requests == 1) {
        request.response.add(bytes.sublist(0, 4096));
        await request.response.flush();
      } else {
        request.response.add(bytes);
        await request.response.close();
      }
    });
    final received = Completer<void>();
    container.listen(updateDownloadControllerProvider, (_, next) {
      if (next.receivedBytes > 0 && !received.isCompleted) received.complete();
    });
    final controller = container.read(
      updateDownloadControllerProvider.notifier,
    );
    final first = controller.startDownload(info('1.0.0'));
    await received.future.timeout(const Duration(seconds: 5));
    await controller
        .startDownload(info('2.0.0'))
        .timeout(const Duration(seconds: 5));
    await first;
    final state = container.read(updateDownloadControllerProvider);
    expect(state.phase, UpdateDownloadPhase.ready);
    expect(state.version, '2.0.0');
    expect(await File(state.filePath).readAsBytes(), bytes);
    expect(requests, 2);
  });

  test('恢复后的安装包仍须通过 SHA-256 校验', () async {
    createContainer(() async => directory.path);
    server.listen((request) async {
      request.response.add(bytes);
      await request.response.close();
    });
    await container
        .read(updateDownloadControllerProvider.notifier)
        .startDownload(info('1.0.0', hash: '00'));
    final state = container.read(updateDownloadControllerProvider);
    expect(state.phase, UpdateDownloadPhase.failed);
    expect(state.errorMessage, 'update_error_generic_safe');
    expect(await directory.list().toList(), isEmpty);
  });
  test('控制器暂停可恢复同一任务，重复开始不会覆盖暂停状态', () async {
    createContainer(() async => directory.path);
    final received = Completer<void>();
    var requests = 0;
    server.listen((request) async {
      requests++;
      request.response.bufferOutput = false;
      request.response.headers.set('etag', '"provider-pause"');
      final range = request.headers.value('range');
      final offset = range == null
          ? 0
          : int.parse(range.replaceAll(RegExp(r'[^0-9]'), ''));
      if (offset > 0) {
        request.response.statusCode = HttpStatus.partialContent;
        request.response.headers.set(
          'content-range',
          'bytes $offset-${bytes.length - 1}/${bytes.length}',
        );
      }
      request.response.contentLength = bytes.length - offset;
      request.response.add(
        bytes.sublist(offset, requests == 1 ? 4096 : bytes.length),
      );
      await request.response.flush();
      if (requests > 1) {
        await request.response.close();
      }
    });
    container.listen(updateDownloadControllerProvider, (_, next) {
      if (next.receivedBytes >= 4096 && !received.isCompleted) {
        received.complete();
      }
    });
    final controller = container.read(
      updateDownloadControllerProvider.notifier,
    );
    final task = controller.startDownload(info('3.0.0'));
    await received.future.timeout(const Duration(seconds: 5));
    controller.pauseDownload();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(
      container.read(updateDownloadControllerProvider).phase,
      UpdateDownloadPhase.paused,
    );
    await controller.startDownload(info('3.0.0'));
    expect(
      container.read(updateDownloadControllerProvider).phase,
      UpdateDownloadPhase.paused,
    );
    expect(requests, 1);
    controller.resumeDownload();
    await task.timeout(const Duration(seconds: 5));
    final ready = container.read(updateDownloadControllerProvider);
    expect(ready.phase, UpdateDownloadPhase.ready);
    expect(await File(ready.filePath).readAsBytes(), bytes);
    expect(requests, 2);
  });
}
