import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/Welcome.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_room_detail_page.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_room_list_page.dart';
import 'package:anoxia/features/chat/presentation/widgets/room_detail_settings/chat_room_detail_panel.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  @override
  Widget build(BuildContext context) {
    if (DeviceUtil.isRealMobile()) {
      return const ChatRoomList();
    }

    final activeRoomId = ref.watch(activeRoomIdProvider);
    final showRightPanel = ref.watch(chatRightPanelVisibleProvider);

    final room = activeRoomId != null
        ? ref.watch(currentRoomProvider(activeRoomId))
        : null;

    final isCompactWidth = MediaQuery.of(context).size.width < 1000;
    // 没有选中会话时右侧面板没有内容可展示，一并隐藏
    final effectiveShowRightPanel =
        showRightPanel && !isCompactWidth && activeRoomId != null;

    return Row(
      children: [
        SizedBox(
          width: isCompactWidth ? 240.0 : 320.0,
          child: const ChatRoomList(),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 12, 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.18),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: room == null
                    ? const Welcome.chat()
                    : ChatRoomDetail(roomId: activeRoomId!),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: effectiveShowRightPanel ? 320.0 : 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: effectiveShowRightPanel
                  ? Container(
                      key: ValueKey('right-panel-${activeRoomId!}'),
                      margin: const EdgeInsets.fromLTRB(8, 10, 12, 12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.18),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: ChatRoomDetailPanel(
                          roomId: activeRoomId,
                          onClose: () =>
                              ref
                                      .read(
                                        chatRightPanelVisibleProvider.notifier,
                                      )
                                      .state =
                                  false,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('right-panel-closed')),
            ),
          ),
        ),
      ],
    );
  }
}
