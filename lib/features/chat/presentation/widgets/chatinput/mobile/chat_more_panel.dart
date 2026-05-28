import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:anoxia/common/utils/DeviceUtil.dart' show DeviceUtil;
import 'package:anoxia/features/chat/presentation/widgets/appbar/chat_bar_handlers.dart';
import 'package:anoxia/framework/provider/chat/call/call_status_provider.dart';
import 'package:anoxia/framework/provider/chat/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'chat_action_item.dart';

/// 聊天更多操作面板组件
class ChatMorePanel extends ConsumerWidget {
  /// 房间 ID
  final String roomId;

  /// 文件选择回调，参数为文件类型和是否为图片
  final Function(FileType type, bool isImage) onPickFile;

  /// @提及按钮点击回调
  final VoidCallback onMentionTap;

  const ChatMorePanel({
    super.key,
    required this.roomId,
    required this.onPickFile,
    required this.onMentionTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 动态订阅状态（驱动 UI 图标和文案刷新）
    final callWindow = ref.watch(callWindowControllerProvider);
    final mobileCallSession = ref.watch(mobileCallSessionControllerProvider);
    final callStatus = ref.watch(roomCallStatusProvider(roomId));

    // 确保加载房间的通话状态
    ref.read(callStatusControllerProvider.notifier).ensureLoaded(roomId);

    // 💡 判断当前是否存在处于激活状态的通话会话
    final hasActiveCall =
        callWindow != null ||
        (DeviceUtil.isRealMobile() && mobileCallSession != null);
    final isCallingNow = callStatus.calling;

    // 根据状态决定通话按钮的图标和文案
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
        //  优化后的通话按钮
        ChatActionItem(
          icon: callIcon,
          label: callLabel,
          onTap: () async {
            // 读取一次 session 与 callWindow（不订阅）
            final mobileSession = ref.read(mobileCallSessionControllerProvider);
            final callWindow = ref.read(callWindowControllerProvider);

            final hasActiveCallLocal =
                callWindow != null ||
                (DeviceUtil.isRealMobile() && mobileSession != null);

            // 如果存在活跃通话并且是移动端，优先恢复全屏
            if (hasActiveCallLocal && DeviceUtil.isRealMobile()) {
              // 如果当前会话就是本房间，直接恢复
              if (mobileSession != null && mobileSession.roomId == roomId) {
                ref
                    .read(mobileCallSessionControllerProvider.notifier)
                    .enterCallPage();
                return;
              }

              // 活跃通话是别的房间，提示用户确认切换
              final switchConfirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('call_switch_confirm_title'.tr()),
                  content: Text('call_switch_confirm_message'.tr()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text('cancel'.tr()),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text('confirm'.tr()),
                    ),
                  ],
                ),
              );

              // dialog 返回后可能已卸载，先检查
              if (switchConfirmed != true || !context.mounted) return;

              // 结束当前会话并进入本房间通话（或按你业务选择切换策略）
              ref.read(mobileCallSessionControllerProvider.notifier).end();

              final roomVO = ref.read(currentRoomProvider(roomId));
              if (roomVO != null && context.mounted) {
                ChatBarHandlers.onCallPressed(context, ref, roomVO);
              }
              return;
            }

            // 否则正常发起/加入通话
            final roomVO = ref.read(currentRoomProvider(roomId));
            if (roomVO == null) return;
            ChatBarHandlers.onCallPressed(context, ref, roomVO);
          },
        ),
      ],
    );
  }
}
