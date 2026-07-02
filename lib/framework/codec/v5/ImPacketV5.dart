import 'dart:typed_data';

import '../ProtoReader.dart';
import '../ProtoWriter.dart';
import '../FrameCodec.dart';
import '../../protocol/message/Attachment.dart';
import '../../protocol/message/EventMessage.dart';
import '../../protocol/message/HighMessage.dart';
import '../../protocol/message/MessageEunm.dart';
import '../../protocol/message/MessagePayload.dart';
import '../../protocol/message/RoomMessage.dart';
import '../../protocol/PacketType.dart';

/// IM V5 协议全量编解码器
///
/// 负责 V5 Protobuf 消息的编码（Dart → 二进制帧）和解码（二进制帧 → Dart）。
/// 所有方法均为静态方法，无需实例化。
class ImPacketV5 {
  ImPacketV5._();

  // ═══════════════════════════════════════════════════════════════════════════
  // 公共常量（与服务端 CodecConstants 对齐）
  // ═══════════════════════════════════════════════════════════════════════════

  static const int schemaVersion = 5;
  static const int payloadVersion = 1;

  /// Topic 数字码
  static const int topicUnknown = 0;
  static const int topicMessage = 1;
  static const int topicHighFrequency = 2;
  static const int topicEvent = 3;
  static const int topicAck = 4;

  /// Codec ID
  static const int codecRoomMessage = 1;
  static const int codecHighMessage = 2;
  static const int codecEventMessage = 3;
  static const int codecAck = 4;

  // ═══════════════════════════════════════════════════════════════════════════
  // 帧 → 解码结果
  // ═══════════════════════════════════════════════════════════════════════════

  /// 解析完整的应用层帧，返回 [DecodedFrame]；格式非法时返回 null
  static DecodedFrame? decodeFrame(Uint8List rawBytes) {
    try {
      final frame = FrameCodec.parse(rawBytes);
      if (frame.isPing) return DecodedFrame.ping();
      if (frame.isPong) return DecodedFrame.pong();
      if (!frame.isProtobuf) return null;

      return decodeEnvelope(frame.body);
    } catch (_) {
      return null;
    }
  }

