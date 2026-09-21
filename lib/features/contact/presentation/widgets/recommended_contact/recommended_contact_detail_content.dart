import 'package:anoxia/features/contact/presentation/widgets/recommended_contact/recommended_contact_profile_card.dart';
import 'package:anoxia/features/contact/presentation/widgets/recommended_contact/recommended_contact_request_form.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:flutter/material.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 名片公开资料 + 好友请求表单的组合内容
///
/// 供 [RecommendedContactDetailPage]（移动端/Web SP 跳转页）与
/// 桌面端/Web PC 的弹窗展示共用，保证两种形态内容一致。
class RecommendedContactDetailContent extends ConsumerWidget {
  final CardPayload card;

  const RecommendedContactDetailContent({super.key, required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = int.tryParse(card.entityId ?? '');
    final contactMap = ref.watch(contactListServiceProvider).value;
    final isFriend = userId != null && contactMap?.containsKey(userId) == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RecommendedContactProfileCard(card: card),
        const SizedBox(height: SpacingToken.xl),
        RecommendedContactRequestForm(
          userId: userId,
          isFriend: isFriend,
        ),
      ],
    );
  }
}
