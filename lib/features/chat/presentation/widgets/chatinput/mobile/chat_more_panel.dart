import 'package:anoxia/common/utils/DeviceUtil.dart' show DeviceUtil;
import 'package:anoxia/features/chat/presentation/widgets/appbar/chat_bar_handlers.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:anoxia/framework/provider/chat/call/call_status_provider.dart';
import 'package:anoxia/framework/provider/chat/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'chat_action_item.dart';

/// Mobile chat attachment and call actions.
class ChatMorePanel extends ConsumerWidget {
  final String roomId;
  final Function(FileType type, bool isImage) onPickFile;
  final VoidCallback onMentionTap;

  const ChatMorePanel({
    super.key,
    required this.roomId,
    required this.onPickFile,
    required this.onMentionTap,
  });

  Future<void> _handleCallTap(
    BuildContext context,
    WidgetRef ref,
    CallInitialMedia initialMedia,
  ) async {
    final mobileSession = ref.read(mobileCallSessionControllerProvider);
    final callWindow = ref.read(callWindowControllerProvider);
    final hasActiveCall =
        callWindow != null ||
        (DeviceUtil.isRealMobile() && mobileSession != null);

    if (hasActiveCall && DeviceUtil.isRealMobile()) {
      if (mobileSession != null && mobileSession.roomId == roomId) {
        ref.read(mobileCallSessionControllerProvider.notifier).enterCallPage();
        return;
      }

      final switchConfirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('call_switch_confirm_title'.tr()),
          content: Text('call_switch_confirm_message'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('cancel'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('confirm'.tr()),
            ),
          ],
        ),
      );
      if (switchConfirmed != true || !context.mounted) return;
      ref.read(mobileCallSessionControllerProvider.notifier).end();
    }

    final room = ref.read(currentRoomProvider(roomId));
    if (room == null || !context.mounted) return;
    await ChatBarHandlers.onCallPressed(
      context,
      ref,
      room,
      initialMedia: initialMedia,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callWindow = ref.watch(callWindowControllerProvider);
    final mobileCallSession = ref.watch(mobileCallSessionControllerProvider);
    final callStatus = ref.watch(roomCallStatusProvider(roomId));

    ref.read(callStatusControllerProvider.notifier).ensureLoaded(roomId);

    final hasActiveCall =
        callWindow != null ||
        (DeviceUtil.isRealMobile() && mobileCallSession != null);
    final isCallingNow = callStatus.calling;
    final callIcon = hasActiveCall
        ? HugeIcons.strokeRoundedVideoReplay
        : HugeIcons.strokeRoundedCallRinging03;
    final callLabel = hasActiveCall
        ? 'appbar_call_back_to_window'.tr()
        : 'appbar_call_join'.tr();

    return GridView.count(
      crossAxisCount: 4,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ChatActionItem(
          icon: HugeIcons.strokeRoundedImage02,
          label: 'toolbar_image'.tr(),
          onTap: () => onPickFile(FileType.image, true),
        ),
        ChatActionItem(
          icon: HugeIcons.strokeRoundedFiles02,
          label: 'toolbar_file'.tr(),
          onTap: () => onPickFile(FileType.any, false),
        ),
        ChatActionItem(
          icon: HugeIcons.strokeRoundedAt,
          label: '@',
          onTap: onMentionTap,
        ),
        if (hasActiveCall || isCallingNow)
          ChatActionItem(
            icon: callIcon,
            label: callLabel,
            onTap: () => _handleCallTap(context, ref, CallInitialMedia.audio),
          )
        else ...[
          ChatActionItem(
            icon: HugeIcons.strokeRoundedCall02,
            label: 'call_audio_call'.tr(),
            onTap: () => _handleCallTap(context, ref, CallInitialMedia.audio),
          ),
          ChatActionItem(
            icon: HugeIcons.strokeRoundedVideo01,
            label: 'call_video_call'.tr(),
            onTap: () => _handleCallTap(context, ref, CallInitialMedia.video),
          ),
        ],
      ],
    );
  }
}
