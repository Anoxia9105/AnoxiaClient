/// 带箭头的气泡外壳组件
///
/// 职责：为消息内容提供带方向箭头的背景容器，支持自定义颜色、圆角、边框。
/// 内部使用 [BubbleWidget] 实现，封装了主题适配。
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anoxia/framework/provider/setting/chat_bubble_settings_provider.dart';
import 'package:anoxia/common/widgets/bubble_dialog.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 带箭头的气泡外壳
///
/// [isCurrentUser] 决定箭头方向（右箭头表示自己，左箭头表示对方）
/// [backgroundColor] 气泡背景色
/// [child] 内部内容
class BubbleShell extends ConsumerWidget {
  final bool isCurrentUser;
  final bool? placeOnLeft;
  final Color backgroundColor;
  final Widget child;
  final Widget? footer;

  const BubbleShell({
    super.key,
    required this.isCurrentUser,
    this.placeOnLeft,
    required this.backgroundColor,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tail = ref.watch(chatBubbleTailEnabledProvider);
    final left = placeOnLeft ?? !isCurrentUser;
    if (footer case final reactions?) {
      // 回应参与气泡宽度计算，首行跨在下缘，其余换行留在气泡外。
      final firstRowHeight = MediaQuery.textScalerOf(context).scale(15) + 8;
      return _BubbleWithFooter(
        background: BubbleShell(
          isCurrentUser: isCurrentUser,
          placeOnLeft: placeOnLeft,
          backgroundColor: backgroundColor,
          child: const SizedBox.expand(),
        ),
        padding: EdgeInsets.fromLTRB(
          12 + (tail && left ? 6 : 0),
          6,
          12 + (tail && !left ? 6 : 0),
          0,
        ),
        firstRowHeight: firstRowHeight,
        body: child,
        footer: reactions,
      );
    }
    if (tail) {
      return BubbleWidget(
        arrowDirection: (placeOnLeft ?? !isCurrentUser)
            ? AxisDirection.left
            : AxisDirection.right,
        // 尖角固定靠上，保留足够高度避免与圆角相交。
        arrowOffset: 18,
        arrowLength: 6,
        arrowRadius: 2,
        arrowWidth: 8,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        backgroundColor: backgroundColor,
        contentBuilder: (_) => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 24),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            alignment: Alignment.centerLeft,
            child: child,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).toInt()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BubbleWithFooter extends MultiChildRenderObjectWidget {
  _BubbleWithFooter({
    required Widget background,
    required Widget body,
    required Widget footer,
    required this.padding,
    required this.firstRowHeight,
  }) : super(children: [background, body, footer]);

  final EdgeInsets padding;
  final double firstRowHeight;

  @override
  _RenderBubbleWithFooter createRenderObject(BuildContext context) =>
      _RenderBubbleWithFooter(padding, firstRowHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderBubbleWithFooter renderObject,
  ) {
    if (renderObject.padding == padding &&
        renderObject.firstRowHeight == firstRowHeight)
      return;
    renderObject
      ..padding = padding
      ..firstRowHeight = firstRowHeight
      ..markNeedsLayout();
  }
}

class _RenderBubbleWithFooter extends RenderBox
    with
        ContainerRenderObjectMixin<
          RenderBox,
          ContainerBoxParentData<RenderBox>
        >,
        RenderBoxContainerDefaultsMixin<
          RenderBox,
          ContainerBoxParentData<RenderBox>
        > {
  _RenderBubbleWithFooter(this.padding, this.firstRowHeight);

  EdgeInsets padding;
  double firstRowHeight;

  @override
  void setupParentData(RenderBox child) {
    child.parentData = StackParentData();
  }

  @override
  void performLayout() {
    final background = firstChild!;
    final body = childAfter(background)!;
    final footer = childAfter(body)!;
    final inner = constraints.loosen().deflate(padding);
    body.layout(inner, parentUsesSize: true);
    footer.layout(inner, parentUsesSize: true);
    final footerTop = padding.top + body.size.height;
    size = constraints.constrain(
      Size(
        (body.size.width > footer.size.width
                ? body.size.width
                : footer.size.width) +
            padding.horizontal,
        footerTop + footer.size.height,
      ),
    );
    final seam =
        footerTop + (firstRowHeight * 0.45 + 4).clamp(0.0, footer.size.height);
    background.layout(BoxConstraints.tight(Size(size.width, seam)));
    (body.parentData! as ContainerBoxParentData<RenderBox>).offset =
        padding.topLeft;
    (footer.parentData! as ContainerBoxParentData<RenderBox>).offset = Offset(
      padding.left,
      footerTop,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
