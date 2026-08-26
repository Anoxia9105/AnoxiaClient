import 'package:anoxia/features/chat/presentation/widgets/message_menu/ai_ask_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('屏幕右下消息的问 AI 气泡尖角位于右下', () {
    final placement = resolveAiAskBubblePlacement(
      anchor: const Offset(760, 560),
      screenSize: const Size(800, 600),
      bubbleWidth: 420,
      estimatedHeight: 380,
    );

    expect(placement.arrowDirection, AxisDirection.down);
    expect(placement.left + placement.arrowOffset, 760);
  });

  test('屏幕左上消息的问 AI 气泡尖角位于左上', () {
    final placement = resolveAiAskBubblePlacement(
      anchor: const Offset(40, 40),
      screenSize: const Size(800, 600),
      bubbleWidth: 420,
      estimatedHeight: 380,
    );

    expect(placement.arrowDirection, AxisDirection.up);
    expect(placement.left + placement.arrowOffset, 40);
  });

  test('上下空间变化时尖角始终朝向消息', () {
    final aboveMessage = resolveAiAskBubblePlacement(
      anchor: const Offset(200, 500),
      screenSize: const Size(800, 600),
      bubbleWidth: 420,
      estimatedHeight: 380,
    );
    final belowMessage = resolveAiAskBubblePlacement(
      anchor: const Offset(200, 100),
      screenSize: const Size(800, 600),
      bubbleWidth: 420,
      estimatedHeight: 380,
    );

    expect(aboveMessage.arrowDirection, AxisDirection.down);
    expect(belowMessage.arrowDirection, AxisDirection.up);
  });

  test('窄屏居中消息的尖角不会因浮层居中而偏离锚点', () {
    final placement = resolveAiAskBubblePlacement(
      anchor: const Offset(160, 200),
      screenSize: const Size(320, 600),
      bubbleWidth: 296,
      estimatedHeight: 380,
    );

    expect(placement.left, 12);
    expect(placement.left + placement.arrowOffset, 160);
  });

  test('最小支持高度仍选择空间较大的一侧并保留可用高度', () {
    final placement = resolveAiAskBubblePlacement(
      anchor: const Offset(160, 180),
      screenSize: const Size(320, 240),
      bubbleWidth: 296,
      estimatedHeight: 380,
      safeTop: 24,
    );

    expect(placement.showBelow, isFalse);
    expect(placement.maxHeight, 144);
    expect(placement.left + placement.arrowOffset, 160);
  });
}
