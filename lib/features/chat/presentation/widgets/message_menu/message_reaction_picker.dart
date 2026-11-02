import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../message_bubble/message_reaction_bar.dart';

/// 悬停和长按菜单共用的小尺寸表情条。
class MessageReactionPicker extends StatelessWidget {
  const MessageReactionPicker({
    super.key,
    required this.onSelected,
    this.touch = false,
  });
  final ValueChanged<String> onSelected;
  final bool touch;

  @override
  Widget build(BuildContext context) {
    final size = touch ? 40.0 : 30.0;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Wrap(
          children: [
            for (final emoji in [...reactionEmojiPalette, '__more__'])
              SizedBox(
                width: size,
                height: size,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: emoji == '__more__'
                      ? 'chat_reaction_more_emoji'.tr()
                      : emoji,
                  onPressed: () => onSelected(emoji),
                  icon: emoji == '__more__'
                      ? const Icon(Icons.add_reaction_outlined, size: 18)
                      : Text(emoji, style: const TextStyle(fontSize: 18)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 根据鼠标输入显示浮层，移入浮层后保持；滚动、退出和销毁时移除。
class MessageReactionHover extends StatefulWidget {
  const MessageReactionHover({
    super.key,
    required this.child,
    required this.onSelected,
    this.enabled = true,
    this.timeLabel = '',
    this.isCurrentUser = false,
    this.sideInset = 8,
  });
  final Widget child;
  final ValueChanged<String> onSelected;
  final bool enabled;
  final String timeLabel;
  final bool isCurrentUser;
  final double sideInset;
  @override
  State<MessageReactionHover> createState() => _MessageReactionHoverState();
}

class _MessageReactionHoverState extends State<MessageReactionHover> {
  OverlayEntry? _entry;
  Timer? _timer;
  ScrollPosition? _scroll;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scroll?.removeListener(_hide);
    _scroll = Scrollable.maybeOf(context)?.position;
    _scroll?.addListener(_hide);
  }

  @override
  void didUpdateWidget(covariant MessageReactionHover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _hide();
  }

  void _hide() {
    _timer?.cancel();
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }

  void _leave() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 180), _hide);
  }

  void _show(PointerEnterEvent event) {
    _timer?.cancel();
    if (event.kind != PointerDeviceKind.mouse ||
        !widget.enabled ||
        _entry != null) {
      return;
    }
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox;
    final overlayBox = overlay.context.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final width = math.min(218.0, overlayBox.size.width - 16);
    final left = origin.dx
        .clamp(8.0, math.max(8.0, overlayBox.size.width - width - 8.0))
        .toDouble();
    final top = origin.dy >= 46
        ? origin.dy - 42
        : origin.dy + box.size.height + 4;
    // 时间放在气泡外侧，编辑标记预留独立空间；边缘空间不足时放在工具条外侧。
    const timeWidth = 48.0;
    final sideLeft = widget.isCurrentUser
        ? origin.dx - widget.sideInset - timeWidth
        : origin.dx + box.size.width + widget.sideInset;
    final fitsSide =
        sideLeft >= 8 && sideLeft + timeWidth <= overlayBox.size.width - 8;
    final timeLeft = fitsSide ? sideLeft : left;
    final timeTop = fitsSide
        ? origin.dy + (box.size.height - 16) / 2
        : (top < origin.dy ? top - 18 : top + 40);
    _entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            width: width,
            child: MouseRegion(
              onEnter: (_) => _timer?.cancel(),
              onExit: (_) => _leave(),
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(8),
                child: MessageReactionPicker(
                  onSelected: (emoji) {
                    _hide();
                    widget.onSelected(emoji);
                  },
                ),
              ),
            ),
          ),
          if (widget.timeLabel.isNotEmpty)
            Positioned(
              left: timeLeft,
              top: timeTop.clamp(
                4.0,
                math.max(4.0, overlayBox.size.height - 20),
              ),
              width: timeWidth,
              child: IgnorePointer(
                child: Material(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    child: Text(
                      widget.timeLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.4,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    overlay.insert(_entry!);
  }

  @override
  void dispose() {
    _scroll?.removeListener(_hide);
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: _show,
    onExit: (_) => _leave(),
    child: Listener(onPointerDown: (_) => _hide(), child: widget.child),
  );
}
