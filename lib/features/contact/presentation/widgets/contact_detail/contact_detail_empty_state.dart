import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';

/// 联系人详情空状态组件
///
/// 当未选择联系人时显示的提示
class ContactDetailEmptyState extends StatelessWidget {
  const ContactDetailEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedUserGroup,
            size: 56,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: SpacingToken.lg),
          Text(
            'contact_select_contact'.tr(),
            style: TextStyle(
              fontSize: 15,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}