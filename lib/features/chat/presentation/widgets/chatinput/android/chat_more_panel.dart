import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:anoxia/common/utils/DeviceUtil.dart' show DeviceUtil;
import 'package:anoxia/features/chat/presentation/widgets/appbar/chat_bar_handlers.dart';
import 'package:anoxia/framework/domain/ChatRoomVO.dart';
import 'package:anoxia/framework/provider/chat/call/call_status_provider.dart';
import 'package:anoxia/framework/provider/chat/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'chat_action_item.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 监听通话状态
    final callWindow = ref.watch(callWindowControllerProvider);
    final mobileCallSession = ref.watch(mobileCallSessionControllerProvider);
    final callStatus = ref.watch(roomCallStatusProvider(roomId));

    ref.read(callStatusControllerProvider.notifier).ensureLoaded(roomId);

    final hasActiveCall =
        callWindow != null ||
        (DeviceUtil.isRealMobile() && mobileCallSession != null);
    final isCallingNow = callStatus.calling;

    // 2. 动态决定通话按钮的图标和文案
    final dynamic callIcon = hasActiveCall
        ? HugeIcons.strokeRoundedVideoReplay
        : (isCallingNow
              ? HugeIcons.strokeRoundedCallRinging03
              : HugeIcons.strokeRoundedCall02);

    final String callLabel = hasActiveCall
        ? 'appbar_call_back_to_window'.tr()
        : (isCallingNow
              ? 'appbar_call_join'.tr()
              : 'appbar_start_meeting'.tr());

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
        // 新增的通话按钮
        ChatActionItem(
          icon: callIcon,
          label: callLabel,
          onTap: () {
            final roomVO = ref.watch(currentRoomProvider(roomId));
            if (roomVO == null) return;
            ChatBarHandlers.onCallPressed(context, ref, roomVO);
          },
        ),
      ],
    );
  }
}
