import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../framework/provider/chat/room/room_list_service.dart';
import '../../../framework/provider/contact/contact_requests_controller.dart';
import '../../../framework/provider/layout/layout_controller.dart';
import '../vibrating_badge.dart';

/// 移动端底部导航栏（V2-C · 液态玻璃图文紧凑版）
///
/// 与 HTML 预览稿 `bottom-nav-redesign-v2.html` 的「V2-C」一致（已按确认意见
/// 去掉底部圆点、图文贴合）：悬浮液态玻璃胶囊 + 弹簧滑块
/// （320ms `easeOutBack`，位置钳制在框内防撞穿），图标下方紧贴 11px 文字标签。
///
/// - 可见项与之前一致：过滤掉记事本、设置，保留聊天 / 人员 / 收藏 / 我的。
/// - 聊天 Tab 显示总未读，人员 Tab 显示联系人请求数（99+ 封顶由
///   [VibratingBadge] 处理），键盘弹起时隐藏。
/// - HugeIcons 全工程只用了 strokeRounded 一套，选中态用主色 + 2.4 描线
///   模拟稿中的实心图标效果。
class MobileBottomBar extends ConsumerWidget {
  const MobileBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 键盘弹起时隐藏底栏，避免遮挡输入框。
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }

    final layout = ref.watch(layoutControllerProvider);
    final pendingRequests = ref.watch(pendingRequestCountProvider).value ?? 0;
    final totalUnread = ref.watch(totalUnreadCountProvider);
    final currentItem = layout.items[layout.currentIndex];
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const chatIndex = 0;
    const contactsIndex = 1;

    final visibleEntries = layout.items.asMap().entries.where((entry) {
      return entry.value.name != 'sidebar_setting' &&
          entry.value.name != 'sidebar_note';
    }).toList();

    // 当前选中项在可见列表中的位置（滑块定位用，找不到时兜底 0）。
    final selectedPos = visibleEntries.indexWhere(
      (entry) => entry.value.name == currentItem.name,
    );
    final safeSelectedPos = selectedPos < 0 ? 0 : selectedPos;

    // 滑块高光：亮色 primary 14%、暗色 20%，描边带 primary 光晕。
    final highlightFill = colorScheme.primary.withValues(
      alpha: isDark ? 0.20 : 0.14,
    );
    final highlightBorder = colorScheme.primary.withValues(
      alpha: isDark ? 0.30 : 0.35,
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 注意：这里量到的是整栏宽（含容器左右各 _kBarHPad 内边距），
            // Row/滑块实际只占内容宽，必须先减掉，否则末项滑块静止时也会
            // 右溢约 13px（此前只修过冲没修这里，切“我的”依然顶框）。
            final tabWidth =
                (constraints.maxWidth - _kBarHPad * 2) / visibleEntries.length;
            return ClipRRect(
              borderRadius: BorderRadius.circular(_kBarRadius),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  key: const Key('mobile-bottom-bar'),
                  padding: const EdgeInsets.fromLTRB(
                    _kBarHPad,
                    8,
                    _kBarHPad,
                    6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.surface.withValues(alpha: 0.94),
                        colorScheme.surface.withValues(alpha: 0.78),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(_kBarRadius),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // 顶部内高光：提亮玻璃质感，贴合液态玻璃的受光面。
                      IgnorePointer(
                        child: Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 28,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.20),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Stack(
                        // 硬裁剪兜底：滑块任何时刻都不许画出内容区。
                        clipBehavior: Clip.hardEdge,
                        children: [
                          // 弹簧滑块：跟随选中项，带过冲的果味动效，
                          // 内部钳制保证不撞穿玻璃框（见下方 [_SlidingHighlight]）。
                          _SlidingHighlight(
                            left: safeSelectedPos * tabWidth + 3,
                            width: tabWidth - 6,
                            minLeft: 3,
                            maxLeft: 3 * tabWidth + 3,
                            fill: highlightFill,
                            border: highlightBorder,
                          ),
                          Row(
                            children: visibleEntries.map((entry) {
                              final idx = entry.key;
                              final item = entry.value;
                              final isSelected = item.name == currentItem.name;

                              final int badgeCount;
                              if (idx == chatIndex) {
                                badgeCount = totalUnread;
                              } else if (idx == contactsIndex) {
                                badgeCount = pendingRequests;
                              } else {
                                badgeCount = 0;
                              }

                              return Expanded(
                                child: _GlassNavIcon(
                                  label: item.name.tr(),
                                  icon: item.icon,
                                  selected: isSelected,
                                  badgeCount: badgeCount,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    ref
                                        .read(layoutControllerProvider.notifier)
                                        .setIndex(idx);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 弹簧滑块：用显式 [AnimationController] 跑 320ms [Curves.easeOutBack]，
/// 位置钳制在 [minLeft]～[maxLeft] 内。
///
/// 直接用 [AnimatedPositioned] + easeOutBack 时，切到两端 Tab 的长行程
/// 过冲约 10%，动画中途会撞穿玻璃外框（复现见
/// `test/common/widgets/app/mobile_bottom_bar_slider_test.dart`）；
/// 这里保留弹簧手感，只把出界部分截掉，滑块贴框 decelerate 而不是穿框。
class _SlidingHighlight extends StatefulWidget {
  final double left;
  final double width;
  final double minLeft;
  final double maxLeft;
  final Color fill;
  final Color border;

  const _SlidingHighlight({
    required this.left,
    required this.width,
    required this.minLeft,
    required this.maxLeft,
    required this.fill,
    required this.border,
  });

  @override
  State<_SlidingHighlight> createState() => _SlidingHighlightState();
}

class _SlidingHighlightState extends State<_SlidingHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _from = 0;
  double _to = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _from = widget.left;
    _to = widget.left;
  }

  @override
  void didUpdateWidget(_SlidingHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.left != _to) {
      // 以当前实际显示位置为新起点，动画中途变向也不跳帧。
      _from = _displayedLeft;
      _to = widget.left;
      _controller.forward(from: 0);
    }
  }

  double get _displayedLeft {
    final raw =
        ui.lerpDouble(
          _from,
          _to,
          Curves.easeOutBack.transform(_controller.value),
        ) ??
        _to;
    return raw.clamp(widget.minLeft, widget.maxLeft);
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
        return Positioned(
          left: _displayedLeft,
          top: 0,
          width: widget.width,
          height: _kIconBox,
          child: child!,
        );
      },
      child: DecoratedBox(
        key: const Key('mobile-bottom-bar-slider'),
        decoration: BoxDecoration(
          color: widget.fill,
          borderRadius: BorderRadius.circular(_kSliderRadius),
          border: Border.all(color: widget.border, width: 1),
        ),
      ),
    );
  }
}

/// 液态玻璃导航里的单个图文项（紧凑版）。
///
/// 36x36 图标区 + 下方 11px 文字（间距 1px）+ 右上悬挂角标；
/// 按压只缩放图标本身（0.88），读屏 label 去重（可见文字不再重复播报）。
class _GlassNavIcon extends StatefulWidget {
  final String label;
  final List<List<dynamic>> icon;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  const _GlassNavIcon({
    required this.label,
    required this.icon,
    required this.selected,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  State<_GlassNavIcon> createState() => _GlassNavIconState();
}

class _GlassNavIconState extends State<_GlassNavIcon> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final unselectedColor = colorScheme.onSurfaceVariant.withValues(
      alpha: 0.72,
    );

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.badgeCount > 0
          ? '${widget.label}，${widget.badgeCount} 条未读'
          : widget.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (value) {
            if (mounted && _pressed != value) {
              setState(() => _pressed = value);
            }
          },
          borderRadius: BorderRadius.circular(_kSliderRadius),
          splashColor: colorScheme.primary.withValues(alpha: 0.10),
          highlightColor: colorScheme.primary.withValues(alpha: 0.06),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: _pressed ? 0.88 : 1.0,
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeInOut,
                child: SizedBox(
                  width: _kIconBox,
                  height: _kIconBox,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      HugeIcon(
                        icon: widget.icon,
                        size: 25,
                        strokeWidth: widget.selected ? 2.4 : 1.6,
                        color: widget.selected
                            ? colorScheme.primary
                            : unselectedColor,
                      ),
                      if (widget.badgeCount > 0)
                        Positioned(
                          right: -12,
                          top: -4,
                          child: VibratingBadge(
                            count: widget.badgeCount,
                            borderColor: colorScheme.surface,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 1),
              ExcludeSemantics(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: widget.selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: widget.selected
                        ? colorScheme.primary
                        : unselectedColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// HTML 稿映射的固定尺寸：外栏圆角 12、滑块圆角 10、图标区 36、
/// 外栏水平内边距 8（滑块分格时从整栏宽里扣除，见 build 注释）。
const double _kBarRadius = 12;
const double _kSliderRadius = 10;
const double _kIconBox = 36;
const double _kBarHPad = 8;
