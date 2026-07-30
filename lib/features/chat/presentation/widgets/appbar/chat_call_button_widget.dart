import 'package:anoxia/common/utils/device_util.dart' show DeviceUtil;
import 'package:anoxia/features/chat/presentation/widgets/appbar/chat_bar_handlers.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:anoxia/framework/provider/chat/call/call_status_provider.dart';
import 'package:anoxia/framework/provider/chat/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

class ChatCallButtonWidget extends ConsumerWidget {
  final String roomId;

  const ChatCallButtonWidget({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(currentRoomProvider(roomId));
    final callWindow = ref.watch(callWindowControllerProvider);
    final mobileCallSession = ref.watch(mobileCallSessionControllerProvider);
    final callStatus = ref.watch(roomCallStatusProvider(roomId));

    ref.read(callStatusControllerProvider.notifier).ensureLoaded(roomId);

    if (room == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final hasActiveCall =
        callWindow != null ||
        (DeviceUtil.isRealMobile() && mobileCallSession != null);
    final isCallingNow = callStatus.calling;

    if (hasActiveCall || isCallingNow) {
      return IconButton(
        mouseCursor: SystemMouseCursors.click,
        tooltip: hasActiveCall
            ? 'appbar_call_back_to_window'.tr()
            : 'appbar_call_join'.tr(),
        onPressed: () => ChatBarHandlers.onCallPressed(context, ref, room),
        icon: HugeIcon(
          icon: hasActiveCall
              ? HugeIcons.strokeRoundedVideoReplay
              : HugeIcons.strokeRoundedCallRinging03,
          size: 20,
          color: hasActiveCall
              ? colorScheme.onTertiaryContainer
              : colorScheme.onPrimaryContainer,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          mouseCursor: SystemMouseCursors.click,
          tooltip: 'call_microphone'.tr(),
          onPressed: () => ChatBarHandlers.onCallPressed(
            context,
            ref,
            room,
            initialMedia: CallInitialMedia.audio,
          ),
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedCall02,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        IconButton(
          mouseCursor: SystemMouseCursors.click,
          tooltip: 'call_camera'.tr(),
          onPressed: () => ChatBarHandlers.onCallPressed(
            context,
            ref,
            room,
            initialMedia: CallInitialMedia.video,
          ),
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedVideo01,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
