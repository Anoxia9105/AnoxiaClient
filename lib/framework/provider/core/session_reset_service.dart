import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/provider/chat/input/files/chat_file_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/images/chat_image_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_member_service.dart';
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
    'chatImageUploadControllerProvider',
    'chatFileUploadControllerProvider',
    'roomSearchQueryProvider',
  ];

  void reset(Ref ref, {required SessionResetReason reason}) {
    final reasonLabel = reason.name;
    log.info('[SessionReset] 开始重置会话状态, reason=$reasonLabel');

    // 先清理成员缓存，避免保留旧账号的“已同步房间集合”。
    ref.read(roomMemberServiceProvider.notifier).clearAll();

    // 统一失效账号强相关 Provider。
    ref.invalidate(roomMemberServiceProvider);
    ref.invalidate(roomListServiceProvider);
    ref.invalidate(activeRoomIdProvider);
    ref.invalidate(chatMessagesProvider);
    ref.invalidate(chatHasMoreProvider);
    ref.invalidate(chatInputControllerProvider);
    ref.invalidate(chatFocusNodeProvider);
    ref.invalidate(mentionStateProvider);
    ref.invalidate(chatImageUploadControllerProvider);
    ref.invalidate(chatFileUploadControllerProvider);
    ref.invalidate(roomSearchQueryProvider);

    log.info(
      '[SessionReset] 会话状态重置完成, reason=$reasonLabel, scopes=${managedScopes.length}',
    );
  }
}
