import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/contact/presentation/widgets/contact_detail/contact_recommend_dialog.dart';
import 'package:anoxia/framework/domain/chat_contact_detail_vo.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/contact/contact_detail_controller.dart';
import 'package:anoxia/framework/provider/layout/layout_controller.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// 联系人详情操作按钮组件
///
/// 提供"推荐给好友"和"发消息"两个主要操作
class ContactDetailActions extends ConsumerWidget {
  final ChatContactDetailVO detail;

  const ContactDetailActions({super.key, required this.detail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCreating = ref.watch(contactChatLoadingProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _recommendToFriend(context, ref, detail),
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedUserAdd01,
                size: 20,
                color: colorScheme.primary,
              ),
              label: Text('contact_recommend_to_friend'.tr()),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: isCreating
                  ? null
                  : () async {
                      final targetId = detail.userId;
                      if (targetId == null) return;

                      ref
                          .read(contactChatLoadingProvider.notifier)
                          .set(true);

                      try {
                        final roomId = await ref
                            .read(roomListServiceProvider.notifier)
                            .getOrCreateRoom(targetId);

                        if (roomId != null) {
                          ref
                              .read(activeRoomIdProvider.notifier)
                              .setActive(roomId);
                          ref
                              .read(layoutControllerProvider.notifier)
                              .setIndex(0);
                        }
                      } finally {
                        ref
                            .read(contactChatLoadingProvider.notifier)
                            .set(false);
                      }
                    },
              icon: isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : HugeIcon(
                      icon: HugeIcons.strokeRoundedChatting01,
                      size: 20,
                      color: colorScheme.onPrimary,
                    ),
              label: Text(
                isCreating
                    ? 'contact_friend_request_sending'.tr()
                    : 'chat_send_message'.tr(),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _recommendToFriend(
    BuildContext context,
    WidgetRef ref,
    ChatContactDetailVO detail,
  ) async {
    final userId = detail.userId;
    if (userId == null) return;

    final room = await showDialog<ChatRoomVO>(
      context: context,
      builder: (_) => const ContactRecommendDialog(),
    );
    final roomId = room?.roomId;
    if (roomId == null || !context.mounted) return;

    final card = CardPayload(
      cardType: 'contact',
      entityId: userId.toString(),
      title: detail.nickName?.trim().isNotEmpty == true
          ? detail.nickName!.trim()
          : (detail.userName?.trim().isNotEmpty == true
              ? detail.userName!.trim()
              : userId.toString()),
      summary: detail.userName,
      thumbnailUrl: detail.avatar,
      properties: {
        if (detail.userName?.trim().isNotEmpty == true)
          'userName': detail.userName!.trim(),
        if (detail.sex?.trim().isNotEmpty == true) 'sex': detail.sex!.trim(),
      },
    );

    final sent = ref
        .read(chatInputControllerProvider(roomId).notifier)
        .sendCardMessage(card);
    Toast.showToast(
      sent
          ? 'contact_recommend_sent'.tr(args: [room?.roomName ?? ''])
          : 'contact_recommend_send_failed'.tr(),
      type: sent ? ToastType.success : ToastType.error,
    );
  }
}