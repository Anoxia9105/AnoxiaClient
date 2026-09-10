import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../framework/provider/chat/room/room_list_service.dart';
import '../../../framework/provider/contact/contact_requests_controller.dart';
import '../../../framework/provider/layout/layout_controller.dart';
import '../../../framework/provider/setting/update_check_provider.dart';
import '../../../framework/theme/radius_token.dart';
import '../vibrating_badge.dart';

/// 移动端底部导航栏（方案 B · Material3 分段胶囊）
///
/// 根据 [LayoutController] 的配置动态生成导航项，
/// 在聊天、联系人 Tab 上显示未读角标，「我的」Tab 承载更新红点
/// （设置页已移出底栏，原 settingsIndex 分支是死代码，改为挂到我的上）。
///
/// 贴底全宽 + 毛玻璃 + 顶部 hairline，选中图标装进 56x32 胶囊
/// （`primary` 12% 透明度），与 HTML 预览稿 `bottom-nav-redesign.html` 方案 B 一致。
/// 按压只缩放单个胶囊（0.92），不再整体缩放整栏。
class MobileBottomBar extends ConsumerWidget {
  const MobileBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 键盘弹起时隐藏底栏，避免遮挡输入框（与 HTML 稿 UX 规则一致）。
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }

    final layout = ref.watch(layoutControllerProvider);
    final hasUpdate = ref.watch(hasAppUpdateProvider);
    final pendingRequests = ref.watch(pendingRequestCountProvider).value ?? 0;
    final totalUnread = ref.watch(totalUnreadCountProvider);
    final currentItem = layout.items[layout.currentIndex];
    final colorScheme = Theme.of(context).colorScheme;
    const chatIndex = 0;
    const contactsIndex = 1;

    final visibleEntries = layout.items.asMap().entries.where((entry) {
      return entry.value.name != 'sidebar_setting' &&
          entry.value.name != 'sidebar_note';
    }).toList();

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.82),
            border: Border(
              top: BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.09),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                  // 设置 Tab 不在底栏展示，更新红点挂到「我的」上。
                  final showDot =
                      item.name == 'sidebar_my' && hasUpdate;

                  return Expanded(
                    child: _M3NavItem(
                      label: item.name.tr(),
                      icon: item.icon,
                      selected: isSelected,
                      badgeCount: badgeCount,
                      showDot: showDot,
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
            ),
          ),
        ),
      ),
    );
  }
}

/// 单个 M3 导航项：56x32 选中胶囊 + 下方 11px 标签。
///
/// 按压态只缩放胶囊本身（[AnimatedScale] 0.92），选中背景用
/// [AnimatedContainer] 220ms 形变展开，语义上暴露 `selected` 给读屏软件。
class _M3NavItem extends StatefulWidget {
  final String label;
  final List<List<dynamic>> icon;
  final bool selected;
  final int badgeCount;
  final bool showDot;
  final VoidCallback onTap;

  const _M3NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.badgeCount,
    required this.showDot,
    required this.onTap,
  });

  @override
  State<_M3NavItem> createState() => _M3NavItemState();
}

class _M3NavItemState extends State<_M3NavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final unselectedColor =
        colorScheme.onSurfaceVariant.withValues(alpha: 0.72);

    final Widget iconWidget = HugeIcon(
      icon: widget.icon,
      size: 24,
      strokeWidth: widget.selected ? 2.2 : 1.6,
      color: widget.selected ? colorScheme.primary : unselectedColor,
    );

    Widget pillChild = iconWidget;
    if (widget.badgeCount > 0 || widget.showDot) {
      pillChild = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          if (widget.badgeCount > 0)
            Positioned(
              right: -14,
              top: -8,
              child: VibratingBadge(
                count: widget.badgeCount,
                borderColor: colorScheme.surface,
              ),
            )
          else
            Positioned(
              right: -6,
              top: -4,
              child: VibratingBadge(
                isDot: true,
                borderColor: colorScheme.surface,
              ),
            ),
        ],
      );
    }

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
          borderRadius: BorderRadius.circular(RadiusToken.pill),
          splashColor: colorScheme.primary.withValues(alpha: 0.10),
          highlightColor: colorScheme.primary.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: _pressed ? 0.92 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    width: 56,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.selected
                          ? colorScheme.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(RadiusToken.pill),
                    ),
                    child: Center(child: pillChild),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
