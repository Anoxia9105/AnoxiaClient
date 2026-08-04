import 'package:anoxia/framework/provider/contact/user_search_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 推荐联系人页面的好友请求表单
///
/// 根据是否已是好友或请求是否已发送展示对应状态，并提供验证消息输入与发送。
class RecommendedContactRequestForm extends ConsumerStatefulWidget {
  final int? userId;
  final bool isFriend;

  const RecommendedContactRequestForm({
    super.key,
    required this.userId,
    required this.isFriend,
  });

  @override
  ConsumerState<RecommendedContactRequestForm> createState() =>
      _RecommendedContactRequestFormState();
}

class _RecommendedContactRequestFormState
    extends ConsumerState<RecommendedContactRequestForm> {
  final TextEditingController _verificationController =
      TextEditingController();
  bool _isSending = false;
  bool _requestSent = false;

  @override
  void dispose() {
    _verificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.isFriend || _requestSent) {
      return Container(
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
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          maxLength: 100,
          decoration: InputDecoration(
            hintText: 'add_friend_verify_hint'.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: widget.userId == null || _isSending ? null : _sendRequest,
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
        if (widget.userId == null) ...[
          const SizedBox(height: 10),
          Text(
            'contact_card_invalid'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.error),
          ),
        ],
      ],
    );
  }

  Future<void> _sendRequest() async {
    final userId = widget.userId;
    if (userId == null) return;

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
}
