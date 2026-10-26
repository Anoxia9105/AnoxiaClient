import 'package:anoxia/domain/ai_stream_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('只有明确的上游故障才计入入口熔断', () {
    for (final code in [
      'QUOTA_EXHAUSTED',
      'RATE_LIMITED',
      'INVALID_REQUEST',
      'FEATURE_DISABLED',
      'INTERNAL_ERROR',
    ]) {
      expect(AiException('提示', code: code).isUpstreamFailure, isFalse);
    }
    expect(const AiException('offline').isUpstreamFailure, isFalse);
    expect(
      const AiException('失败', code: 'UPSTREAM_ERROR').isUpstreamFailure,
      isTrue,
    );
  });

  test('SSE 错误保留机器码，旧服务端没有机器码时不误判', () {
    final failure = AiException.fromPayload({
      'message': '额度不足',
      'code': 'QUOTA_EXHAUSTED',
    });
    expect(failure.message, '额度不足');
    expect(failure.code, 'QUOTA_EXHAUSTED');
    expect(failure.isUpstreamFailure, isFalse);
    expect(
      AiException.fromPayload({'message': '请求失败'}).isUpstreamFailure,
      isFalse,
    );
  });
}
