import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../framework/provider/chat/room/room_list_service.dart';
import '../../../framework/provider/contact/contact_requests_controller.dart';
import '../../../framework/provider/layout/layout_controller.dart';
import '../../../framework/provider/setting/update_check_provider.dart';
import '../vibrating_badge.dart';

/// 移动端悬浮胶囊底部导航栏
///
/// 根据 [LayoutController] 的配置动态生成导航项，
/// 在聊天、联系人、设置等 Tab 上显示未读角标和更新提示。
///
/// 悬浮胶囊样式：毛玻璃容器 + 阴影 + 内边距，悬浮于页面底部之上。
class MobileBottomBar extends ConsumerStatefulWidget {
  const MobileBottomBar({super.key});

  @override
  ConsumerState<MobileBottomBar> createState() => _MobileBottomBarState();
}

class _MobileBottomBarState extends ConsumerState<MobileBottomBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  int? _pressedIndex;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTapDown(int index) {
    if (_pressedIndex != index) {
      _pressedIndex = index;
      _animController.forward();
    }
  }

  void _onTapUp() {
    if (_pressedIndex != null) {
      _pressedIndex = null;
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = ref.watch(layoutControllerProvider);
    final hasUpdate = ref.watch(hasAppUpdateProvider);
    final pendingRequests = ref.watch(pendingRequestCountProvider).value ?? 0;
    final totalUnread = ref.watch(totalUnreadCountProvider);
    final currentItem = layout.items[layout.currentIndex];
    final colorScheme = Theme.of(context).colorScheme;
    const chatIndex = 0;
    const contactsIndex = 1;
    final settingsIndex = layout.items.length - 1;

    final visibleEntries = layout.items.asMap().entries.where((entry) {
      return entry.value.name != 'sidebar_setting' &&
          entry.value.name != 'sidebar_note';
    }).toList();

    final isPressed = _pressedIndex != null;
    final scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Transform.scale(
              scale: isPressed ? scale.value : 1.0,
              child: child,
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.12),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: -4,
                    ),
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 3),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: visibleEntries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final isSelected = item.name == currentItem.name;

                    Widget iconWidget = HugeIcon(
                      icon: item.icon,
                      size: 22,
                      strokeWidth: isSelected ? 2.2 : 1.5,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.60),
                    );

                    if (idx == chatIndex && totalUnread > 0) {
                      iconWidget = Stack(
                        clipBehavior: Clip.none,
                        children: [
                          iconWidget,
                          Positioned(
                            right: -8,
                            top: -6,
                            child: VibratingBadge(count: totalUnread),
                          ),
                        ],
                      );
                    } else if (idx == contactsIndex && pendingRequests > 0) {
                      iconWidget = Stack(
                        clipBehavior: Clip.none,
                        children: [
                          iconWidget,
                          Positioned(
                            right: -8,
                            top: -6,
                            child: VibratingBadge(count: pendingRequests),
                          ),
                        ],
                      );
                    } else if (idx == settingsIndex && hasUpdate) {
                      iconWidget = Stack(
                        clipBehavior: Clip.none,
                        children: [
                          iconWidget,
                          const Positioned(
                            right: -8,
                            top: -6,
                            child: VibratingBadge(isDot: true),
                          ),
                        ],
                      );
                    }

                    return Expanded(
                      child: GestureDetector(
                        onTapDown: (_) => _onTapDown(idx),
                        onTapUp: (_) => _onTapUp(),
                        onTapCancel: () => _onTapUp(),
                        child: InkWell(
                          onTap: () {
                            ref
                                .read(layoutControllerProvider.notifier)
                                .setIndex(idx);
                          },
                          borderRadius: BorderRadius.circular(22),
                          splashColor: colorScheme.primary.withValues(alpha: 0.10),
                          highlightColor: colorScheme.primary.withValues(alpha: 0.06),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 6,
                            ),
                            decoration: isSelected
                                ? BoxDecoration(
                                    color: colorScheme.primary.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(22),
                                  )
                                : null,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Center(child: iconWidget),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.name.tr(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight:
                                        isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
