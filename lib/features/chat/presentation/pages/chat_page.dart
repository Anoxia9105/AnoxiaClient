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
    final currentRoom = ref.watch(activeRoomProvider);

    return Row(
      children: [
        // 左侧房间列表（固定宽度
        SizedBox(width: 90.w, child: const ChatRoomList()),
        const VerticalDivider(),
        Expanded(
          child: currentRoom == null
              // 未选择房间时显示欢迎页
              ? const Center(child: Welcome())
              : Row(
                  children: [
                    // 中间聊天详情
                    const Expanded(child: ChatRoomDetail()),
                    const VerticalDivider(),
                    // 右侧搜索面板（可选
                    if (currentRoom.isOpenSearch == true)
                      SizedBox(
                        width: 100.w,
                        child: SearchContextPage(
                          roomId: currentRoom.roomId!,
                          roomName:
                              currentRoom.roomName ??
                              'appbar_conversation_detail'.tr(),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
