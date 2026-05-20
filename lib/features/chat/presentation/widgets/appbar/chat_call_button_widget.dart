import 'package:anoxia/common/utils/DeviceUtil.dart' show DeviceUtil;
import 'package:anoxia/features/chat/presentation/widgets/appbar/chat_bar_handlers.dart';
import 'package:anoxia/framework/domain/ChatRoomVO.dart';
import 'package:anoxia/framework/provider/chat/call/call_status_provider.dart';
import 'package:anoxia/framework/provider/chat/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

class ChatCallButtonWidget extends ConsumerWidget {
  final ChatRoomVO room;
  const ChatCallButtonWidget({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callWindow = ref.watch(callWindowControllerProvider);
    final mobileCallSession = ref.watch(mobileCallSessionControllerProvider);
    final callStatus = ref.watch(roomCallStatusProvider(room.roomId ?? ''));
    
    // 首次进入拉取状态
    ref.read(callStatusControllerProvider.notifier).ensureLoaded(room.roomId ?? '');

    final colorScheme = Theme.of(context).colorScheme;
    final hasActiveCall = callWindow != null || (DeviceUtil.isRealMobile() && mobileCallSession != null);
    final isCallingNow = callStatus.calling;

    return IconButton(
      tooltip: hasActiveCall ? 'appbar_call_back_to_window'.tr() : (isCallingNow ? 'appbar_call_join'.tr() : 'appbar_start_meeting'.tr()),
      style: IconButton.styleFrom(
        backgroundColor: hasActiveCall ? colorScheme.tertiaryContainer : (isCallingNow ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => ChatBarHandlers.onCallPressed(context, ref, room),
      icon: HugeIcon(
        icon: hasActiveCall ? HugeIcons.strokeRoundedVideoReplay : (isCallingNow ? HugeIcons.strokeRoundedCallRinging03 : HugeIcons.strokeRoundedCall02),
        size: 20,
        color: hasActiveCall ? colorScheme.onTertiaryContainer : (isCallingNow ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
      ),
    );
  }
}