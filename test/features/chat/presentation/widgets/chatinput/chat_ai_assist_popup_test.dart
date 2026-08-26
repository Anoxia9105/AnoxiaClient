import 'package:anoxia/common/widgets/bubble_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AI 助手在输入栏上方时尖角位于右下方', () {
    final placement = resolveAnchoredBubblePlacement(
      targetRect: const Rect.fromLTWH(720, 540, 40, 40),
      screenSize: const Size(800, 600),
      bubbleWidth: 420,
      estimatedHeight: 380,
      preferRightArrow: true,
      arrowInset: 24,
    );

    expect(placement.arrowDirection, AxisDirection.down);
    expect(placement.arrowOffset, 396);
    expect(placement.left + placement.arrowOffset, 740);
  });

  test('AI 助手在按钮下方时尖角位于右上方', () {
    final placement = resolveAnchoredBubblePlacement(
      targetRect: const Rect.fromLTWH(500, 20, 40, 40),
      screenSize: const Size(800, 600),
      bubbleWidth: 320,
      estimatedHeight: 380,
      preferRightArrow: true,
      arrowInset: 24,
    );

    expect(placement.arrowDirection, AxisDirection.up);
    expect(placement.arrowOffset, 296);
    expect(placement.left + placement.arrowOffset, 520);
  });
}
