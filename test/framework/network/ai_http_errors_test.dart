import 'package:anoxia/domain/ai_stream_event.dart';
import 'package:anoxia/framework/network/sse_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  for (final status in [404, 405, 429]) {
    test('HTTP $status 提供明确分类且不回退到持久会话', () async {
      var requests = 0;
      await http.runWithClient(
        () async {
          await expectLater(
            SseClient.post(
              '/chat/ai/replies/stream',
              body: const {'draft': 'hello'},
            ).toList(),
            throwsA(
              isA<AiException>().having(
                (e) => e.code,
                'code',
                status == 429 ? 'RATE_LIMITED' : 'ENDPOINT_UNAVAILABLE',
              ),
            ),
          );
        },
        () => MockClient((request) async {
          requests++;
          expect(request.url.path, endsWith('/chat/ai/replies/stream'));
          return http.Response(
            '{"message":"拒绝"}',
            status,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      expect(requests, 1);
    });
  }
  test('HTTP 200 普通 JSON 业务错误保留提示，而不是当作空 SSE', () async {
    await http.runWithClient(
      () async {
        await expectLater(
          SseClient.post('/chat/ai/stream').toList(),
          throwsA(
            isA<AiException>().having((e) => e.message, 'message', '登录过期'),
          ),
        );
      },
      () => MockClient(
        (_) async => http.Response(
          '{"message":"登录过期"}',
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
  });
}
