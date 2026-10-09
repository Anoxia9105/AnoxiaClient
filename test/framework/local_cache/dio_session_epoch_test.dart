import 'dart:async';
import 'dart:io';

import 'package:anoxia/framework/local_cache/session_epoch.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final status in [200, 401]) {
    test('账号切换后拒绝过期 HTTP $status 响应并避免登出新账号', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var unauthorizedCalls = 0;
      final client = DioClient();
      client.configureAuth(
        tokenLoader: () async => 'test-token',
        onUnauthorized: () async {
          unauthorizedCalls++;
        },
      );
      addTearDown(() async {
        await server.close(force: true);
        client.configureAuth(
          tokenLoader: () async => null,
          onUnauthorized: () async {},
        );
      });
      final received = Completer<HttpRequest>();
      server.listen((request) => received.complete(request));
      final requestFuture = client.get(
        'http://127.0.0.1:${server.port}/session-test',
      );
      final assertion = expectLater(
        requestFuture,
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      final request = await received.future;
      SessionEpoch.instance.advance();
      request.response.statusCode = status;
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"code":$status,"data":{}}');
      await request.response.close();
      await assertion;
      expect(unauthorizedCalls, 0);
    });
  }
}
