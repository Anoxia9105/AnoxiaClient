import 'package:anoxia/common/widgets/bubble_dialog.dart';
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
            close = Toast.showWidget(
              context,
              direction: PreferDirection.bottomRight,
              child: Material(
                color: Colors.transparent,
                child: BubbleWidget(
                  arrowDirection: AxisDirection.up,
                  arrowOffset: 95,
                  arrowWidth: 13,
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
                        .withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                  contentBuilder: (context) => Container(
                    constraints: const BoxConstraints(maxWidth: 120),
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 2,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMenuItem(
                          icon: HugeIcons.strokeRoundedEdit01,
                          title: 'contact_edit_remark'.tr(),
                          onTap: () {
                            close?.call();
                            onEditRemark();
                          },
                        ),
                        _buildMenuItem(
                          icon: HugeIcons.strokeRoundedDelete01,
                          title: 'contact_delete'.tr(),
                          isDestructive: true,
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

  Widget _buildMenuItem({
    required dynamic icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: icon,
              size: 15,
              color: isDestructive ? Colors.red : null,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDestructive ? Colors.red : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
