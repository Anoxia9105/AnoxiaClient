import 'dart:async';
import 'dart:io';

import 'package:anoxia/framework/network/update_package_downloader.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late HttpServer server;
  late Directory directory;
  late UpdatePackageDownloader downloader;
  final bytes = List<int>.generate(16384, (i) => i % 251);

  setUp(() async {
    // 此集成测试仅访问本地 HttpServer，使用真实 socket。
    HttpOverrides.global = null;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    directory = await Directory.systemTemp.createTemp('anoxia-update-test-');
    downloader = UpdatePackageDownloader();
  });
  tearDown(() async {
    downloader.dispose();
    await server.close(force: true);
    await directory.delete(recursive: true);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    debugDefaultTargetPlatformOverride = null;
  });

  String url() => 'http://${server.address.address}:${server.port}/app.apk';
  String savePath() => '${directory.path}/app.apk';

  test('锁屏期间不失败，返回前台后从已下载字节恢复', () async {
    final firstChunk = Completer<void>();
    final requests = <String?>[];
    server.listen((request) async {
      requests.add(request.headers.value('range'));
      request.response.headers.set('etag', '"package-v1"');
      if (requests.length == 1) {
        request.response.bufferOutput = false;
        request.response.contentLength = bytes.length;
        request.response.add(bytes.sublist(0, 4096));
        await request.response.flush();
      } else {
        expect(request.headers.value('if-range'), '"package-v1"');
        final offset = int.parse(
          request.headers.value('range')!.replaceAll(RegExp(r'[^0-9]'), ''),
        );
        request.response.statusCode = HttpStatus.partialContent;
        request.response.headers.set(
          'content-range',
          'bytes $offset-${bytes.length - 1}/${bytes.length}',
        );
        request.response.contentLength = bytes.length - offset;
        request.response.add(bytes.sublist(offset));
        await request.response.close();
      }
    });
    var failed = false;
    final result = downloader.download(
      url(),
      savePath(),
      cancelToken: CancelToken(),
      onReceiveProgress: (received, total) {
        if (received >= 4096 && !firstChunk.isCompleted) firstChunk.complete();
      },
    );
    unawaited(
      result.catchError((Object _) {
        failed = true;
      }),
    );
    await firstChunk.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw StateError('first chunk not received'),
    );
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(failed, isFalse);
    expect(requests, hasLength(1));
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await result.timeout(
      const Duration(seconds: 5),
      onTimeout: () =>
          throw StateError('foreground recovery stalled: $requests'),
    );
    expect(await File(savePath()).readAsBytes(), bytes);
    expect(requests, hasLength(2));
  });

  test('连接中断后自动重试，服务器忽略 Range 时从头覆盖而不拼坏文件', () async {
    var requests = 0;
    server.listen((request) async {
      requests++;
      request.response.headers.set('etag', '"package-v1"');
      request.response.contentLength = bytes.length;
      if (requests == 1) {
        final socket = await request.response.detachSocket(writeHeaders: false);
        socket.write(
          'HTTP/1.1 200 OK\r\nContent-Length: ${bytes.length}\r\n'
          'ETag: "package-v1"\r\n\r\n',
        );
        socket.add(bytes.sublist(0, 4096));
        await socket.flush();
        socket.destroy();
      } else {
        request.response.add(bytes);
        await request.response.close();
      }
    });
    await downloader
        .download(url(), savePath(), cancelToken: CancelToken())
        .timeout(const Duration(seconds: 10));
    expect(requests, 2);
    expect(await File(savePath()).readAsBytes(), bytes);
  });

  test('404 不自动重试，也不写入错误页', () async {
    var requests = 0;
    server.listen((request) async {
      requests++;
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('not found');
      await request.response.close();
    });
    await expectLater(
      downloader.download(url(), savePath(), cancelToken: CancelToken()),
      throwsA(isA<DioException>()),
    );
    expect(requests, 1);
    expect(await File(savePath()).exists(), isFalse);
  });

  test('后台等待期间可以取消，不必等到再次进入前台', () async {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    var requests = 0;
    server.listen((request) {
      requests++;
    });
    final token = CancelToken();
    final result = downloader.download(url(), savePath(), cancelToken: token);
    final assertion = expectLater(
      result,
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.cancel,
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    token.cancel('user reset');
    await assertion.timeout(const Duration(seconds: 2));
    expect(requests, 0);
  });

  test('隐藏到 inactive 期间保持暂停，只有 resumed 才恢复', () async {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    var requests = 0;
    server.listen((request) async {
      requests++;
      request.response.add(bytes);
      await request.response.close();
    });
    final result = downloader.download(
      url(),
      savePath(),
      cancelToken: CancelToken(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(requests, 0);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await result.timeout(const Duration(seconds: 3));
    expect(await File(savePath()).readAsBytes(), bytes);
  });

  test('持续服务端错误只有限重试，保留明确失败结果', () async {
    var requests = 0;
    server.listen((request) async {
      requests++;
      request.response.statusCode = HttpStatus.serviceUnavailable;
      await request.response.close();
    });
    await expectLater(
      downloader.download(url(), savePath(), cancelToken: CancelToken()),
      throwsA(isA<DioException>()),
    ).timeout(const Duration(seconds: 12));
    expect(requests, 4);
  });

  test('连续锁屏两次仍能续传，保留的进度不重复写入', () async {
    final chunks = [Completer<void>(), Completer<void>()];
    var requests = 0;
    server.listen((request) async {
      requests++;
      final range = request.headers.value('range');
      final offset = range == null
          ? 0
          : int.parse(range.replaceAll(RegExp(r'[^0-9]'), ''));
      request.response.bufferOutput = false;
      request.response.headers.set('etag', '"package-v1"');
      if (offset > 0) {
        request.response.statusCode = HttpStatus.partialContent;
        request.response.headers.set(
          'content-range',
          'bytes $offset-${bytes.length - 1}/${bytes.length}',
        );
      }
      request.response.contentLength = bytes.length - offset;
      request.response.add(
        bytes.sublist(offset, requests < 3 ? offset + 4096 : bytes.length),
      );
      await request.response.flush();
      if (requests == 3) await request.response.close();
    });
    final result = downloader.download(
      url(),
      savePath(),
      cancelToken: CancelToken(),
      onReceiveProgress: (received, _) {
        for (var i = 0; i < chunks.length; i++) {
          if (received >= (i + 1) * 4096 && !chunks[i].isCompleted) {
            chunks[i].complete();
          }
        }
      },
    );
    for (final chunk in chunks) {
      await chunk.future.timeout(const Duration(seconds: 3));
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    }
    await result.timeout(const Duration(seconds: 3));
    expect(requests, 3);
    expect(await File(savePath()).readAsBytes(), bytes);
  });
  test('手动暂停保留字节，锁屏再回前台不能覆盖手动暂停意图', () async {
    final chunk = Completer<void>();
    var requests = 0;
    final pauses = <bool>[];
    server.listen((request) async {
      requests++;
      request.response.headers.set('etag', '"manual-pause"');
      request.response.bufferOutput = false;
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
      if (requests > 1) await request.response.close();
    });
    final result = downloader.download(
      url(),
      savePath(),
      cancelToken: CancelToken(),
      onPauseChanged: pauses.add,
      onReceiveProgress: (received, _) {
        if (received >= 4096 && !chunk.isCompleted) chunk.complete();
      },
    );
    await chunk.future.timeout(const Duration(seconds: 5));
    downloader.pause();
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(requests, 1);
    expect(pauses.last, isTrue);
    expect(await File(savePath()).length(), 4096);
    downloader.resume();
    await result.timeout(const Duration(seconds: 5));
    expect(requests, 2);
    expect(pauses.last, isFalse);
    expect(await File(savePath()).readAsBytes(), bytes);
  });
}
