import 'package:anoxia/features/contact/presentation/widgets/contact_detail/contact_detail_header.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/features/contact/presentation/widgets/contact_detail/contact_info_tile.dart';
import 'package:anoxia/framework/domain/chat_room_member_vo.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 群成员基本信息页
///
/// 当群成员还不是联系人时展示其基础资料
/// （头像、昵称、用户ID、在线状态、性别、手机号等）。
class MemberBasicInfoPage extends StatelessWidget {
  final ChatRoomMemberVO member;

  const MemberBasicInfoPage({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: Text('member_basic_info_title'.tr())),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ContactDetailHeader(
            avatar: member.avatar,
            nickName: member.nickName,
            isOnline: member.onlineStatus ?? false,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(RadiusToken.lg),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedInformationCircle,
                    size: 16,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'member_not_contact_hint'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    icon: HugeIcons.strokeRoundedFingerPrint,
                    label: 'member_user_id'.tr(),
                    value: member.userId?.toString() ?? '-',
                  ),
                  _divider(colorScheme),
                  ContactInfoTile(
                    icon: member.onlineStatus == true
                        ? HugeIcons.strokeRoundedCircle
                        : HugeIcons.strokeRoundedCircleArrowDataTransferDiagonal,
                    label: 'contact_status'.tr(),
                    value: member.onlineStatus == true
                        ? 'contact_online'.tr()
                        : 'contact_offline'.tr(),
                  ),
                  _divider(colorScheme),
                  ContactInfoTile(
                    icon: HugeIcons.strokeRoundedUserGroup,
                    label: 'contact_gender'.tr(),
                    value: _translatedGender(member.sex),
                  ),
                  _divider(colorScheme),
                  ContactInfoTile(
                    icon: HugeIcons.strokeRoundedCall,
                    label: 'contact_phone'.tr(),
                    value: member.phoneNumber ?? 'contact_no_phone'.tr(),
                  ),
                ],
              ),
            ),
          ),
        ],
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