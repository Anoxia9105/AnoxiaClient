// 单聊已读回执判定（P0-2）。
//
// 纯函数，无 Flutter/UI 依赖，供任意端复用与边界单测。
//
// 数据来源（F1 调研结论，零协议改动）：
// 服务端 `/chat/members`（selectRoomMemberList）的 SQL 本就把
// `chat_room_member.read_seq AS lastReadSeq` 带给每个成员，
// 客户端 `ChatRoomMemberVO.fromJson` 解析后由 `roomMemberServiceProvider`
// 的 keepAlive 缓存持有（进入会话时 `roomEntryTask` 会 syncMembers 拉一次）。
// 本任务不依赖实时推送；「对端已读水位」以会话级快照为准，P1-3 云同步
// 后续提供更小的刷新点。
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';

/// 单聊消息气泡的回执展示态
enum PeerReadIndicator {
  /// 不展示（非我发 / 未送达 / 群聊 AI 房间等）
  none,

  /// 已送达（✓✓ 的降级态：seq 尚未被对端 readSeq 覆盖，或对端水位未知）
  delivered,

  /// 已读（对端 readSeq >= 消息 seq）
  read,
}

/// 判定「我发的单聊消息」在气泡旁应展示的回执态。
///
/// 口径（与计划一致）：
/// - 仅 `DeliveryStatus.sent`（已 ACK）才可能展示；sending/failed 仍走
///   原有的进度圈/错误图标，不叠加回执。
/// - 已读：`messageSeq != null && peerReadSeq >= messageSeq`。
/// - 已送达：已 ACK 但对端水位未知或尚未覆盖该 seq 的降级兜底。
/// - 群聊 / AI / 官方房间不展示（v1 仅单聊；官方房间 roomType 走
///   [RoomType.singleChat] 之外的枚举）。
PeerReadIndicator evaluatePeerReadIndicator({
  required bool isMine,
  required DeliveryStatus deliveryStatus,
  required bool isSingleChat,
  required int? messageSeq,
  required int? peerReadSeq,
}) {
  if (!isMine) return PeerReadIndicator.none;
  if (deliveryStatus != DeliveryStatus.sent) return PeerReadIndicator.none;
  if (!isSingleChat) return PeerReadIndicator.none;
  if (messageSeq != null && peerReadSeq != null && peerReadSeq >= messageSeq) {
    return PeerReadIndicator.read;
  }
  return PeerReadIndicator.delivered;
}
