// 编辑预览栏组件
//
// 在聊天输入框上方显示「正在编辑」状态条，与回复预览栏同视觉语言。
// 编辑时输入框已回填消息原文，这里仅提示编辑态 + 提供退出编辑入口。
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 编辑预览条
///
/// [onCancel] 退出编辑：清空编辑目标与输入框内容。
class EditPreviewBar extends StatelessWidget {
  /// 退出编辑回调
  final VoidCallback onCancel;

  const EditPreviewBar({super.key, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(RadiusToken.sm),
        border: Border(left: BorderSide(color: colorScheme.primary, width: 3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedEdit01,
            size: 14,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'chat_editing'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'chat_edit_cancel_tooltip'.tr(),
            onPressed: onCancel,
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 16),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          ),
        ],
      ),
    );
  }
}
