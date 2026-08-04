import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/bubble_dialog.dart';
import 'package:anoxia/common/widgets/bubble_menu.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 联系人详情右上角弹出菜单按钮
///
/// 提供编辑备注和删除联系人入口。
///
/// 由于 BotToast 自带 overlay 始终位于 Dialog 路由之下，使用它会在桌面端
/// 对话框场景下导致气泡被对话框遮挡。此处改为直接向根 overlay 插入
/// [OverlayEntry]，根 overlay 位于所有路由（含 showDialog）之上，气泡必
/// 定显示在对话框上方。
class ContactDetailPopupMenuButton extends StatelessWidget {
  final VoidCallback onEditRemark;
  final VoidCallback onDelete;

  const ContactDetailPopupMenuButton({
    super.key,
    required this.onEditRemark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final buttonKey = GlobalKey();

    return IconButton(
      key: buttonKey,
      mouseCursor: SystemMouseCursors.click,
      onPressed: () {
        final renderBox = buttonKey.currentContext?.findRenderObject();
        if (renderBox is! RenderBox) return;

        // UI 布局按宽度断点判定（Web 窄屏等同移动端），与聊天列表菜单保持一致
        final isMobile = DeviceUtil.isMobile(context);
        // 气泡宽度与聊天列表菜单保持一致：自适应最长文案
        final menuWidth = BubbleMenu.measureWidth(
          context,
          titles: [
            'contact_edit_remark'.tr(),
            'contact_delete'.tr(),
          ],
          maxWidth: isMobile ? 200 : 220,
        );

        // 按钮在屏幕中的全局位置（用于定位气泡与箭头）
        final buttonOffset = renderBox.localToGlobal(Offset.zero);
        final buttonSize = renderBox.size;
        final colorScheme = Theme.of(context).colorScheme;

        final overlay = Overlay.of(context, rootOverlay: true);
        late final OverlayEntry entry;

        // 气泡右侧与按钮右侧对齐，整体位于按钮下方；箭头指向右上角按钮
        final double bubbleRight = buttonOffset.dx + buttonSize.width;
        final double bubbleLeft = bubbleRight - menuWidth;
        final double bubbleTop = buttonOffset.dy + buttonSize.height + 8;
        // 箭头水平偏移：相对气泡左缘，靠近右缘以指向右上角按钮
        final double arrowOffset = menuWidth - 24;

        void close() => entry.remove();

        entry = OverlayEntry(
          builder: (_) => Stack(
            children: [
              // 点击空白区域关闭菜单
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: close,
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                left: bubbleLeft,
                top: bubbleTop,
                child: Material(
                  color: Colors.transparent,
                  child: BubbleWidget(
                    arrowDirection: AxisDirection.up,
                    arrowOffset: arrowOffset,
                    backgroundColor: colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    shadows: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                      width: 0.5,
                    ),
                    contentBuilder: (ctx) => Container(
                      // 宽度自适应最长文案，所有菜单项等宽、内容统一居中
                      width: menuWidth,
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 3,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BubbleMenu.buildMenuItem(
                            context: ctx,
                            icon: HugeIcons.strokeRoundedEdit01,
                            title: 'contact_edit_remark'.tr(),
                            textMaxWidth:
                                menuWidth - BubbleMenu.fixedContentWidth,
                            onTap: () {
                              close();
                              onEditRemark();
                            },
                          ),
                          BubbleMenu.buildMenuItem(
                            context: ctx,
                            icon: HugeIcons.strokeRoundedDelete01,
                            title: 'contact_delete'.tr(),
                            isDestructive: true,
                            textMaxWidth:
                                menuWidth - BubbleMenu.fixedContentWidth,
                            onTap: () {
                              close();
                              onDelete();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        overlay.insert(entry);
      },
      icon: const Icon(Icons.more_horiz),
    );
  }
}
