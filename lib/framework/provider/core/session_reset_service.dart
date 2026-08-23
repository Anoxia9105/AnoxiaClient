import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/core/app_globals.dart';
import 'package:anoxia/framework/provider/ai/ai_chat_controller.dart';
import 'package:anoxia/framework/provider/desktop/desktop_search_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_file_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_image_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/reply_target_provider.dart';
import 'package:anoxia/framework/provider/chat/favorite/chat_favorite_service.dart';
import 'package:anoxia/framework/provider/chat/message/high_message_service.dart';
import 'package:anoxia/framework/provider/chat/message/search_message_service.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
import 'package:anoxia/framework/provider/chat/room/group_join_service.dart';
import 'package:anoxia/framework/provider/chat/room/create_new_group_controller.dart';
import 'package:anoxia/framework/provider/chat/sticker/sticker_packs_provider.dart';
import 'package:anoxia/framework/provider/contact/contact_detail_controller.dart';
import 'package:anoxia/framework/provider/contact/contact_requests_controller.dart';
import 'package:anoxia/framework/provider/contact/contact_selection_controller.dart';
import 'package:anoxia/framework/provider/contact/user_search_service.dart';
import 'package:anoxia/framework/provider/chat/call/call_status_provider.dart';
import 'package:anoxia/framework/provider/layout/layout_controller.dart';
import 'package:anoxia/framework/provider/note/note_content_provider.dart';
import 'package:anoxia/framework/provider/note/note_open_provider.dart';
import 'package:anoxia/framework/provider/note/note_tag_provider.dart';
import 'package:anoxia/framework/provider/note/note_trash_provider.dart';
import 'package:anoxia/framework/provider/note/note_tree_provider.dart';
import 'package:anoxia/framework/provider/note/note_version_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SessionResetReason { logout, tokenExpired, accountSwitch }

/// 会话级状态统一重置入口。
///
/// 约束：
/// - 所有与账号强相关的缓存/控制器，统一在此处登记与清理
/// - 登出、token 失效、切账号等场景都复用本入口
class SessionResetService {
  SessionResetService._();

  static final SessionResetService instance = SessionResetService._();

  // 仅用于日志与维护清单，避免清理点散落。
  static const List<String> managedScopes = <String>[
    'roomMemberServiceProvider',
    'roomListServiceProvider',
    'activeRoomIdProvider',
    'chatMessagesProvider',
    'chatHasMoreProvider',
    'chatInputControllerProvider(*)',
    'chatFocusNodeProvider(*)',
    'mentionStateProvider',
    'replyTargetControllerProvider',
    'chatImageUploadControllerProvider',
    'chatFileUploadControllerProvider',
    'roomSearchQueryProvider',
    'chatFavoriteListProvider',
    'noteTreeServiceProvider',
    'noteTagServiceProvider',
    'noteSessionServiceProvider',
    'noteTrashServiceProvider',
    'noteVersionServiceProvider',
    'noteTagFilterProvider(*)',
    'noteOpenRequestProvider(*)',
    'layoutControllerProvider',
    'contactSelectionProvider',
    'contactDetailDataProvider(*)',
    'selectedContactIdsProvider',
    'contactRequestsServiceProvider',
    'userSearchServiceProvider',
    'searchMessageServiceProvider',
    'highMessageServiceProvider',
    'groupJoinRequestsServiceProvider(*)',
    'callStatusControllerProvider',
    'stickerPacksProvider',
    'aiChatControllerProvider',
    'desktopSearchControllerProvider',
    'createGroupControllerProvider',
  ];

