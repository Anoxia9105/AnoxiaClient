import 'package:anoxia/features/contact/presentation/widgets/recommended_contact/recommended_contact_profile_card.dart';
import 'package:anoxia/features/contact/presentation/widgets/recommended_contact/recommended_contact_request_form.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 从名片进入的公开资料与好友请求页面
class RecommendedContactDetailPage extends ConsumerWidget {
  final CardPayload card;

  const RecommendedContactDetailPage({
    super.key,
    required this.card,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = int.tryParse(card.entityId ?? '');
    final contactMap = ref.watch(contactListServiceProvider).value;
    final isFriend = userId != null && contactMap?.containsKey(userId) == true;

    return Scaffold(
      appBar: AppBar(title: Text('contact_card_detail_title'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RecommendedContactProfileCard(card: card),
                const SizedBox(height: 24),
                RecommendedContactRequestForm(
                  userId: userId,
                  isFriend: isFriend,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
