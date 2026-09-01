import 'package:anoxia/features/contact/presentation/widgets/contact_detail/contact_info_tile.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/domain/chat_contact_detail_vo.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 联系人信息区域组件
///
/// 以卡片形式分组展示联系人的状态、备注、用户名、性别、手机号、加好友时间等信息
class ContactInfoSection extends StatelessWidget {
  final ChatContactDetailVO detail;
  final bool isOnline;

  const ContactInfoSection({
    super.key,
    required this.detail,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(RadiusToken.xl),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          children: [
            ContactInfoTile(
              icon: isOnline
                  ? HugeIcons.strokeRoundedCircle
                  : HugeIcons.strokeRoundedCircleArrowDataTransferDiagonal,
              label: 'contact_status'.tr(),
              value: isOnline ? 'contact_online'.tr() : 'contact_offline'.tr(),
            ),
            _divider(colorScheme),
            ContactInfoTile(
              icon: HugeIcons.strokeRoundedEdit01,
              label: 'contact_remark'.tr(),
              value: detail.remark ?? 'contact_no_remark'.tr(),
            ),
            _divider(colorScheme),
            ContactInfoTile(
              icon: HugeIcons.strokeRoundedUser,
              label: 'contact_username'.tr(),
              value: detail.userName ?? '',
            ),
            _divider(colorScheme),
            ContactInfoTile(
              icon: HugeIcons.strokeRoundedUserGroup,
              label: 'contact_gender'.tr(),
              value: _translatedGender(detail.sex),
            ),
            _divider(colorScheme),
            ContactInfoTile(
              icon: HugeIcons.strokeRoundedCall,
              label: 'contact_phone'.tr(),
              value: detail.phoneNumber ?? 'contact_no_phone'.tr(),
            ),
            _divider(colorScheme),
            ContactInfoTile(
              icon: HugeIcons.strokeRoundedCalendar03,
              label: 'contact_became_friends'.tr(),
              value: detail.formattedDate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(ColorScheme colorScheme) {
    return Divider(
      height: 1,
      indent: 52,
      endIndent: 20,
      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }

  String _translatedGender(String? sex) {
    switch (sex) {
      case '0':
        return 'contact_male'.tr();
      case '1':
        return 'contact_female'.tr();
      default:
        return 'contact_unknown_gender'.tr();
    }
  }
}