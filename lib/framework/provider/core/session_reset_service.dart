import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chat/call/call_status_provider.dart';
import '../chat/call/call_window_controller.dart';
import '../chat/call/history_panel_provider.dart';
import '../chat/call/room_controller.dart';
import '../chat/input/chat_input_controller.dart';
import '../chat/input/files/chat_file_upload_controller.dart';
import '../chat/input/images/chat_image_upload_controller.dart';
import '../chat/message/high_message_service.dart';
import '../chat/message/room_message_service.dart';
import '../chat/message/search_message_service.dart';
import '../chat/message/system_event_service.dart';
import '../chat/room/create_new_gropu_controller.dart';
import '../chat/room/pinned_rooms_provider.dart';
import '../chat/room/room_list_service.dart';
import '../chat/room/room_member_service.dart';
import '../contact/contact_detail_controller.dart';
import '../contact/contact_list_controller.dart';
import '../contact/contact_requests_controller.dart';
import '../contact/contact_selection_controller.dart';
import '../contact/user_search_service.dart';
import '../note/note_provider.dart';
import '../ws/ws_controller.dart';
import 'app_initializer.dart';

/// 统一的会话级状态重置入口。
///
/// 目标：
/// 1) 避免登出时散落 invalidate，降低漏清理风险；
/// 2) 新增会话级 provider 时只维护这一处；
/// 3) 支持未来“切号/账号切换”复用同一套清理逻辑。
void resetSessionProviders(
  Ref ref, {
  bool includeWs = true,
  bool includeInitializer = true,
}) {
  // ── 聊天输入 & 上传 ──
  ref.invalidate(chatInputControllerProvider);
  ref.invalidate(mentionStateProvider);
  ref.invalidate(chatImageUploadControllerProvider);
  ref.invalidate(chatFileUploadControllerProvider);

  // ── 消息相关 ──
  ref.invalidate(chatMessagesProvider);
  ref.invalidate(chatHasMoreProvider);
  ref.invalidate(highMessageServiceProvider);
  ref.invalidate(searchMessageServiceProvider);
  ref.invalidate(systemEventServiceProvider);

  // ── 房间 / 成员 / 通话 ──
  ref.invalidate(roomListServiceProvider);
  ref.invalidate(activeRoomIdProvider);
  ref.invalidate(activeRoomProvider);
  ref.invalidate(roomSearchQueryProvider);
  ref.invalidate(roomEntryTaskProvider);
  ref.invalidate(roomMemberServiceProvider);
  ref.invalidate(pinnedRoomsProvider);
  ref.invalidate(callStatusControllerProvider);
  ref.invalidate(historyPanelProvider);
  ref.invalidate(roomControllerProvider);
  ref.invalidate(roomTokenProvider);
  ref.invalidate(callWindowControllerProvider);

  // ── 建群流程临时态 ──
  ref.invalidate(selectedContactIdsProvider);
  ref.invalidate(createGroupControllerProvider);

  // ── 联系人 / 搜索 ──
  ref.invalidate(contactListServiceProvider);
  ref.invalidate(contactRequestsServiceProvider);
  ref.invalidate(contactSelectionProvider);
  ref.invalidate(contactDetailDataProvider);
  ref.invalidate(userSearchServiceProvider);

  // ── 笔记（会话隔离） ──
  ref.invalidate(noteProvider);

  // ── WebSocket / 初始化状态 ──
  if (includeWs) {
    ref.invalidate(wsControllerProvider);
  }
  if (includeInitializer) {
    ref.invalidate(appInitializerProvider);
  }
}
