// 视频通话中「自己的小视频悬浮窗」。
//
// 默认停靠在右下角，支持拖拽滑动，松手后自动吸附到最近的一侧，
// 交互与全局通话悬浮窗（GlobalCallOverlay）保持一致。
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import 'mobile_participant_surface.dart';

/// 可拖拽、自动吸边的本地自己画面小窗
///
/// 位置状态保存在组件内部（页面级临时状态），进出通话/切换布局后回到默认右下角。
class DraggableSelfView extends StatefulWidget {
  const DraggableSelfView({
    super.key,
    required this.participant,
    this.width = 104,
    this.height = 150,
    this.edgePadding = 12,
  });

  /// 本地参与者
  final Participant participant;

  /// 小窗宽度
  final double width;

  /// 小窗高度
  final double height;

  /// 停靠时与父容器边缘的间距
  final double edgePadding;

  @override
  State<DraggableSelfView> createState() => _DraggableSelfViewState();
}

class _DraggableSelfViewState extends State<DraggableSelfView> {
  /// 小窗左上角相对父容器的偏移，null 表示尚未拖拽过（使用默认右下角）
  Offset? _offset;

  /// 拖拽中关闭位移动画，跟手；松手后再开启动画吸边
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final areaWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : widget.width;
        final areaHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : widget.height;
        final maxX = (areaWidth - widget.width).clamp(0.0, areaWidth);
        final maxY = (areaHeight - widget.height).clamp(0.0, areaHeight);

        // 默认右下角
        final current =
            _offset ??
            Offset(maxX - widget.edgePadding, maxY - widget.edgePadding);
        final dx = current.dx.clamp(0.0, maxX);
        final dy = current.dy.clamp(0.0, maxY);

        return Stack(
          children: [
            AnimatedPositioned(
              left: dx,
              top: dy,
              width: widget.width,
              height: widget.height,
              duration: _dragging
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: GestureDetector(
                behavior: HitTestBehavior.deferToChild,
                onPanStart: (_) {
                  if (!_dragging) setState(() => _dragging = true);
                },
                onPanUpdate: (details) {
                  setState(() {
                    _offset = Offset(
                      (dx + details.delta.dx).clamp(0.0, maxX),
                      (dy + details.delta.dy).clamp(0.0, maxY),
                    );
                  });
                },
                onPanEnd: (_) {
                  // 按中心点判断靠近左侧还是右侧，吸附到对应边缘
                  final centerX = (_offset?.dx ?? dx) + widget.width / 2;
                  final snappedX = centerX < areaWidth / 2
                      ? widget.edgePadding
                      : maxX - widget.edgePadding;
                  setState(() {
                    _dragging = false;
                    _offset = Offset(snappedX.clamp(0.0, maxX), dy);
                  });
                },
                child: MobileParticipantSurface(
                  participant: widget.participant,
                  compact: true,
                  borderRadius: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
