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

/// IM V5 鍗忚鍏ㄩ噺缂栬В鐮佸櫒
///
/// 璐熻矗 V5 Protobuf 娑堟伅鐨勭紪鐮侊紙Dart 鈫?浜岃繘鍒跺抚锛夊拰瑙ｇ爜锛堜簩杩涘埗甯?鈫?Dart锛夈€?
/// 鎵€鏈夋柟娉曞潎涓洪潤鎬佹柟娉曪紝鏃犻渶瀹炰緥鍖栥€?
class ImPacketV5 {
  ImPacketV5._();

  // 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺?
  // 鍏叡甯搁噺锛堜笌鏈嶅姟绔?CodecConstants 瀵归綈锛?
  // 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺?

  static const int schemaVersion = 5;
  static const int payloadVersion = 1;

  /// Topic 鏁板瓧鐮?
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

  // 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺?
  // 甯?鈫?瑙ｇ爜缁撴灉
  // 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺?

  /// 瑙ｆ瀽瀹屾暣鐨勫簲鐢ㄥ眰甯э紝杩斿洖 [DecodedFrame]锛涙牸寮忛潪娉曟椂杩斿洖 null
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

  /// 瑙ｆ瀽 Protobuf Envelope锛岃繑鍥?[DecodedFrame]
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

  // 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺?
  // 娑堟伅瑙ｇ爜锛坧ayload bytes 鈫?Dart 妯″瀷锛?
  // 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺?

