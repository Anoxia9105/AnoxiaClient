import 'package:anoxia/common/widgets/BubbleDialog.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';

/// 弹出"更多"操作菜单
///
/// 提供静音和踢出功能（仅对远端参与者显示）
void showParticipantMoreMenu(
  BuildContext context, {
  required String identity,
  required void Function(String identity) onMute,
  required void Function(String identity) onKick,
}) {
  Function? close;

  final items = [
    ParticipantMoreMenuItem(
      icon: HugeIcons.strokeRoundedMicOff01,
      iconColor: null,
      label: 'call_mute'.tr(),
      onTap: () {
        onMute(identity);
        close?.call();
      },
    ),
    ParticipantMoreMenuItem(
      icon: HugeIcons.strokeRoundedUserRemove01,
      iconColor: Colors.redAccent,
      label: 'call_kick'.tr(),
      labelColor: Colors.redAccent,
      onTap: () {
        onKick(identity);
        close?.call();
      },
    ),
  ];

  close = Toast.showWidget(
    context,
    direction: PreferDirection.topCenter,
    child: Material(
      color: Colors.transparent,
      child: BubbleWidget(
        arrowDirection: AxisDirection.down,
        arrowOffset: 70,
        arrowLength: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        border: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
        contentBuilder: (ctx) => Container(
          constraints: const BoxConstraints(minWidth: 100),
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: items.map((item) {
              return InkWell(
                mouseCursor: SystemMouseCursors.click,
                onTap: item.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: item.icon,
                        size: 15,
                        color:
                            item.iconColor ??
                            Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: item.labelColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    ),
  );
}

/// 更多菜单项数据
class ParticipantMoreMenuItem {
  /// 图标
  final List<List<dynamic>> icon;

  /// 图标颜色
  final Color? iconColor;

  /// 标签文字
  final String label;

  /// 标签颜色
  final Color? labelColor;

  /// 点击回调
  final VoidCallback onTap;

  const ParticipantMoreMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });
}