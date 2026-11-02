import 'dart:math' as math;
import 'package:bot_toast/bot_toast.dart';
import 'package:anoxia/common/widgets/bubble_dialog.dart';
import 'package:anoxia/framework/domain/sticker_pack.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'chat_emoji_widget.dart';

/// 输入框与消息回应共用的 Emoji 气泡外壳。
class ChatEmojiBubble extends StatelessWidget {
  const ChatEmojiBubble({
    super.key,
    required this.onEmojiSelected,
    required this.onStickerSelected,
    this.closeSelected,
    this.closeOnSelect = false,
    this.emojiOnly = false,
    this.arrowDirection = AxisDirection.down,
    this.arrowOffset,
    this.reactionMaxHeight,
  });

  final ValueChanged<String> onEmojiSelected;
  final ValueChanged<Sticker> onStickerSelected;
  final VoidCallback? closeSelected;
  final bool closeOnSelect;
  final bool emojiOnly;
  final AxisDirection arrowDirection;
  final double? arrowOffset;
  final double? reactionMaxHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screen = MediaQuery.sizeOf(context);
    // 回应面板使用逻辑像素限制尺寸，不跟随输入框的 ScreenUtil 放大。
    final reactionWidth = (screen.width - 32).clamp(0.0, 344.0);
    final reactionHeight = math.min(
      (screen.height - 64).clamp(0.0, 320.0),
      reactionMaxHeight ?? 320,
    );
    const padding = SpacingToken.sm * 2;
    return Material(
      color: Colors.transparent,
      child: BubbleWidget(
        arrowDirection: arrowDirection,
        arrowOffset: arrowOffset ?? (emojiOnly ? reactionWidth - 24 : 115.w),
        backgroundColor: scheme.surface,
        border: BorderSide(color: scheme.outlineVariant, width: 0.5),
        contentBuilder: (context) => Container(
          constraints: emojiOnly
              ? BoxConstraints.tightFor(
                  width: reactionWidth,
                  height: reactionHeight,
                )
              : BoxConstraints(maxWidth: 120.w, maxHeight: 500.h),
          padding: const EdgeInsets.all(SpacingToken.sm),
          child: ChatEmojiWidget(
            closeSelected: closeSelected,
            closeOnSelect: closeOnSelect,
            emojiOnly: emojiOnly,
            panelHeight: emojiOnly
                ? (reactionHeight - padding).clamp(0.0, 320.0)
                : null,
            onEmojiSelected: onEmojiSelected,
            onStickerSelected: onStickerSelected,
          ),
        ),
      ),
    );
  }
}

/// 更多回应表情直接按消息矩形定位，避免浮层自动翻转后箭头仍指向原方向。
void showReactionEmojiBubble({
  required BuildContext context,
  required Rect targetRect,
  required ValueChanged<String> onSelected,
}) {
  final screen = MediaQuery.sizeOf(context);
  final width = (screen.width - 32).clamp(0.0, 344.0);
  final placement = resolveAnchoredBubblePlacement(
    targetRect: targetRect,
    screenSize: screen,
    bubbleWidth: width,
    estimatedHeight: (screen.height - 64).clamp(0.0, 320.0) + 10,
    preferRightArrow: targetRect.center.dx >= screen.width / 2,
    safeTop: MediaQuery.paddingOf(context).top,
  );
  BotToast.showEnhancedWidget(
    onlyOne: true,
    clickClose: true,
    ignoreContentClick: false,
    enableKeyboardSafeArea: false,
    backgroundColor: Colors.transparent,
    toastBuilder: (close) => Stack(
      children: [
        Positioned(
          left: placement.left,
          top: placement.showBelow ? placement.anchorY : null,
          bottom: placement.showBelow
              ? null
              : screen.height - placement.anchorY,
          width: width,
          child: ChatEmojiBubble(
            emojiOnly: true,
            closeOnSelect: true,
            closeSelected: close,
            arrowDirection: placement.arrowDirection,
            arrowOffset: placement.arrowOffset,
            reactionMaxHeight: math.max(0.0, placement.maxHeight - 10),
            onStickerSelected: (_) {},
            onEmojiSelected: onSelected,
          ),
        ),
      ],
    ),
  );
}
