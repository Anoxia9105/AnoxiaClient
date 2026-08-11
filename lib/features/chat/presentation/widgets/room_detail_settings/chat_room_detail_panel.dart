import 'package:anoxia/features/chat/presentation/widgets/room_detail_settings/room_detail_settings_body.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 桌面端右侧聊天详情面板
///
/// 嵌入在 [ChatPage] 右侧固定宽度容器中，复用 [RoomDetailSettingsBody]，
/// 只是换成轻量 Header（标题 + 关闭按钮），不带 Scaffold/AppBar。
class ChatRoomDetailPanel extends StatelessWidget {
  final String roomId;
  final VoidCallback onClose;

  const ChatRoomDetailPanel({
    super.key,
    required this.roomId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'chat_conversation_detail'.tr(),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: onClose,
                tooltip: 'close'.tr(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.18),
        ),
        Expanded(
          child: RoomDetailSettingsBody(
            roomId: roomId,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          ),
        ),
      ],
    );
  }
}
