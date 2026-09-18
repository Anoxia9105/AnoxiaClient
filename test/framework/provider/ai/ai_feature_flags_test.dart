import 'package:anoxia/framework/provider/ai/ai_feature_flags_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('aiFeatureFlagsFromMap 解析', () {
    test('health 熔断时聊天与记事本同时不可用', () {
      final flags = aiFeatureFlagsFromMap(const {
        'available': false,
        'reason': 'upstream_error',
        'chatEnabled': true,
        'noteEnabled': true,
      });

      expect(flags.available, isFalse);
      expect(flags.reason, 'upstream_error');
      expect(flags.chatAvailable, isFalse);
      expect(flags.noteAvailable, isFalse);
      expect(flags.anyEnabled, isFalse);
    });

    test('人工关闭聊天时仅记事本可用', () {
      final flags = aiFeatureFlagsFromMap(const {
        'available': true,
        'reason': 'ok',
        'chatEnabled': false,
        'noteEnabled': true,
      });

      expect(flags.chatAvailable, isFalse);
      expect(flags.noteAvailable, isTrue);
      expect(flags.anyEnabled, isTrue);
    });

    test('老 models 接口无 available 字段时 fail-open', () {
      final flags = aiFeatureFlagsFromMap(const {
        'chatEnabled': true,
        'noteEnabled': false,
        'healthReason': 'ok',
      });

      expect(flags.available, isTrue);
      expect(flags.reason, 'ok');
      expect(flags.chatAvailable, isTrue);
      expect(flags.noteAvailable, isFalse);
    });

    test('空响应默认全部可用（避免误隐藏）', () {
      final flags = aiFeatureFlagsFromMap(null);

      expect(flags.chatAvailable, isTrue);
      expect(flags.noteAvailable, isTrue);
      expect(flags.anyEnabled, isTrue);
    });

    test('copyWith 只改可用性', () {
      const flags = AiFeatureFlags(
        chatEnabled: true,
        noteEnabled: true,
        available: true,
      );
      final hidden = flags.copyWith(available: false, reason: 'local');

      expect(hidden.chatAvailable, isFalse);
      expect(hidden.noteAvailable, isFalse);
      expect(hidden.chatEnabled, isTrue);
      expect(hidden.reason, 'local');
    });
  });
}
