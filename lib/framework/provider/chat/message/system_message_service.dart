import 'package:anoxia/common/utils/NotificationHelper.dart';
import 'package:anoxia/framework/domain/ChatRoomVO.dart';
import 'package:anoxia/framework/protocol/PacketType.dart';
import 'package:anoxia/framework/protocol/message/MessageEunm.dart';
import 'package:anoxia/framework/protocol/message/RoomMessage.dart';
import 'package:anoxia/framework/provider/chat/call/call_status_provider.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../logs/talker.dart';

part 'system_message_service.g.dart';

/// 系统信令消息监听服务
/// 
/// 专门拦截 RoomMessage 中的 system 类型，处理通话挂断、禁言、解散、通知等衍生旁路业务
@Riverpod(keepAlive: true)
class SystemMessageService extends _$SystemMessageService {
  @override
  void build() {
    final stream = ref.watch(wsControllerProvider.notifier).messageStream;

    final subscription = stream
        .where((frame) => frame.topic == PacketType.message)
        .map((frame) => frame.data as RoomMessage)
        .where((msg) => msg.type == MessageType.system) // 只拦截系统消息
        .listen(_onSystemMessageReceived);

    ref.onDispose(() => subscription.cancel());
  }

  void _onSystemMessageReceived(RoomMessage msg) {
    final roomId = msg.roomId;
    final action = msg.extra['action']?.toString().toUpperCase();
    if (roomId.isEmpty || action == null || action.isEmpty) return;

    _processRoomStatusAction(roomId, action, msg.extra);
    _processCallStatusAction(roomId, action, msg);
  }
  /// 1. 处理房间层面的信令更新
  void _processRoomStatusAction(String roomId, String action, Map<String, dynamic> extra) {
    int? nextStatus;
    switch (action) {
      case 'ROOM_MUTED':
        nextStatus = extra['isMute'] == true ? 1 : 0;
        break;
      case 'ROOM_DISSOLVED':
        nextStatus = extra['type']?.toString().toLowerCase() == 'ban' ? 2 : 3;
        break;
      case 'ROOM_CREATED':
        if (extra['type']?.toString().toLowerCase() == 'unban') nextStatus = 0;
        break;
    }

    if (nextStatus != null) {
      ref.read(roomListServiceProvider.notifier).updateRoomStatus(roomId, nextStatus);
      log.info('房间 $roomId 状态根据系统信令 [$action] 异步变更为: $nextStatus');
    }
  }

  /// 2. 处理音视频通话层面的信令与桌面通知
  void _processCallStatusAction(String roomId, String action, RoomMessage msg) {
    final callStatus = ref.read(callStatusControllerProvider.notifier);
    final extra = msg.extra;

    if (action == 'CALL_STARTED') {
      final startTime = (extra['startTime'] as num?)?.toInt() ?? msg.timestamp.toInt();
      callStatus.markStarted(roomId, startTime: startTime);
      _sendDesktopNotification(roomId, action, msg);
    } else if (action == 'CALL_ENDED') {
      callStatus.markEnded(roomId);
      _sendDesktopNotification(roomId, action, msg);
    }
  }

  /// 3. 本地桌面横幅通知投递
  void _sendDesktopNotification(String roomId, String action, RoomMessage msg) {
    final rooms = ref.read(roomListServiceProvider).value ?? const <ChatRoomVO>[];
    final room = rooms.firstWhere((r) => r.roomId == roomId, orElse: () => ChatRoomVO());
    final roomName = (room.roomName?.isNotEmpty == true) ? room.roomName! : '通话通知';

    final extra = msg.extra;
    String body = '';

    if (action == 'CALL_STARTED') {
      final nickName = extra['nickName']?.toString();
      body = (nickName?.isNotEmpty == true) ? '$nickName 发起了通话' : '房间通话已开始';
    } else {
      final durationText = extra['durationText']?.toString();
      body = (durationText?.isNotEmpty == true) ? '房间通话已结束:$durationText' : '房间通话已结束';
    }

    NotificationHelper().show(
      id: roomId.hashCode ^ action.hashCode,
      title: roomName,
      body: body,
      payload: roomId,
      avatarUrl: msg.senderAvatar,
      force: true,
    );
  }
}