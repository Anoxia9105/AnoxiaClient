// P0-2 单聊已读回执：判定纯函数 + 成员 VO 解析边界测试。
import 'package:anoxia/common/utils/peer_read_receipt.dart';
import 'package:anoxia/framework/domain/chat_room_member_vo.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('evaluatePeerReadIndicator 判定边界', () {
    PeerReadIndicator eval({
      bool isMine = true,
      DeliveryStatus status = DeliveryStatus.sent,
      bool isSingleChat = true,
      int? messageSeq = 10,
      int? peerReadSeq = 8,
    }) => evaluatePeerReadIndicator(
      isMine: isMine,
      deliveryStatus: status,
      isSingleChat: isSingleChat,
      messageSeq: messageSeq,
      peerReadSeq: peerReadSeq,
    );

    test('对端水位 == 消息 seq → 已读（等于算已读）', () {
      expect(eval(messageSeq: 10, peerReadSeq: 10), PeerReadIndicator.read);
    });

    test('对端水位 > 消息 seq → 已读', () {
      expect(eval(messageSeq: 10, peerReadSeq: 11), PeerReadIndicator.read);
    });

    test('对端水位 < 消息 seq → 已送达（降级态）', () {
      expect(
        eval(messageSeq: 11, peerReadSeq: 10),
        PeerReadIndicator.delivered,
      );
    });

    test('对端水位未知（null）→ 已送达，不猜已读', () {
      expect(eval(peerReadSeq: null), PeerReadIndicator.delivered);
    });

    test('消息无 seq（未 ACK 定位）→ 已送达兜底', () {
      expect(
        eval(messageSeq: null, peerReadSeq: 99),
        PeerReadIndicator.delivered,
      );
    });

    test('sending / failed 不展示回执（保留原指示器）', () {
      expect(eval(status: DeliveryStatus.sending), PeerReadIndicator.none);
      expect(eval(status: DeliveryStatus.failed), PeerReadIndicator.none);
    });

    test('非本人消息不展示', () {
      expect(eval(isMine: false), PeerReadIndicator.none);
    });

    test('群聊 / AI 房间不展示（v1 仅单聊）', () {
      expect(eval(isSingleChat: false), PeerReadIndicator.none);
    });
  });

  group('ChatRoomMemberVO.lastReadSeq 解析', () {
    test('整型与字符串数字都解析，缺失为 null', () {
      expect(
        ChatRoomMemberVO.fromJson({'userId': 2, 'lastReadSeq': 12}).lastReadSeq,
        12,
      );
      expect(
        ChatRoomMemberVO.fromJson({
          'userId': 2,
          'lastReadSeq': '12',
        }).lastReadSeq,
        12,
      );
      expect(ChatRoomMemberVO.fromJson({'userId': 2}).lastReadSeq, isNull);
      expect(
        ChatRoomMemberVO.fromJson({
          'userId': 2,
          'lastReadSeq': 'bad',
        }).lastReadSeq,
        isNull,
      );
    });

    test('copyWith 支持覆盖已读水位（收到推送快照时使用）', () {
      final member = ChatRoomMemberVO(userId: 2, lastReadSeq: 1);
      expect(member.copyWith(lastReadSeq: 9).lastReadSeq, 9);
      // 无参 copyWith 保持原值
      expect(member.copyWith(onlineStatus: true).lastReadSeq, 1);
    });
  });
}
