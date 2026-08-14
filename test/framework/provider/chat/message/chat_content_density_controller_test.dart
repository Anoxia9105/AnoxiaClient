import 'package:anoxia/framework/provider/chat/message/chat_content_density_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatContentDensity', () {
    test('未知的持久化值回退为舒适模式', () {
      expect(
        parseChatContentDensity('unknown'),
        ChatContentDensity.comfortable,
      );
    });

    test('可以解析紧凑和平铺模式', () {
      expect(parseChatContentDensity('compact'), ChatContentDensity.compact);
      expect(parseChatContentDensity('flat'), ChatContentDensity.flat);
    });
  });

  group('resolveChatMessageLayout', () {
    test('舒适模式保留自己消息右对齐', () {
      final layout = resolveChatMessageLayout(
        ChatContentDensity.comfortable,
        isCurrentUser: true,
        baseHorizontalPadding: 50,
      );

      expect(layout.placeOnLeft, isFalse);
      expect(layout.verticalMargin, 6);
      expect(layout.avatarSize, 32);
      expect(layout.horizontalPadding, 50);
    });

    test('紧凑模式减少消息间距和头像尺寸', () {
      final layout = resolveChatMessageLayout(
        ChatContentDensity.compact,
        isCurrentUser: false,
        baseHorizontalPadding: 50,
      );

      expect(layout.placeOnLeft, isTrue);
      expect(layout.verticalMargin, lessThan(6));
      expect(layout.avatarSize, lessThan(32));
      expect(layout.horizontalPadding, lessThan(50));
    });

    test('平铺模式将自己和对方消息统一放在左侧', () {
      final selfLayout = resolveChatMessageLayout(
        ChatContentDensity.flat,
        isCurrentUser: true,
        baseHorizontalPadding: 50,
      );
      final otherLayout = resolveChatMessageLayout(
        ChatContentDensity.flat,
        isCurrentUser: false,
        baseHorizontalPadding: 50,
      );

      expect(selfLayout.placeOnLeft, isTrue);
      expect(otherLayout.placeOnLeft, isTrue);
      expect(selfLayout.horizontalPadding, lessThanOrEqualTo(16));
    });
  });
}
