import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';

/// 好友请求状态操作按钮
///
/// 根据请求状态展示同意/拒绝按钮或已处理状态徽章：
/// - 待处理（0）：同意 / 拒绝按钮
/// - 已接受（1）：绿色徽章
/// - 已拒绝（2）：灰色徽章
class NewFriendsStatusButtons extends StatelessWidget {
  final int? status;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const NewFriendsStatusButtons({
    super.key,
    required this.status,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();

    if (status == 0) {
      return _buildPending(context);
    }

    if (status == 1) {
      return _buildChip(
        context,
        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
        label: 'contact_request_accepted'.tr(),
        color: Colors.green,
      );
    }

    return _buildChip(
      context,
      icon: HugeIcons.strokeRoundedCancelCircle,
      label: 'contact_request_rejected'.tr(),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  /// 待处理状态：同意 / 拒绝按钮
  Widget _buildPending(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          onPressed: onAccept,
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedTick02,
            size: 14,
            strokeWidth: 3,
          ),
          label: Text('contact_accept'.tr()),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onReject,
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            foregroundColor: cs.error,
            side: BorderSide(color: cs.error.withValues(alpha: 0.45)),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedCancel01,
            size: 14,
            strokeWidth: 3,
            color: cs.error,
          ),
          label: Text('contact_reject'.tr()),
        ),
      ],
    );
  }

  /// 已处理状态徽章
  Widget _buildChip(
    BuildContext context, {
    required dynamic icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 13, color: color, strokeWidth: 2.5),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
