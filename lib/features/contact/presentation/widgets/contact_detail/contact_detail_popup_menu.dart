import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/bubble_dialog.dart';
import 'package:anoxia/common/widgets/bubble_menu.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 联系人详情右上角弹出菜单按钮
///
/// 提供编辑备注和删除联系人入口
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
    return Builder(
      builder: (context) {
        return IconButton(
          mouseCursor: SystemMouseCursors.click,
          onPressed: () {
            Function? close;
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

            close = Toast.showWidget(
              context,
              direction: isMobile
                  ? PreferDirection.bottomRight
                  : PreferDirection.bottomLeft,
              child: Material(
                color: Colors.transparent,
                child: BubbleWidget(
                  arrowDirection: AxisDirection.up,
                  // 气泡宽度随文案自适应，移动端箭头偏移跟随宽度，保持指向右上角按钮
                  arrowOffset: isMobile ? menuWidth + 34 : 25,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  shadows: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                  contentBuilder: (context) => Container(
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
                          context: context,
                          icon: HugeIcons.strokeRoundedEdit01,
                          title: 'contact_edit_remark'.tr(),
                          textMaxWidth:
                              menuWidth - BubbleMenu.fixedContentWidth,
                          onTap: () {
                            close?.call();
                            onEditRemark();
                          },
                        ),
                        BubbleMenu.buildMenuItem(
                          context: context,
                          icon: HugeIcons.strokeRoundedDelete01,
                          title: 'contact_delete'.tr(),
                          isDestructive: true,
                          textMaxWidth:
                              menuWidth - BubbleMenu.fixedContentWidth,
                          onTap: () {
                            close?.call();
                            onDelete();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          icon: const Icon(Icons.more_horiz),
        );
      },
    );
  }
}
