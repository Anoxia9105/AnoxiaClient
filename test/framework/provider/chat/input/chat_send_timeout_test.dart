// 发送超时计算单元测试。
//
// resolveSendTimeoutSeconds 直接决定消息何时被标记失败：
// 超时过短 = 大消息/慢网络下注定失败；过长 = 气泡永远转圈。
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/chat/input/chat_send_timeout.dart';
import 'package:flutter_test/flutter_test.dart';

List<Attachment> attachmentsOf(int count) => [
      for (var i = 0; i < count; i++)
        Attachment(id: 'a$i', kind: 'FILE', url: 'u$i', name: 'f$i', size: 1, type: 'text/plain'),
    ];

void main() {
  group('resolveSendTimeoutSeconds', () {
    test('无附件文本消息为基础 10 秒', () {
      expect(
        resolveSendTimeoutSeconds(type: MessageType.text),
        10,
      );
    });

    test('每个附件加 2 秒', () {
      expect(
        resolveSendTimeoutSeconds(type: MessageType.image, attachments: attachmentsOf(1)),
        12,
      );
      expect(
        resolveSendTimeoutSeconds(type: MessageType.image, attachments: attachmentsOf(5)),
        20,
      );
    });

    test('媒体类型（音频/文件/视频）额外加 5 秒', () {
      for (final type in [MessageType.audio, MessageType.file, MessageType.video]) {
        expect(
          resolveSendTimeoutSeconds(type: type),
          15,
          reason: 'type=$type 应有媒体加成',
        );
      }
      // 媒体类型 + 附件同样叠加
      expect(
        resolveSendTimeoutSeconds(type: MessageType.video, attachments: attachmentsOf(2)),
        19,
      );
    });

    test('下限 10 秒钳制（相对来说只防负/更小值）', () {
      // 0 附件非媒体 = 10s 本来就是下限
      final d = resolveSendTimeoutSeconds(type: MessageType.text);
      expect(d, greaterThanOrEqualTo(10));
    });

    test('上限 30 秒钳制（大量附件不会无限增长）', () {
      expect(
        resolveSendTimeoutSeconds(type: MessageType.file, attachments: attachmentsOf(50)),
        30,
      );
    });
  });
}
