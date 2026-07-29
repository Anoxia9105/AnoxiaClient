import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/framework/provider/contact/contact_list_controller.dart';
import 'package:anoxia/framework/provider/contact/user_search_service.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Public profile and friend-request page opened from a contact card.
class RecommendedContactDetailPage extends ConsumerStatefulWidget {
  final CardPayload card;

  const RecommendedContactDetailPage({super.key, required this.card});

  @override
  ConsumerState<RecommendedContactDetailPage> createState() =>
      _RecommendedContactDetailPageState();
}

class _RecommendedContactDetailPageState
    extends ConsumerState<RecommendedContactDetailPage> {
  final TextEditingController _verificationController = TextEditingController();
  bool _isSending = false;
  bool _requestSent = false;

  int? get _userId => int.tryParse(widget.card.entityId ?? '');

  @override
  void dispose() {
    _verificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final colorScheme = Theme.of(context).colorScheme;
    final userId = _userId;
    final contactMap = ref.watch(contactListServiceProvider).value;
    final isFriend = userId != null && contactMap?.containsKey(userId) == true;
    final userName = card.properties['userName']?.trim().isNotEmpty == true
        ? card.properties['userName']!.trim()
        : card.displaySummary;
    final sex = card.properties['sex'];

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
                Card(
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
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 20),
                        _PublicInfoRow(
                          label: 'contact_username'.tr(),
                          value: userName,
                        ),
                        const Divider(height: 24),
                        _PublicInfoRow(
                          label: 'contact_gender'.tr(),
                          value: _translatedGender(sex),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (isFriend || _requestSent)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _requestSent
                                ? 'add_friend_request_sent'.tr()
                                : 'contact_already_friend'.tr(),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Text(
                    'contact_friend_request_message'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _verificationController,
                    maxLines: 3,
                    maxLength: 50,
                    decoration: InputDecoration(
                      hintText: 'add_friend_verify_hint'.tr(),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: userId == null || _isSending
                        ? null
                        : () => _sendFriendRequest(userId),
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.person_add_alt_1),
                    label: Text(
                      _isSending
                          ? 'contact_friend_request_sending'.tr()
                          : 'add_friend_send'.tr(),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                  if (userId == null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'contact_card_invalid'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendFriendRequest(int userId) async {
    setState(() => _isSending = true);
    final success = await ref
        .read(userSearchServiceProvider.notifier)
        .sendContactRequest(userId, _verificationController.text.trim());
    if (!mounted) return;

    setState(() {
      _isSending = false;
      _requestSent = success;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'add_friend_request_sent'.tr()
                : 'add_friend_request_failed'.tr(),
          ),
          backgroundColor: success
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
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

class _PublicInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _PublicInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value.trim().isEmpty ? '-' : value,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
