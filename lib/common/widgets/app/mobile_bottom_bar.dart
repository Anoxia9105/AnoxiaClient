import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../framework/provider/chat/room/room_list_service.dart';
import '../../../framework/provider/contact/contact_requests_controller.dart';
import '../../../framework/provider/layout/layout_controller.dart';
import '../vibrating_badge.dart';

/// 移动端底部导航栏（平面贴底版）
///
/// - 无悬浮胶囊、无毛玻璃、无滑块动画：[Container] 直接贴底，
///   顶部一条 [Divider] 细线分隔内容区。
/// - 选中态只加粗：图标描线加粗 + 文字 [FontWeight.w700]，
///   颜色跟随主题 [ColorScheme.primary]；未选中用
///   [ColorScheme.onSurfaceVariant] 弱化。
/// - 可见项与之前一致：过滤掉记事本、日程、设置，保留聊天 / 人员 / 收藏 / 我的。
/// - 聊天 Tab 显示总未读，人员 Tab 显示联系人请求数（99+ 封顶由
///   [VibratingBadge] 处理），键盘弹起时隐藏。
/// - HugeIcons 全工程只用了 strokeRounded 一套，选中态用主色 + 2.4 描线
///   模拟实心图标效果。
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
          entry.value.name != 'sidebar_note' &&
          entry.value.name != 'sidebar_schedule';
    }).toList();

    return SafeArea(
      top: false,
      child: Container(
        key: const Key('mobile-bottom-bar'),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(
                alpha: isDark ? 0.24 : 0.5,
              ),
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
        child: Row(
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
              child: _FlatNavItem(
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
      ),
    );
  }
}

/// 平面导航里的单个图文项。
///
/// 24px 图标 + 下方 11px 文字（间距 2px）+ 右上悬挂角标；
/// 选中只加粗：图标描线 2.4 + 文字 w700 + 主题主色，
/// 无任何背景框/滑块/缩放动画。
class _FlatNavItem extends StatelessWidget {
  final String label;
  final List<List<dynamic>> icon;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  const _FlatNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final unselectedColor = colorScheme.onSurfaceVariant.withValues(
      alpha: 0.72,
    );
    final foreground = selected ? colorScheme.primary : unselectedColor;

    return Semantics(
      button: true,
      selected: selected,
      label: badgeCount > 0 ? '$label，$badgeCount 条未读' : label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          // 底部导航不需要水波纹：点击已有触觉反馈 + 选中态颜色切换，
          // 保留 InkWell 只为语义与无障碍，视觉上完全静默。
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: _kIconBox,
                  height: _kIconBox,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      HugeIcon(
                        icon: icon,
                        size: 25,
                        strokeWidth: selected ? 2.4 : 1.6,
                        color: foreground,
                      ),
                      if (badgeCount > 0)
                        Positioned(
                          right: -12,
                          top: -4,
                          child: VibratingBadge(
                            count: badgeCount,
                            borderColor: colorScheme.surface,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                ExcludeSemantics(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: foreground,
                    ),
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

/// 图标触控区尺寸。
const double _kIconBox = 36;
