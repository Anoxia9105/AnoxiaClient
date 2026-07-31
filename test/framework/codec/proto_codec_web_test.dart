// 验证手写 Protobuf varint 编解码在 Web(dart2js) 下不会被 32 位位移截断。
//
// 根因：原 _readVarint 使用 `result |= (b & 0x7F) << shift`，_writeVarint 使用
// `value >>> 7`。dart2js 的 << / >>> / | 都是 32 位语义，移位量 >= 32 时高位字节
// 丢失，导致毫秒时间戳(~41 位)、seq、senderId 等 int64 字段被解成垃圾值，最终让
// 消息在 UI 合并时错乱/消失。本测试用 BigInt 修复后，需保证 VM 与 chrome 双端一致。
import 'package:anoxia/framework/codec/proto_reader.dart';
import 'package:anoxia/framework/codec/proto_writer.dart';
import 'package:anoxia/framework/codec/v5/im_packet_v5.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProtoWriter/ProtoReader varint 往返 (int64 不能丢高位)', () {
    final cases = <String, int>{
      '127': 127,
      '128': 128,
      '300': 300,
      '1<<20': 1 << 20,
      // ⚠️ 关键：超过 32 位，原实现在 dart2js 下会乱码
      '1<<31': 1 << 31,
      '1<<40': 1 << 40,
      'realistic ms timestamp (~2025)': 1750000000000,
      '1<<53 - 1 (JS 安全整数上界)': (1 << 53) - 1,
      // 负数走 64 位补码
      '-1': -1,
      '-realistic timestamp': -1750000000000,
    };

    for (final entry in cases.entries) {
      test('round-trip ${entry.key} = ${entry.value}', () {
        final w = ProtoWriter()..writeInt64(1, entry.value);
        final decoded = ProtoReader(w.toBytes()).readAll();
        expect(decoded[1], entry.value,
            reason: 'int64 值 ${entry.value} 编解码后必须完全相等');
      });
    }

    test('-1 编码为 10 字节补码 varint', () {
      final bytes = (ProtoWriter()..writeInt64(1, -1)).toBytes();
      // 跳过头 tag 单字节 (field 1, wire 0 => 0x08)
      final body = bytes.sublist(1);
      expect(body.length, 10, reason: 'int64 负数必须编码为 10 字节');
      expect(body.last, 0x01);
      expect(body.take(9).every((b) => (b & 0x80) != 0), isTrue);
    });

    test('多个 int64 字段混合不串扰', () {
      final w = ProtoWriter()
        ..writeInt64(1, 1750000000000)
        ..writeInt64(2, 161)
        ..writeInt64(3, 9876543210);
      final m = ProtoReader(w.toBytes()).readAll();
      expect(m[1], 1750000000000);
      expect(m[2], 161);
      expect(m[3], 9876543210);
    });
  });

  group('ImPacketV5.decodeRoomMessage int64 字段 (真实解码路径)', () {
    test('大 senderId / seq / timestamp 解码正确', () {
      const senderId = 1 << 45; // 大于 32 位、且在 JS 安全整数内 (>2^32 即可触发原 bug)
      const seq = 161;
      const serverTs = 1750000000000;
      const clientTs = 1749999000000;

      final payload = (ProtoWriter()
            ..writeString(1, 'b659b28e000000000000000000000001')
            ..writeString(2, '34c81250000000000000000000000002')
            ..writeString(3, 'room-1')
            ..writeInt64(4, senderId)
            ..writeUint32(5, MessageType.text.code)
            ..writeInt64(7, seq)
            ..writeInt64(8, serverTs)
            ..writeInt64(9, clientTs))
          .toBytes();

      final msg = ImPacketV5.decodeRoomMessage(payload);
      expect(msg, isNotNull);
      expect(msg!.senderId, senderId);
      expect(msg.seq, seq);
      expect(msg.serverTimestamp, serverTs);
      expect(msg.clientTimestamp, clientTs);
    });

    test('真实日志规模: clientMsgId->serverId 换绑所需字段解码一致', () {
      // 复现用户 19:35 日志：clientMsgId=34c81250… → server id=b659b28e… seq=166
      const seq = 166;
      const ts = 1751271301000; // 2025-06-30 19:35 量级时间戳

      final payload = (ProtoWriter()
            ..writeString(1, 'b659b28e000000000000000000000000')
            ..writeString(2, '34c81250000000000000000000000000')
            ..writeString(3, 'room-x')
            ..writeInt64(4, 10086)
            ..writeUint32(5, MessageType.text.code)
            ..writeInt64(7, seq)
            ..writeInt64(8, ts)
            ..writeInt64(9, ts))
          .toBytes();

      final msg = ImPacketV5.decodeRoomMessage(payload);
      expect(msg, isNotNull);
      expect(msg!.seq, 166);
      expect(msg.serverTimestamp, ts);
      expect(msg.clientTimestamp, ts);
      expect(msg.senderId, 10086);
    });
  });
}
