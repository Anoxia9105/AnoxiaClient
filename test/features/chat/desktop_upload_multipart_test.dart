import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anoxia/data/repositories/upload_repository_impl.dart';
import 'package:anoxia/features/chat/presentation/widgets/desktop_drop_files.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:anoxia/framework/network/dio_config.dart';
import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _UploadAdapter implements HttpClientAdapter {
  String? body;
  RequestOptions? request;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    final bytes = <int>[];
    await for (final chunk in requestStream!) {
      bytes.addAll(chunk);
    }
    body = utf8.decode(bytes);
    return ResponseBody.fromString(
      jsonEncode({
        'code': 200,
        'data': {
          'clientFileId': 'drop1',
          'url': 'https://files.test/report.lib',
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('拖入文件经过真实仓库和 Dio 生成正确 multipart 数据', () async {
    final directory = Directory.systemTemp.createTempSync('multipart_drop_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/报告.lib')
      ..writeAsStringSync('native file content');
    final prepared = await prepareDesktopDropFiles([XFile(file.path)]);
    final picked = prepared.files.single;
    final dio = DioConfig().createDio();
    final adapter = _UploadAdapter();
    final previousAdapter = dio.httpClientAdapter;
    dio.httpClientAdapter = adapter;
    addTearDown(() => dio.httpClientAdapter = previousAdapter);
    DioClient().configureAuth(
      tokenLoader: () async => null,
      onUnauthorized: () async {},
    );
    final results = await UploadRepositoryImpl().uploadFiles(
      [
        XFile(
          picked.path!,
          name: picked.name,
          mimeType: 'application/octet-stream',
        ),
      ],
      clientFileIds: ['drop1'],
    );
    expect(results.single.isSuccess, isTrue);
    expect(adapter.request!.path, '/file/uploadV2');
    expect(
      adapter.request!.contentType,
      startsWith('multipart/form-data; boundary='),
    );
    expect(adapter.body, contains('filename="报告.lib"'));
    expect(adapter.body, contains('native file content'));
    expect(adapter.body, contains('name="clientFileId"'));
    expect(adapter.body, contains('drop1'));
  });
}
