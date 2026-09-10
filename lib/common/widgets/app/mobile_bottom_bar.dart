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

/// 移动端底部导航栏（V2-C · 纯图标液态玻璃版）
///
/// 与 HTML 预览稿 `bottom-nav-redesign-v2.html` 的「V2-C · 纯图标版」一致：
/// 悬浮液态玻璃胶囊 + 弹簧滑块（`AnimatedPositioned` 320ms `easeOutBack`），
/// 只显示图标（无文字标签），选中靠滑块高光 + 主色图标表达。
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
    final selectedPos = visibleEntries
        .indexWhere((entry) => entry.value.name == currentItem.name);
    final safeSelectedPos = selectedPos < 0 ? 0 : selectedPos;

    // 滑块高光：亮色 primary 14%、暗色 20%，描边带 primary 光晕。
    final highlightFill =
        colorScheme.primary.withValues(alpha: isDark ? 0.20 : 0.14);
    final highlightBorder =
        colorScheme.primary.withValues(alpha: isDark ? 0.30 : 0.35);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth =
                constraints.maxWidth / visibleEntries.length;
            return ClipRRect(
              borderRadius: BorderRadius.circular(_kBarRadius),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.surface.withValues(alpha: 0.88),
                        colorScheme.surface.withValues(alpha: 0.72),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(_kBarRadius),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 44,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // 弹簧滑块：跟随选中项，带过冲的果味动效。
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutBack,
                        left: safeSelectedPos * tabWidth + 3,
                        top: 0,
                        width: tabWidth - 6,
                        height: _kIconBox,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: highlightFill,
                            borderRadius:
                                BorderRadius.circular(_kSliderRadius),
                            border: Border.all(
                              color: highlightBorder,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: visibleEntries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          final isSelected =
                              item.name == currentItem.name;

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
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 液态玻璃导航里的单个纯图标项。
///
/// 36x36 图标区 + 右上悬挂角标；按压只缩放图标本身（0.88），
/// 语义上保留文字标签给读屏软件。
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
    final unselectedColor =
        colorScheme.onSurfaceVariant.withValues(alpha: 0.72);

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
          child: SizedBox(
            height: _kIconBox,
            child: Center(
              child: AnimatedScale(
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
            ),
          ),
        ),
      ),
    );
  }
}

/// HTML 稿映射的固定尺寸：外栏圆角 30、滑块圆角 18、图标区 36。
const double _kBarRadius = 30;
const double _kSliderRadius = 18;
const double _kIconBox = 36;