  /// 瑙ｇ爜 RoomMessage
  static RoomMessage? decodeRoomMessage(Uint8List bytes) {
    try {
      final f = ProtoReader(bytes).readAll();
      final messageType = MessageType.fromCode(f.getUint32(5));
      final payloadBytes = f.getBytes(6); // MessagePayloadProtoV5

      MessagePayload? payload;

      if (payloadBytes.isNotEmpty) {
        payload = _decodeMessagePayload(payloadBytes, messageType);
      }

      // properties: repeated StringPropertyProtoV5 = field 10
      final propsRaw = f.getRepeatedBytes(10);
      final properties = _decodeStringProperties(propsRaw);

      // 绯荤粺娑堟伅锛氬皢 system payload 鐨?eventCode 娉ㄥ叆 properties['action']
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
        properties: properties,
        seq: _zeroToNull(f.getInt64(7)),
        serverTimestamp: _zeroToNull(f.getInt64(8)),
        clientTimestamp: _zeroToNull(f.getInt64(9)),
      );
    } catch (_) {
      return null;
    }
  }

  /// 瑙ｇ爜 HighMessage
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

  /// 瑙ｇ爜 EventMessage
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

  /// 瑙ｇ爜 AckV5
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

  // 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺?
  // 娑堟伅缂栫爜锛圖art 妯″瀷 鈫?瀹屾暣浜岃繘鍒跺抚锛?
  // 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺?

  /// 缂栫爜 RoomMessage 鈫?瀹屾暣浜岃繘鍒跺抚
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

  /// 缂栫爜 HighMessage 鈫?瀹屾暣浜岃繘鍒跺抚
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

  // 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺?
  // 鍐呴儴锛歁essagePayload 缂栬В鐮?
  // 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺?

  /// 缂栫爜 RoomMessage 鐨?payload bytes锛圧oomMessageProtoV5锛?
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

  /// 鏋勫缓 MessagePayloadProtoV5锛坥neof body锛?
  static ProtoWriter _buildMessagePayloadProto(RoomMessage msg) {
    final payload = msg.payload;
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
        if (payload?.image != null) {
          iw.writeMessage(1, _buildMediaAttachment(payload!.image!));
        }
        iw.writeString(2, payload?.content);
        _writeInteraction(iw, 3, payload?.replyTo, payload?.mentions);
        w.writeMessage(3, iw); // oneof image = 3

      case MessageType.audio:
        // AudioPayloadProtoV5: audio=1, duration_ms=2, waveform=3
        final aw = ProtoWriter();
        if (payload?.audio != null) {
          aw.writeMessage(1, _buildMediaAttachment(payload!.audio!));
        }
        if (payload?.audioDuration != null) {
          aw.writeInt32(2, payload!.audioDuration!);
        }
        aw.writeString(3, payload?.waveform);
        w.writeMessage(4, aw); // oneof audio = 4

      case MessageType.video:
        // VideoPayloadProtoV5: video=1, cover=2, duration_ms=3, caption=4
        final vw = ProtoWriter();
        if (payload?.video != null) {
          vw.writeMessage(1, _buildMediaAttachment(payload!.video!));
        }
        if (payload?.cover != null) {
          vw.writeMessage(2, _buildMediaAttachment(payload!.cover!));
        }
        if (payload?.audioDuration != null) {
          vw.writeInt32(3, payload!.audioDuration!);
        }
        vw.writeString(4, payload?.content);
        w.writeMessage(5, vw); // oneof video = 5

      case MessageType.file:
        // FilePayloadProtoV5: file=1, caption=2, interaction=3
        final fw = ProtoWriter();
        if (payload?.file != null) {
          fw.writeMessage(1, _buildMediaAttachment(payload!.file!));
        }
        fw.writeString(2, payload?.content);
        _writeInteraction(fw, 3, payload?.replyTo, payload?.mentions);
        w.writeMessage(6, fw); // oneof file = 6

      case MessageType.emoji:
        // EmojiPayloadProtoV5: emoji_code=1, asset=2
        final ew = ProtoWriter()
          ..writeString(1, payload?.emojiCode ?? payload?.content);
        if (payload?.asset != null) {
          ew.writeMessage(2, _buildMediaAttachment(payload!.asset!));
        }
        w.writeMessage(7, ew); // oneof emoji = 7

      case MessageType.location:
        // LocationPayloadProtoV5: latitude=1, longitude=2, title=3, address=4
        final location = payload?.location;
        final lw = ProtoWriter()
          ..writeDouble(1, location?.latitude)
          ..writeDouble(2, location?.longitude)
          ..writeString(3, location?.title ?? payload?.content)
          ..writeString(4, location?.address);
        w.writeMessage(8, lw); // oneof location = 8

      case MessageType.card:
        // CardPayloadProtoV5: card_type=1, entity_id=2, title=3,
        // summary=4, thumbnail_url=5, properties=6
        final card = payload?.card;
        final fallbackTitle = card?.title ?? payload?.content ?? '[card]';
        final cw = ProtoWriter()
          ..writeString(1, card?.cardType)
          ..writeString(2, card?.entityId)
          ..writeString(3, fallbackTitle)
          ..writeString(4, card?.summary)
          ..writeString(5, card?.thumbnailUrl);
        for (final entry
            in card?.properties.entries ?? const <MapEntry<String, String>>[]) {
          final propWriter = ProtoWriter()
            ..writeString(1, entry.key)
            ..writeString(2, entry.value);
          cw.writeMessage(6, propWriter);
        }
        w.writeMessage(9, cw); // oneof card = 9

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
    }
    return w;
  }

  // Decode MessagePayloadProtoV5 into the local MessagePayload model.
  static MessagePayload? _decodeMessagePayload(
    Uint8List bytes,
    MessageType type,
  ) {
    final f = ProtoReader(bytes).readAll();
    MessagePayload? payload;

    switch (type) {
      case MessageType.text:
        final tb = f.getBytes(1);
        if (tb.isNotEmpty) {
          final tf = ProtoReader(tb).readAll();
          final inter = _readInteraction(tf.getBytes(3));
          payload = MessagePayload(
            content:
                _emptyToNull(tf.getString(1)) ?? _emptyToNull(tf.getString(2)),
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
            content: _emptyToNull(rf.getString(2)),
            quillDelta: _emptyToNull(rf.getString(1)),
            replyTo: inter?.replyTo,
            mentions: inter?.mentions,
          );
        }

      case MessageType.image:
        final ib = f.getBytes(3);
        if (ib.isNotEmpty) {
          final image = ProtoReader(ib).readAll();
          final inter = _readInteraction(image.getBytes(3));
          final att = _decodeMediaAttachment(image.getBytes(1));
          payload = MessagePayload(
            content: _emptyToNull(image.getString(2)) ?? '[image]',
            image: att?.copyWith(kind: 'IMAGE'),
            replyTo: inter?.replyTo,
            mentions: inter?.mentions,
          );
        }

      case MessageType.audio:
        final ab = f.getBytes(4);
        if (ab.isNotEmpty) {
          final audio = ProtoReader(ab).readAll();
          final att = _decodeMediaAttachment(audio.getBytes(1));
          payload = MessagePayload(
            content: '[audio]',
            audioDuration: _zeroToNull(audio.getInt32(2)),
            audio: att?.copyWith(kind: 'AUDIO'),
            waveform: _emptyToNull(audio.getString(3)),
          );
        }

      case MessageType.video:
        final vb = f.getBytes(5);
        if (vb.isNotEmpty) {
          final video = ProtoReader(vb).readAll();
          final videoAtt = _decodeMediaAttachment(video.getBytes(1));
          final coverAtt = _decodeMediaAttachment(video.getBytes(2));
          final inter = _readInteraction(video.getBytes(5));
          payload = MessagePayload(
            content: _emptyToNull(video.getString(4)) ?? '[video]',
            replyTo: inter?.replyTo,
            mentions: inter?.mentions,
            audioDuration: _zeroToNull(video.getInt32(3)),
            video: videoAtt?.copyWith(kind: 'VIDEO'),
            cover: coverAtt?.copyWith(kind: 'IMAGE'),
          );
        }

      case MessageType.file:
        final fb = f.getBytes(6);
        if (fb.isNotEmpty) {
          final file = ProtoReader(fb).readAll();
          final inter = _readInteraction(file.getBytes(3));
          final att = _decodeMediaAttachment(file.getBytes(1));
          payload = MessagePayload(
            content: _emptyToNull(file.getString(2)) ?? '[file]',
            file: att?.copyWith(kind: 'FILE'),
            replyTo: inter?.replyTo,
            mentions: inter?.mentions,
          );
        }

      case MessageType.emoji:
        final eb = f.getBytes(7);
        if (eb.isNotEmpty) {
          final emoji = ProtoReader(eb).readAll();
          final code = _emptyToNull(emoji.getString(1));
          final asset = _decodeMediaAttachment(emoji.getBytes(2));
          payload = MessagePayload(
            content: code ?? '',
            emojiCode: code,
            asset: asset?.copyWith(kind: 'FILE'),
          );
        }

      case MessageType.location:
        final lb = f.getBytes(8);
        if (lb.isNotEmpty) {
          final lf = ProtoReader(lb).readAll();
          final location = LocationPayload(
            latitude: lf.containsKey(1) ? lf.getDouble(1) : null,
            longitude: lf.containsKey(2) ? lf.getDouble(2) : null,
            title: _emptyToNull(lf.getString(3)),
            address: _emptyToNull(lf.getString(4)),
          );
          payload = MessagePayload(
            content: location.displayTitle.isNotEmpty
                ? location.displayTitle
                : '[location]',
            location: location,
          );
        }

      case MessageType.card:
        final cb = f.getBytes(9);
        if (cb.isNotEmpty) {
          final cf = ProtoReader(cb).readAll();
          final card = CardPayload(
            cardType: _emptyToNull(cf.getString(1)),
            entityId: _emptyToNull(cf.getString(2)),
            title: _emptyToNull(cf.getString(3)),
            summary: _emptyToNull(cf.getString(4)),
            thumbnailUrl: _emptyToNull(cf.getString(5)),
            properties: _decodeStringProperties(cf.getRepeatedBytes(6)),
          );
          payload = MessagePayload(
            content: card.displayTitle.isNotEmpty
                ? card.displayTitle
                : '[card]',
            card: card,
          );
        }

      case MessageType.system:
        final sb = f.getBytes(10);
        if (sb.isNotEmpty) {
          final sf = ProtoReader(sb).readAll();
          payload = MessagePayload(
            content:
                _emptyToNull(sf.getString(1)) ?? _emptyToNull(sf.getString(2)),
          );
        }
    }

    return payload;
  }

  static ProtoWriter _buildMediaAttachment(Attachment att) {
    final w = ProtoWriter()
      ..writeString(1, att.id) // attachment_id
      ..writeUint32(2, _mediaKindCode(att.kind)) // kind
      ..writeString(3, att.url) // url
      ..writeString(4, att.name) // name
      ..writeString(5, att.type) // mime_type
      ..writeInt64(6, att.size ?? 0) // size_bytes
      ..writeString(7, att.sha256)
      ..writeInt32(8, att.width ?? 0)
      ..writeInt32(9, att.height ?? 0)
      ..writeInt32(10, att.bitrate ?? 0)
      ..writeString(11, att.thumbnailUrl);
    for (final entry in att.properties.entries) {
      final propWriter = ProtoWriter()
        ..writeString(1, entry.key)
        ..writeString(2, entry.value);
      w.writeMessage(12, propWriter);
    }
    return w;
  }

  static Attachment? _decodeMediaAttachment(Uint8List bytes) {
    if (bytes.isEmpty) return null;
    final f = ProtoReader(bytes).readAll();
    final url = f.getString(3);
    if (url.isEmpty) return null;
    return Attachment(
      id: _emptyToNull(f.getString(1)),
      kind: _decodeMediaKind(f.getUint32(2)),
      url: url,
      name: _emptyToNull(f.getString(4)),
      type: _emptyToNull(f.getString(5)),
      size: _zeroToNull(f.getInt64(6)),
      sha256: _emptyToNull(f.getString(7)),
      thumbnailUrl: _emptyToNull(f.getString(11)),
      width: _zeroToNull(f.getInt32(8)),
      height: _zeroToNull(f.getInt32(9)),
      bitrate: _zeroToNull(f.getInt32(10)),
      properties: _decodeStringProperties(f.getRepeatedBytes(12)),
    );
  }

  // 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺?
  // 鍐呴儴锛欼nteraction
  // 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺?

  static void _writeInteraction(
    ProtoWriter w,
    int fieldNum,
    String? replyTo,
    List<int>? mentions,
  ) {
    if ((replyTo == null || replyTo.isEmpty) &&
        (mentions == null || mentions.isEmpty)) {
      return;
    }
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

  // 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺?
  // 鍐呴儴锛歋tringProperty
  // 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺?

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

  // 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺?
  // 鍐呴儴锛歅acketEnvelopeV5 鏋勫缓
  // 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺?

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

  // 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺?
  // 鍐呴儴锛氭灇涓捐浆鎹?
  // 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺?

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

  static int _mediaKindCode(String? kind) {
    switch (kind?.toUpperCase()) {
      case 'IMAGE':
        return 1;
      case 'AUDIO':
        return 2;
      case 'VIDEO':
        return 3;
      case 'FILE':
        return 4;
      default:
        return 0;
    }
  }

  static String? _decodeMediaKind(int code) => switch (code) {
    1 => 'IMAGE',
    2 => 'AUDIO',
    3 => 'VIDEO',
    4 => 'FILE',
    _ => null,
  };

  // 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺?
  // 宸ュ叿鏂规硶
  // 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺?

  static String? _emptyToNull(String s) => s.isEmpty ? null : s;
  static int? _zeroToNull(int v) => v == 0 ? null : v;
}

// 鈹€鈹€鈹€ 瑙ｇ爜缁撴灉 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

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

// 鈹€鈹€鈹€ ACK 妯″瀷 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

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

// 鈹€鈹€鈹€ 浜や簰鍏冩暟鎹紙鍐呴儴浣跨敤锛夆攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€

class _Interaction {
  final String? replyTo;
  final List<int>? mentions;

  const _Interaction(this.replyTo, this.mentions);
}
