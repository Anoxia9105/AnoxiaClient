import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/features/contact/presentation/widgets/recommended_contact/public_info_row.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 推荐联系人/名片资料卡片
///
/// 展示名片中的头像、昵称、用户名和性别等公开信息
class RecommendedContactProfileCard extends StatelessWidget {
  final CardPayload card;

  const RecommendedContactProfileCard({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final userName = card.properties['userName']?.trim().isNotEmpty == true
        ? card.properties['userName']!.trim()
        : card.displaySummary;
    final sex = card.properties['sex'];

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AvatarWidget(
              url: card.thumbnailUrl,
              name: card.displayTitle,
              size: 92,
              borderRadius: 14,
            ),
            const SizedBox(height: 16),
            Text(
              card.displayTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),
            PublicInfoRow(
              label: 'contact_username'.tr(),
              value: userName,
            ),
            const Divider(height: 24),
            PublicInfoRow(
              label: 'contact_gender'.tr(),
              value: _translatedGender(sex),
            ),
          ],
        ),
      ),
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