  /// 解析 Protobuf Envelope，返回 [DecodedFrame]
  static DecodedFrame? decodeEnvelope(Uint8List envelopeBytes) {
    try {
      final env = ProtoReader(envelopeBytes).readAll();
      final schemaVer = env.getUint32(1); // schema_version
      final topicCode = env.getUint32(2); // topic
      final codecId = env.getUint32(3); // codec_id
      final payloadBytes = env.getBytes(5); // payload
      final roomId = env.getString(6); // room_id

      if (schemaVer != schemaVersion) return null;
      if (topicCode == topicUnknown) return null;
      if (payloadBytes.isEmpty) return null;

      final topic = _codeToTopic(topicCode);
      return DecodedFrame.data(
        topic: topic,
        codecId: codecId,
        roomId: roomId,
        payload: payloadBytes,
      );
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 消息解码（payload bytes → Dart 模型）
  // ═══════════════════════════════════════════════════════════════════════════

  /// 解码 RoomMessage
  static RoomMessage? decodeRoomMessage(Uint8List bytes) {
    try {
      final f = ProtoReader(bytes).readAll();
      final messageType = MessageType.fromCode(f.getUint32(5));
      final payloadBytes = f.getBytes(6); // MessagePayloadProtoV5

      MessagePayload? payload;
      List<Attachment> attachments = const [];

      if (payloadBytes.isNotEmpty) {
        final result = _decodeMessagePayload(payloadBytes, messageType);
        payload = result.$1;
        attachments = result.$2;
      }

      // properties: repeated StringPropertyProtoV5 = field 10
      final propsRaw = f.getRepeatedBytes(10);
      final properties = _decodeStringProperties(propsRaw);

      // 系统消息：将 system payload 的 eventCode 注入 properties['action']
      if (messageType == MessageType.system) {
        final ec = payload?.content;
        if (ec != null && ec.isNotEmpty) {
          properties.putIfAbsent('action', () => ec.toUpperCase());
        }
      }

      return RoomMessage(
        messageId: f.getString(1),
        clientMsgId: _emptyToNull(f.getString(2)),
        roomId: f.getString(3),
        senderId: f.getInt64(4),
        messageType: messageType,
        payload: payload,
        attachments: attachments,
        properties: properties,
        seq: _zeroToNull(f.getInt64(7)),
        serverTimestamp: _zeroToNull(f.getInt64(8)),
        clientTimestamp: _zeroToNull(f.getInt64(9)),
      );
    } catch (_) {
      return null;
    }
  }

  /// 解码 HighMessage
  static HighMessage? decodeHighMessage(Uint8List bytes) {
    try {
      final f = ProtoReader(bytes).readAll();
      return HighMessage(
        messageId: _emptyToNull(f.getString(1)),
        roomId: _emptyToNull(f.getString(2)),
        senderId: _zeroToNull(f.getInt64(3)),
        senderDeviceId: _emptyToNull(f.getString(4)),
        targetId: _zeroToNull(f.getInt64(5)),
        type: HighMessageType.fromCode(f.getUint32(6)),
        content: _emptyToNull(f.getString(7)),
        timestamp: _zeroToNull(f.getInt64(8)),
      );
    } catch (_) {
      return null;
    }
  }

  /// 解码 EventMessage
  static EventMessage? decodeEventMessage(Uint8List bytes) {
    try {
      final f = ProtoReader(bytes).readAll();
      final propsRaw = f.getRepeatedBytes(5);
      final properties = _decodeStringProperties(propsRaw);
      return EventMessage(
        eventType: SystemEventType.fromCode(f.getUint32(1)),
        operatorId: f.getInt64(2),
        content: _emptyToNull(f.getString(3)),
        timestamp: f.getInt64(4),
        extra: properties.isEmpty ? null : properties.cast<String, dynamic>(),
      );
    } catch (_) {
      return null;
    }
  }

  /// 解码 AckV5
  static AckV5? decodeAck(Uint8List bytes) {
    try {
      final f = ProtoReader(bytes).readAll();
      AckMeta? meta;
      final metaBytes = f.getBytes(5);
      if (metaBytes.isNotEmpty) {
        final mf = ProtoReader(metaBytes).readAll();
        meta = AckMeta(
          messageId: _emptyToNull(mf.getString(1)),
          roomId: _emptyToNull(mf.getString(2)),
          seq: _zeroToNull(mf.getInt64(3)),
          timestamp: _zeroToNull(mf.getInt64(4)),
        );
      }
      return AckV5(
        clientMessageId: _emptyToNull(f.getString(1)),
        code: f.getInt32(2),
        message: _emptyToNull(f.getString(3)),
        retryable: f.getBool(4),
        meta: meta,
      );
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 消息编码（Dart 模型 → 完整二进制帧）
  // ═══════════════════════════════════════════════════════════════════════════

  /// 编码 RoomMessage → 完整二进制帧
  static Uint8List encodeRoomMessageFrame(RoomMessage msg) {
    final payloadBytes = _encodeMessagePayload(msg);
    final envelope = _buildEnvelope(
      topic: topicMessage,
      codecId: codecRoomMessage,
      roomId: msg.roomId,
      payload: payloadBytes,
    );
    return FrameCodec.buildProtobuf(envelope);
  }

  /// 编码 HighMessage → 完整二进制帧
  static Uint8List encodeHighMessageFrame(HighMessage msg) {
    final w = ProtoWriter()
      ..writeString(1, msg.messageId)
      ..writeString(2, msg.roomId)
      ..writeInt64(3, msg.senderId ?? 0)
      ..writeString(4, msg.senderDeviceId)
      ..writeInt64(5, msg.targetId ?? 0)
      ..writeUint32(6, _highMessageTypeCode(msg.type))
      ..writeString(7, msg.content)
      ..writeInt64(8, msg.timestamp ?? 0);

    final envelope = _buildEnvelope(
      topic: topicHighFrequency,
      codecId: codecHighMessage,
      roomId: msg.roomId ?? '',
      payload: w.toBytes(),
    );
    return FrameCodec.buildProtobuf(envelope);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 内部：MessagePayload 编解码
  // ═══════════════════════════════════════════════════════════════════════════

  /// 编码 RoomMessage 的 payload bytes（RoomMessageProtoV5）
  static Uint8List _encodeMessagePayload(RoomMessage msg) {
    final w = ProtoWriter();
    w.writeString(1, msg.messageId.isEmpty ? null : msg.messageId);
    w.writeString(2, msg.clientMsgId);
    w.writeString(3, msg.roomId);
    if (msg.senderId != 0) w.writeInt64(4, msg.senderId);
    w.writeUint32(5, MessageType.toCode(msg.messageType));
    // field 6: MessagePayloadProtoV5
    final payloadWriter = _buildMessagePayloadProto(msg);
    if (!payloadWriter.isEmpty) w.writeMessage(6, payloadWriter);
    if (msg.seq != null) w.writeInt64(7, msg.seq!);
    if (msg.serverTimestamp != null) w.writeInt64(8, msg.serverTimestamp!);
    if (msg.clientTimestamp != null) w.writeInt64(9, msg.clientTimestamp!);
    // properties
    for (final entry in msg.properties.entries) {
      final propWriter = ProtoWriter()
        ..writeString(1, entry.key)
        ..writeString(2, entry.value);
      w.writeMessage(10, propWriter);
    }
    return w.toBytes();
  }

  /// 构建 MessagePayloadProtoV5（oneof body）
  static ProtoWriter _buildMessagePayloadProto(RoomMessage msg) {
    final payload = msg.payload;
    final attachments = msg.attachments;
    final type = msg.messageType;
    final w = ProtoWriter();

    switch (type) {
      case MessageType.text:
        // TextPayloadProtoV5: content=1, markdown=2, interaction=3
        final tw = ProtoWriter()
          ..writeString(1, payload?.content)
          ..writeString(2, payload?.markdown);
        _writeInteraction(tw, 3, payload?.replyTo, payload?.mentions);
        w.writeMessage(1, tw); // oneof text = 1

      case MessageType.richText:
        // RichTextPayloadProtoV5: quill_delta=1, plain_text=2, interaction=3
        final rw = ProtoWriter()
          ..writeString(1, payload?.quillDelta)
          ..writeString(2, payload?.content);
        _writeInteraction(rw, 3, payload?.replyTo, payload?.mentions);
        w.writeMessage(2, rw); // oneof rich_text = 2

      case MessageType.image:
        // ImagePayloadProtoV5: image=1, caption=2, interaction=3
        final iw = ProtoWriter();
        if (attachments.isNotEmpty) {
          iw.writeMessage(1, _buildMediaAttachment(attachments.first));
        }
        iw.writeString(2, payload?.content);
        _writeInteraction(iw, 3, payload?.replyTo, payload?.mentions);
        w.writeMessage(3, iw); // oneof image = 3

      case MessageType.audio:
        // AudioPayloadProtoV5: audio=1, duration_ms=2, waveform=3
        final aw = ProtoWriter();
        if (attachments.isNotEmpty) {
          aw.writeMessage(1, _buildMediaAttachment(attachments.first));
        }
        if (payload?.audioDuration != null) {
          aw.writeInt32(2, payload!.audioDuration!);
        }
        w.writeMessage(4, aw); // oneof audio = 4

      case MessageType.video:
        // VideoPayloadProtoV5: video=1, cover=2, duration_ms=3, caption=4
        final vw = ProtoWriter();
        if (attachments.isNotEmpty) {
          vw.writeMessage(1, _buildMediaAttachment(attachments.first));
        }
        if (attachments.length > 1) {
          vw.writeMessage(2, _buildMediaAttachment(attachments[1]));
        }
        vw.writeString(4, payload?.content);
        w.writeMessage(5, vw); // oneof video = 5

      case MessageType.file:
        // FilePayloadProtoV5: file=1, caption=2, interaction=3
        final fw = ProtoWriter();
        if (attachments.isNotEmpty) {
          fw.writeMessage(1, _buildMediaAttachment(attachments.first));
        }
        fw.writeString(2, payload?.content);
        _writeInteraction(fw, 3, payload?.replyTo, payload?.mentions);
        w.writeMessage(6, fw); // oneof file = 6

      case MessageType.emoji:
        // EmojiPayloadProtoV5: emoji_code=1, asset=2
        final ew = ProtoWriter()
          ..writeString(1, payload?.emojiCode ?? payload?.content);
        w.writeMessage(7, ew); // oneof emoji = 7

      case MessageType.system:
        // SystemPayloadProtoV5: event_code=1, text=2, properties=3
        final sw = ProtoWriter()
          ..writeString(1, payload?.content ?? '')
          ..writeString(2, payload?.content ?? '');
        for (final entry in msg.properties.entries) {
          final propWriter = ProtoWriter()
            ..writeString(1, entry.key)
            ..writeString(2, entry.value);
          sw.writeMessage(3, propWriter);
        }
        w.writeMessage(10, sw); // oneof system = 10

      default:
        break;
    }
    return w;
  }

  /// 解码 MessagePayloadProtoV5 → (MessagePayload, List<Attachment>)
  static (MessagePayload?, List<Attachment>) _decodeMessagePayload(
    Uint8List bytes,
    MessageType type,
  ) {
    final f = ProtoReader(bytes).readAll();
    MessagePayload? payload;
    List<Attachment> attachments = const [];

    // oneof body: text=1, rich_text=2, image=3, audio=4, video=5, file=6,
    //             emoji=7, location=8, card=9, system=10

    // 按照枚举类型决定读取哪个 oneof 字段
    switch (type) {
      case MessageType.text:
        final tb = f.getBytes(1);
        if (tb.isNotEmpty) {
          final tf = ProtoReader(tb).readAll();
          final inter = _readInteraction(tf.getBytes(3));
          payload = MessagePayload(
            content: _emptyToNull(tf.getString(1)) ?? _emptyToNull(tf.getString(2)),
            markdown: _emptyToNull(tf.getString(2)),
            replyTo: inter?.replyTo,
            mentions: inter?.mentions,
          );
        }

      case MessageType.richText:
        final rb = f.getBytes(2);
        if (rb.isNotEmpty) {
          final rf = ProtoReader(rb).readAll();
          final inter = _readInteraction(rf.getBytes(3));
          payload = MessagePayload(
            content: _emptyToNull(rf.getString(2)), // plain_text
            quillDelta: _emptyToNull(rf.getString(1)), // quill_delta
            replyTo: inter?.replyTo,
            mentions: inter?.mentions,
          );
        }

      case MessageType.image:
        final ib = f.getBytes(3);
        if (ib.isNotEmpty) {
          final iif = ProtoReader(ib).readAll();
          final att = _decodeMediaAttachment(iif.getBytes(1));
          final inter = _readInteraction(iif.getBytes(3));
          payload = MessagePayload(
            content: _emptyToNull(iif.getString(2)) ?? '[图片]',
            replyTo: inter?.replyTo,
            mentions: inter?.mentions,
          );
          attachments = att != null ? [att] : const [];
        }

      case MessageType.audio:
        final ab = f.getBytes(4);
        if (ab.isNotEmpty) {
          final af = ProtoReader(ab).readAll();
          final att = _decodeMediaAttachment(af.getBytes(1));
          payload = MessagePayload(
            content: '[语音]',
            audioDuration: _zeroToNull(af.getInt32(2)),
          );
          attachments = att != null ? [att] : const [];
        }

      case MessageType.video:
        final vb = f.getBytes(5);
        if (vb.isNotEmpty) {
          final vf = ProtoReader(vb).readAll();
          final videoAtt = _decodeMediaAttachment(vf.getBytes(1));
          final coverAtt = _decodeMediaAttachment(vf.getBytes(2));
          final inter = _readInteraction(vf.getBytes(5));
          payload = MessagePayload(
            content: _emptyToNull(vf.getString(4)) ?? '[视频]',
            replyTo: inter?.replyTo,
            mentions: inter?.mentions,
          );
          final atts = <Attachment>[];
          if (videoAtt != null) atts.add(videoAtt);
          if (coverAtt != null) atts.add(coverAtt);
          attachments = atts;
        }

      case MessageType.file:
        final fb = f.getBytes(6);
        if (fb.isNotEmpty) {
          final ff = ProtoReader(fb).readAll();
          final att = _decodeMediaAttachment(ff.getBytes(1));
          final inter = _readInteraction(ff.getBytes(3));
          payload = MessagePayload(
            content: _emptyToNull(ff.getString(2)) ?? '[文件]',
            replyTo: inter?.replyTo,
            mentions: inter?.mentions,
          );
          attachments = att != null ? [att] : const [];
        }

      case MessageType.emoji:
        final eb = f.getBytes(7);
        if (eb.isNotEmpty) {
          final ef = ProtoReader(eb).readAll();
          final code = _emptyToNull(ef.getString(1));
          payload = MessagePayload(content: code ?? '', emojiCode: code);
        }

      case MessageType.location:
        final lb = f.getBytes(8);
        if (lb.isNotEmpty) {
          final lf = ProtoReader(lb).readAll();
          payload = MessagePayload(
            content: _emptyToNull(lf.getString(3)) ?? '[位置]',
          );
        }

      case MessageType.card:
        final cb = f.getBytes(9);
        if (cb.isNotEmpty) {
          final cf = ProtoReader(cb).readAll();
          payload = MessagePayload(
            content: _emptyToNull(cf.getString(3)) ?? '[卡片]',
          );
        }

      case MessageType.system:
        final sb = f.getBytes(10);
        if (sb.isNotEmpty) {
          final sf = ProtoReader(sb).readAll();
          // event_code → content（用于 system_message_service 读取 action）
          payload = MessagePayload(
            content: _emptyToNull(sf.getString(1)) ?? _emptyToNull(sf.getString(2)),
          );
        }
    }

    return (payload, attachments);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 内部：Attachment / MediaAttachment
  // ═══════════════════════════════════════════════════════════════════════════

  static ProtoWriter _buildMediaAttachment(Attachment att) {
    return ProtoWriter()
      ..writeString(1, att.id) // attachment_id
      ..writeString(3, att.url) // url
      ..writeString(4, att.name) // name
      ..writeString(5, att.type) // mime_type
      ..writeInt64(6, att.size ?? 0); // size_bytes
  }

  static Attachment? _decodeMediaAttachment(Uint8List bytes) {
    if (bytes.isEmpty) return null;
    final f = ProtoReader(bytes).readAll();
    final url = f.getString(3);
    if (url.isEmpty) return null;
    return Attachment(
      id: _emptyToNull(f.getString(1)),
      url: url,
      name: _emptyToNull(f.getString(4)),
      type: _emptyToNull(f.getString(5)),
      size: _zeroToNull(f.getInt64(6)),
      thumbnailUrl: _emptyToNull(f.getString(11)),
      width: _zeroToNull(f.getInt32(8)),
      height: _zeroToNull(f.getInt32(9)),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 内部：Interaction
  // ═══════════════════════════════════════════════════════════════════════════

  static void _writeInteraction(
    ProtoWriter w,
    int fieldNum,
    String? replyTo,
    List<int>? mentions,
  ) {
    if ((replyTo == null || replyTo.isEmpty) &&
        (mentions == null || mentions.isEmpty)) return;
    final iw = ProtoWriter()
      ..writeString(1, replyTo)
      ..writeRepeatedInt64(2, mentions ?? const []);
    w.writeMessage(fieldNum, iw);
  }

  static _Interaction? _readInteraction(Uint8List bytes) {
    if (bytes.isEmpty) return null;
    final f = ProtoReader(bytes).readAll();
    final replyTo = _emptyToNull(f.getString(1));
    final mentions = f.getRepeatedInt64(2);
    if (replyTo == null && mentions.isEmpty) return null;
    return _Interaction(replyTo, mentions.isEmpty ? null : mentions);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 内部：StringProperty
  // ═══════════════════════════════════════════════════════════════════════════

  static Map<String, String> _decodeStringProperties(List<Uint8List> propsRaw) {
    final result = <String, String>{};
    for (final bytes in propsRaw) {
      if (bytes.isEmpty) continue;
      final f = ProtoReader(bytes).readAll();
      final k = f.getString(1);
      final v = f.getString(2);
      if (k.isNotEmpty) result[k] = v;
    }
    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 内部：PacketEnvelopeV5 构建
  // ═══════════════════════════════════════════════════════════════════════════

  static Uint8List _buildEnvelope({
    required int topic,
    required int codecId,
    required String roomId,
    required Uint8List payload,
  }) {
    final w = ProtoWriter()
      ..writeUint32(1, schemaVersion) // schema_version
      ..writeUint32(2, topic) // topic
      ..writeUint32(3, codecId) // codec_id
      ..writeUint32(4, payloadVersion) // payload_version
      ..writeBytes(5, payload) // payload
      ..writeString(6, roomId); // room_id
    return w.toBytes();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 内部：枚举转换
  // ═══════════════════════════════════════════════════════════════════════════

  static PacketType _codeToTopic(int code) => switch (code) {
        topicMessage => PacketType.message,
        topicHighFrequency => PacketType.highFrequency,
        topicEvent => PacketType.event,
        topicAck => PacketType.ack,
        _ => PacketType.unknown,
      };

  static int _highMessageTypeCode(HighMessageType? type) {
    if (type == null) return 0;
    return type.code;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 工具方法
  // ═══════════════════════════════════════════════════════════════════════════

  static String? _emptyToNull(String s) => s.isEmpty ? null : s;
  static int? _zeroToNull(int v) => v == 0 ? null : v;
}

// ─── 解码结果 ─────────────────────────────────────────────────────────────────

class DecodedFrame {
  final bool isPing;
  final bool isPong;
  final PacketType? topic;
  final int codecId;
  final String roomId;
  final Uint8List? payload;

  const DecodedFrame._({
    this.isPing = false,
    this.isPong = false,
    this.topic,
    this.codecId = 0,
    this.roomId = '',
    this.payload,
  });

  factory DecodedFrame.ping() => const DecodedFrame._(isPing: true);
  factory DecodedFrame.pong() => const DecodedFrame._(isPong: true);
  factory DecodedFrame.data({
    required PacketType topic,
    required int codecId,
    required String roomId,
    required Uint8List payload,
  }) => DecodedFrame._(
    topic: topic,
    codecId: codecId,
    roomId: roomId,
    payload: payload,
  );

  bool get isData => payload != null;
  bool get isAck => codecId == ImPacketV5.codecAck;
}

// ─── ACK 模型 ─────────────────────────────────────────────────────────────────

class AckV5 {
  final String? clientMessageId;
  final int code;
  final String? message;
  final bool retryable;
  final AckMeta? meta;

  const AckV5({
    this.clientMessageId,
    required this.code,
    this.message,
    this.retryable = false,
    this.meta,
  });

  bool get isSuccess => code == 0;
}

class AckMeta {
  final String? messageId;
  final String? roomId;
  final int? seq;
  final int? timestamp;

  const AckMeta({this.messageId, this.roomId, this.seq, this.timestamp});

  bool get isEmpty => messageId == null && roomId == null && seq == null;
}

// ─── 交互元数据（内部使用）────────────────────────────────────────────────────

class _Interaction {
  final String? replyTo;
  final List<int>? mentions;

  const _Interaction(this.replyTo, this.mentions);
}
