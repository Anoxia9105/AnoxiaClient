import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_room_detail_page.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_room_list_page.dart';
import 'package:anoxia/features/chat/presentation/widgets/search_context_page.dart';
import 'package:anoxia/common/widgets/Welcome.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 聊天页面容器
///
/// 根据设备类型提供不同的布局：
/// - 移动端：仅显示房间列表
/// - 桌面端/平板：三栏布局（房间列表+聊天详情+搜索面板）
class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 移动端简化为单栏
    if (DeviceUtil.isRealMobile()) {
      return const ChatRoomList();
    }

    // 桌面端三栏布局
    final activeRoomId = ref.watch(activeRoomIdProvider);

    if (activeRoomId == null) {
      return Row(
        children: [
          SizedBox(width: 90.w, child: const ChatRoomList()),
          const VerticalDivider(),
          const Expanded(child: Center(child: Welcome())),
        ],
      );
    }

    final room = ref.watch(currentRoomProvider(activeRoomId));

    // 如果列表更新导致房间数据还没加载出来或房间已被解散，安全防御展示欢迎页或加载中
    if (room == null) {
      return Row(
        children: [
          SizedBox(width: 90.w, child: const ChatRoomList()),
          const VerticalDivider(),
          const Expanded(child: Center(child: Welcome())),
        ],
      );
    }

    return Row(
      children: [
        // 左侧房间列表（固定宽度）
        SizedBox(width: 90.w, child: const ChatRoomList()),
        const VerticalDivider(),
        Expanded(
          child: Row(
            children: [
              // 中间聊天详情（推荐将 ChatRoomDetail 改造为只接收 roomId）
              Expanded(
                child: ChatRoomDetail(roomId: activeRoomId),
              ),
              
              // 右侧搜索面板（根据当前房间的搜索开启状态动态挂载）
              if (room.isOpenSearch == true) ...[
                const VerticalDivider(),
                SizedBox(
                  width: 100.w,
                  child: SearchContextPage(
                    roomId: room.roomId!,
                    roomName: room.roomName ?? 'appbar_conversation_detail'.tr(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