  void reset(Ref ref, {required SessionResetReason reason}) {
    final reasonLabel = reason.name;
    debugLog('[SessionReset] 开始重置会话状态, reason=$reasonLabel');

    // 使用全局容器执行失效，避免在 AuthController 的 provider 上下文内
    // invalidate 依赖到间接依赖 auth 的 provider 时触发环依赖断言。
    final container = globalContainer;

    // 先清理成员缓存，避免保留旧账号的“已同步房间集合”。
    container.read(roomMemberServiceProvider.notifier).clearAll();

    // 统一失效账号强相关 Provider。
    container.invalidate(roomMemberServiceProvider);
    container.invalidate(roomListServiceProvider);
    container.invalidate(activeRoomIdProvider);
    container.invalidate(chatMessagesProvider);
    container.invalidate(chatHasMoreProvider);
    container.invalidate(chatInputControllerProvider);
    container.invalidate(chatFocusNodeProvider);
    container.invalidate(mentionStateProvider);
    container.invalidate(replyTargetControllerProvider);
    container.invalidate(chatImageUploadControllerProvider);
    container.invalidate(chatFileUploadControllerProvider);
    container.invalidate(roomSearchQueryProvider);
    container.invalidate(chatFavoriteListProvider);

    // 记事本：树 / 标签 / 回收站 / 版本历史 / 编辑会话均与账号强相关，
    // 登出或切账号后必须失效，否则新账号进入记事本会看到上一个账号的
    // 笔记树、标签、回收站与正在编辑的内容。
    container.invalidate(noteTreeServiceProvider);
    container.invalidate(noteTagServiceProvider);
    container.invalidate(noteSessionServiceProvider);
    container.invalidate(noteTrashServiceProvider);
    container.invalidate(noteVersionServiceProvider);
    // 标签筛选与深链打开请求为纯内存状态，一并复位。
    container.read(noteTagFilterProvider.notifier).state = null;
    container.read(noteOpenRequestProvider.notifier).state = null;

    // 侧边栏选中位置复位到「聊天」：登出/切账号后不保留上个账号的
    // 浏览位置（IndexedStack 常驻，MainLayoutPage 未卸载时该状态会跨会话存活）。
    container.read(layoutControllerProvider.notifier).setIndex(0);

    // 联系人详情：清空选中视图（联系人详细/新的朋友/群聊列表）与
    // 按用户缓存的详情数据，避免新账号看到上个账号查看过的联系人详情。
    container.invalidate(contactSelectionProvider);
    container.invalidate(contactDetailDataProvider);

    // 建群弹窗已选联系人集合为纯内存状态，一并清空。
    container.invalidate(selectedContactIdsProvider);

    // 好友申请列表（「新的朋友」）：keepAlive 且直接从远端拉取，
    // 不失效的话切账号后侧边栏红点与新账号的申请页都会显示上一个
    // 账号的好友申请。pendingRequestCountProvider watch 本源，级联重建。
    container.invalidate(contactRequestsServiceProvider);

    // 用户搜索结果：上个账号搜到的用户列表对新账号无意义，一并清空。
    container.invalidate(userSearchServiceProvider);

    // 消息搜索状态：持有旧账号房间内的搜索命中消息，必须复位。
    container.invalidate(searchMessageServiceProvider);

    // 高优消息状态（正在输入/通话信令等，按 roomId 缓存）：
    // 房间 ID 跨账号可能复用，残留会让新账号看到幽灵「正在输入」。
    container.invalidate(highMessageServiceProvider);

    // 入群申请列表与红点（按 roomId 的 family 缓存）：
    // 不带参数 invalidate 会失效该 family 的所有实例。
    container.invalidate(groupJoinRequestsServiceProvider);

    // 各房间通话状态缓存（含已加载房间集合），随会话一并重置。
    container.invalidate(callStatusControllerProvider);

    // 表情包列表为当前账号的服务端数据，切账号后需重新拉取。
    container.invalidate(stickerPacksProvider);

    // AI 对话历史 / 桌面聚合搜索关键词与结果：上个账号的会话痕迹。
    container.invalidate(aiChatControllerProvider);
    container.invalidate(desktopSearchControllerProvider);

    // 建群结果 AsyncNotifier：上个账号创建中的群聊状态不应带入新会话。
    container.invalidate(createGroupControllerProvider);

    debugLog(
      '[SessionReset] 会话状态重置完成, reason=$reasonLabel, scopes=${managedScopes.length}',
    );
  }
}
