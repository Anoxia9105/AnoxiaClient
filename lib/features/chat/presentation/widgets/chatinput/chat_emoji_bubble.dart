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
  });

  final ValueChanged<String> onEmojiSelected;
  final ValueChanged<Sticker> onStickerSelected;
  final VoidCallback? closeSelected;
  final bool closeOnSelect;
  final bool emojiOnly;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: BubbleWidget(
        arrowDirection: AxisDirection.down,
        arrowOffset: 115.w,
        backgroundColor: scheme.surface,
        border: BorderSide(color: scheme.outlineVariant, width: 0.5),
        contentBuilder: (context) => Container(
          constraints: BoxConstraints(maxWidth: 120.w, maxHeight: 500.h),
          padding: const EdgeInsets.all(SpacingToken.sm),
          child: ChatEmojiWidget(
            closeSelected: closeSelected,
            closeOnSelect: closeOnSelect,
            emojiOnly: emojiOnly,
            onEmojiSelected: onEmojiSelected,
            onStickerSelected: onStickerSelected,
          ),
        ),
      ),
    );
  }
}
