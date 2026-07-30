import 'dart:math';

import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/framework/domain/room_state.dart';
import 'package:flutter/material.dart';

/// 表情反应全屏特效叠加层
///
/// 监听 [RoomState.reactions] 列表，当有新的表情反应时，
/// 在屏幕中央展示全屏动画特效（缩放 + 淡出），3 秒后自动消失。
///
/// 支持同时展示多个反应，每个反应独立动画。
class ReactionOverlay extends StatefulWidget {
  /// 表情反应列表
  final List<ReactionItem> reactions;

  const ReactionOverlay({super.key, required this.reactions});

  @override
  State<ReactionOverlay> createState() => _ReactionOverlayState();
}

class _ReactionOverlayState extends State<ReactionOverlay> {
  /// 当前正在展示的反应项（key = reaction.id）
  final Map<String, ReactionItem> _activeReactions = {};

  /// 已处理过的 reaction id 集合，避免重复动画
  final Set<String> _processedIds = {};

  @override
  void didUpdateWidget(covariant ReactionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 找出新增的 reaction
    for (final item in widget.reactions) {
      if (!_processedIds.contains(item.id)) {
        _processedIds.add(item.id);
        _activeReactions[item.id] = item;
      }
    }

    // 找出已移除的 reaction（已被 Timer 从列表中移除）
    final currentIds = widget.reactions.map((r) => r.id).toSet();
    _activeReactions.removeWhere((id, _) => !currentIds.contains(id));
  }

  @override
  Widget build(BuildContext context) {
    if (_activeReactions.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: _activeReactions.entries.map((entry) {
        return _ReactionBubble(
          key: ValueKey(entry.key),
          reaction: entry.value,
          onAnimationComplete: () {
            if (mounted) {
              setState(() {
                _activeReactions.remove(entry.key);
                _processedIds.remove(entry.key);
              });
            }
          },
        );
      }).toList(),
    );
  }
}

/// 单个表情气泡动画组件
///
/// 动画流程：
///   1. 0-400ms：从 0.3 缩放到 1.2（弹性曲线）
///   2. 400-2200ms：保持显示
///   3. 2200-3000ms：淡出消失
class _ReactionBubble extends StatefulWidget {
  final ReactionItem reaction;
  final VoidCallback onAnimationComplete;

  const _ReactionBubble({
    super.key,
    required this.reaction,
    required this.onAnimationComplete,
  });

  @override
  State<_ReactionBubble> createState() => _ReactionBubbleState();
}

class _ReactionBubbleState extends State<_ReactionBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  /// 随机水平偏移，避免多个表情完全重叠
  final double _randomOffsetX = (Random().nextDouble() - 0.5) * 80;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // 缩放动画：0-400ms 从 0.3 到 1.2，之后保持
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.3, end: 1.2)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 13, // 400ms / 3000ms ≈ 13%
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.2),
        weight: 87, // 保持
      ),
    ]).animate(_controller);

    // 透明度动画：前 2200ms 保持 1.0，最后 800ms 淡出到 0
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 73, // 2200ms / 3000ms ≈ 73%
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 27, // 800ms / 3000ms ≈ 27%
      ),
    ]).animate(_controller);

    _controller.forward().then((_) {
      widget.onAnimationComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            child: Transform.translate(
              offset: Offset(_randomOffsetX, -40),
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 表情符号
                      Text(
                        widget.reaction.message,
                        style: const TextStyle(fontSize: 64),
                      ),
                      const SizedBox(height: 8),
                      // 发送者信息
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.reaction.avatar != null) ...[
                              AvatarWidget(
                                url: widget.reaction.avatar!,
                                name: widget.reaction.name,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              widget.reaction.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
