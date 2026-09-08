import 'dart:typed_data';

import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:anoxia/framework/protocol/message/announcement_event.dart';
import 'package:anoxia/framework/protocol/message/code_payload.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/framework/protocol/message/event_message.dart';
import 'package:anoxia/framework/protocol/message/high_message.dart';
import 'package:anoxia/framework/protocol/message/room_message.dart';
import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:anoxia_protocol/anoxia_protocol.dart' as v6;

/// IM V6 协议编解码器
///
/// WebSocket 二进制负载直接使用 ClientFrame / ServerFrame 的 protobuf bytes，
/// 不附加应用层帧头。
class ImPacketV6 {
  ImPacketV6._();

  // ─── 发送：ClientFrame 构建 ─────────────────────────────────────────────

  /// 编码 RoomMessage 为 V6 ClientFrame SendMessageCommand 帧
  static Uint8List encodeRoomMessageFrame(RoomMessage msg) {
    final userPayload = _toUserMessagePayload(msg.messageType, msg.payload);
    final cmd = v6.SendMessageCommand(
      clientMessageId: msg.clientMsgId ?? msg.messageId,
      roomId: msg.roomId,
      payload: userPayload,
      clientTimestampMs: fixnum.Int64(
        msg.clientTimestamp ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
    final frame = v6.ClientFrame(
      requestId: msg.clientMsgId ?? msg.messageId,
      sendMessage: cmd,
    );
    return frame.writeToBuffer();
  }

  /// 编码已读游标
  static Uint8List encodeReadCursorFrame(
    String roomId,
    int readSeq, {
    String? requestId,
  }) {
    final cmd = v6.ReadCursorCommand(
      roomId: roomId,
      readSeq: fixnum.Int64(readSeq),
    );
    final frame = v6.ClientFrame(
      requestId: requestId ?? 'read_${DateTime.now().microsecondsSinceEpoch}',
      readCursor: cmd,
    );
    return frame.writeToBuffer();
  }

  /// 编码正在输入
  static Uint8List encodeTypingFrame(String roomId, bool isTyping) {
    final cmd = v6.TypingCommand(roomId: roomId, isTyping: isTyping);
    final frame = v6.ClientFrame(
      requestId: 'typing_${DateTime.now().microsecondsSinceEpoch}',
      typing: cmd,
    );
    return frame.writeToBuffer();
  }

  /// 编码撤回
  static Uint8List encodeRecallFrame(
    String roomId,
    String messageId, {
    String? requestId,
  }) {
    final cmd = v6.RecallMessageCommand(roomId: roomId, messageId: messageId);
    final frame = v6.ClientFrame(
      requestId: requestId ?? 'recall_${DateTime.now().microsecondsSinceEpoch}',
      recallMessage: cmd,
    );
    return frame.writeToBuffer();
  }

  /// 编码通话信令
  static Uint8List encodeCallSignalFrame({
    required String roomId,
    int? targetUserId,
    required v6.CallSignalType type,
    required String content,
  }) {
    final cmd = v6.CallSignalCommand(
      roomId: roomId,
      type: type,
      content: content,
    );
    if (targetUserId != null) {
      cmd.targetUserId = fixnum.Int64(targetUserId);
    }
    final frame = v6.ClientFrame(
      requestId: 'call_${DateTime.now().microsecondsSinceEpoch}',
      callSignal: cmd,
    );
    return frame.writeToBuffer();
  }

  // ─── 接收：ServerFrame 解码 ─────────────────────────────────────────────

  /// 尝试将 ServerFrame bytes 解码为 Dart 业务对象
  ///
  /// 返回 [DecodedV6]，由上层按类型分发；格式非法时返回 null
  static DecodedV6? decodeServerFrame(Uint8List data) {
    try {
      final frame = v6.ServerFrame.fromBuffer(data);
      final requestId = frame.hasRequestId() ? frame.requestId : null;
      final traceId = frame.hasTraceId() ? frame.traceId : null;
      if (frame.hasMessage()) {
        final rm = _fromV6RoomMessage(frame.message);
        if (rm != null) {
          return DecodedV6.message(rm, requestId: requestId, traceId: traceId);
        }
      } else if (frame.hasAck()) {
        final ack = _fromV6Ack(frame.ack);
        return DecodedV6.ack(ack, requestId: requestId, traceId: traceId);
      } else if (frame.hasEvent()) {
        final event = _fromV6RoomEvent(frame.event);
        if (event != null) {
          return DecodedV6.event(event, requestId: requestId, traceId: traceId);
        }
      } else if (frame.hasCallSignal()) {
        final sig = _fromV6CallSignal(frame.callSignal);
        if (sig != null) {
          return DecodedV6.callSignal(
            sig,
            requestId: requestId,
            traceId: traceId,
          );
        }
      } else if (frame.hasOperation()) {
        final op = _fromV6Operation(frame.operation);
        if (op != null) {
          return DecodedV6.operation(
            op,
            requestId: requestId,
            traceId: traceId,
          );
        }
      } else if (frame.hasTyping()) {
        return DecodedV6.typing(
          _fromV6Typing(frame.typing),
          requestId: requestId,
          traceId: traceId,
        );
      } else if (frame.hasSystemEvent()) {
        final system = _fromV6SystemEvent(frame.systemEvent);
        return system is HighMessage
            ? DecodedV6.systemKick(
                system,
                requestId: requestId,
                traceId: traceId,
              )
            : DecodedV6.event(
                system as EventMessage,
                requestId: requestId,
                traceId: traceId,
              );
      } else if (frame.hasAnnouncementEvent()) {
        final event = frame.announcementEvent;
        final action = switch (event.action) {
          v6.AnnouncementAction.ANNOUNCEMENT_ACTION_PUBLISHED =>
            AnnouncementAction.published,
          v6.AnnouncementAction.ANNOUNCEMENT_ACTION_UPDATED =>
            AnnouncementAction.updated,
          v6.AnnouncementAction.ANNOUNCEMENT_ACTION_OFFLINE =>
            AnnouncementAction.offline,
          _ => null,
        };
        if (action != null) {
          return DecodedV6.announcement(
            AnnouncementEvent(
              id: event.id.toInt(),
              revision: event.revision,
              action: action,
            ),
            requestId: requestId,
            traceId: traceId,
          );
        }
      } else if (frame.hasError()) {
        final err = frame.error;
        return DecodedV6.error(
          err.code,
          err.message,
          err.retryable,
          requestId: requestId,
          traceId: traceId,
        );
      }
    } catch (e, st) {
      debugLog('[ImPacketV6] decodeServerFrame failed', e, st);
    }
    return null;
  }

  // ─── 内部：UserMessagePayload 转换 ─────────────────────────────────────

  static v6.UserMessagePayload _toUserMessagePayload(
    MessageType type,
    MessagePayload? payload,
  ) {
    final p = payload;
    // 提取 interaction
    v6.Interaction? buildInteraction() {
      final replyTo = p?.replyTo;
      final mentions = p?.mentions;
      final mentionAll = p?.mentionAll == true;
      if ((replyTo == null || replyTo.isEmpty) &&
          (mentions == null || mentions.isEmpty) &&
          !mentionAll) {
        return null;
      }
      final inter = v6.Interaction();
      if (replyTo != null && replyTo.isNotEmpty) {
        inter.replyToMessageId = replyTo;
      }
      if (mentions != null && mentions.isNotEmpty) {
        inter.mentionedUserIds.addAll(mentions.map((e) => fixnum.Int64(e)));
      }
      inter.mentionAll = mentionAll;
      return inter;
    }

    v6.MediaAttachment toMedia(Attachment att) {
      final m = v6.MediaAttachment();
      if (att.id != null && att.id!.isNotEmpty) m.attachmentId = att.id!;
      m.kind = _toAttachmentKind(att.kind);
      if (att.url != null) m.url = att.url!;
      if (att.name != null) m.originalName = att.name!;
      if (att.type != null) m.mimeType = att.type!;
      if (att.size != null) m.sizeBytes = fixnum.Int64(att.size!);
      if (att.sha256 != null) m.sha256 = att.sha256!;
      if (att.width != null) m.width = att.width!;
      if (att.height != null) m.height = att.height!;
      if (att.bitrate != null) m.bitrate = att.bitrate!;
      return m;
    }

    switch (type) {
      case MessageType.text:
        final tp = v6.TextPayload()
          ..content = p?.content ?? ''
          ..format = (p?.markdown?.isNotEmpty == true)
              ? v6.TextFormat.TEXT_FORMAT_MARKDOWN
              : v6.TextFormat.TEXT_FORMAT_PLAIN;
        final inter = buildInteraction();
        if (inter != null) tp.interaction = inter;
        return v6.UserMessagePayload()..text = tp;
      case MessageType.richText:
        final rp = v6.RichTextPayload()
          ..plainText = p?.content ?? ''
          ..deltaJson = p?.quillDelta ?? '';
        final inter = buildInteraction();
        if (inter != null) rp.interaction = inter;
        return v6.UserMessagePayload()..richText = rp;
      case MessageType.image:
        final ip = v6.ImagePayload();
        if (p?.image != null) ip.image = toMedia(p!.image!);
        final imageCaption = p?.content;
        if (imageCaption != null &&
            imageCaption.isNotEmpty &&
            imageCaption != '[image]') {
          ip.caption = imageCaption;
        }
        final inter = buildInteraction();
        if (inter != null) ip.interaction = inter;
        return v6.UserMessagePayload()..image = ip;
      case MessageType.audio:
        final ap = v6.AudioPayload();
        if (p?.audio != null) ap.audio = toMedia(p!.audio!);
        ap.durationMs = p?.audioDuration ?? 0;
        if (p?.waveform != null) {
          try {
            ap.waveform = p!.waveform!.codeUnits;
          } catch (_) {}
        }
        return v6.UserMessagePayload()..audio = ap;
      case MessageType.video:
        final vp = v6.VideoPayload();
        if (p?.video != null) vp.video = toMedia(p!.video!);
        vp.durationMs = p?.audioDuration ?? 1000;
        if (p?.cover != null) vp.cover = toMedia(p!.cover!);
        final videoCaption = p?.content;
        if (videoCaption != null &&
            videoCaption.isNotEmpty &&
            videoCaption != '[video]') {
          vp.caption = videoCaption;
        }
        final inter = buildInteraction();
        if (inter != null) vp.interaction = inter;
        return v6.UserMessagePayload()..video = vp;
      case MessageType.file:
        final fp = v6.FilePayload();
        if (p?.file != null) fp.file = toMedia(p!.file!);
        final fileCaption = p?.content;
        if (fileCaption != null &&
            fileCaption.isNotEmpty &&
            fileCaption != '[file]') {
          fp.caption = fileCaption;
        }
        final inter = buildInteraction();
        if (inter != null) fp.interaction = inter;
        return v6.UserMessagePayload()..file = fp;
      case MessageType.emoji:
        final ep = v6.EmojiPayload()
          ..emojiId = p?.emojiCode ?? p?.content ?? ''
          ..textFallback = p?.content ?? '';
        if (p?.asset != null) ep.asset = toMedia(p!.asset!);
        return v6.UserMessagePayload()..emoji = ep;
      case MessageType.location:
        final lp = v6.LocationPayload();
        final loc = p?.location;
        if (loc?.latitude != null) lp.latitude = loc!.latitude!;
        if (loc?.longitude != null) lp.longitude = loc!.longitude!;
        if (loc?.title != null) lp.title = loc!.title!;
        if (loc?.address != null) lp.address = loc!.address!;
        return v6.UserMessagePayload()..location = lp;
      case MessageType.card:
        final cp = v6.CardPayload();
        final card = p?.card;
        cp.cardType = card?.cardType ?? 'unknown';
        if (card?.entityId != null) cp.entityId = card!.entityId!;
        cp.title = card?.title ?? p?.content ?? '[card]';
        if (card?.summary != null) cp.summary = card!.summary!;
        if (card?.thumbnailUrl != null) cp.thumbnailUrl = card!.thumbnailUrl!;
        if (card?.properties.isNotEmpty == true) {
          cp.metadata.addAll(card!.properties);
        }
        return v6.UserMessagePayload()..card = cp;
      case MessageType.codeSnippet:
        final code = p?.code;
        final ccp = v6.CodePayload()
          ..code = code?.code ?? p?.content ?? ''
          ..language = code?.language ?? ''
          ..title = code?.title ?? '';
        final inter = buildInteraction();
        if (inter != null) ccp.interaction = inter;
        return v6.UserMessagePayload()..code = ccp;
      case MessageType.system:
        // system 不应由客户端上行，兜底发 text
        final tp = v6.TextPayload()..content = p?.content ?? '';
        return v6.UserMessagePayload()..text = tp;
    }
  }

  static v6.AttachmentKind _toAttachmentKind(String? kind) {
    switch (kind?.toUpperCase()) {
      case 'IMAGE':
        return v6.AttachmentKind.ATTACHMENT_KIND_IMAGE;
      case 'AUDIO':
        return v6.AttachmentKind.ATTACHMENT_KIND_AUDIO;
      case 'VIDEO':
        return v6.AttachmentKind.ATTACHMENT_KIND_VIDEO;
      case 'FILE':
        return v6.AttachmentKind.ATTACHMENT_KIND_FILE;
      default:
        return v6.AttachmentKind.ATTACHMENT_KIND_UNSPECIFIED;
    }
  }

  static String _fromAttachmentKind(v6.AttachmentKind kind) {
    switch (kind) {
      case v6.AttachmentKind.ATTACHMENT_KIND_IMAGE:
        return 'IMAGE';
      case v6.AttachmentKind.ATTACHMENT_KIND_AUDIO:
        return 'AUDIO';
      case v6.AttachmentKind.ATTACHMENT_KIND_VIDEO:
        return 'VIDEO';
      case v6.AttachmentKind.ATTACHMENT_KIND_FILE:
        return 'FILE';
      default:
        return 'FILE';
    }
  }

  // ─── 内部：ServerFrame → Dart 模型 ─────────────────────────────────────

  static RoomMessage? _fromV6RoomMessage(v6.RoomMessage m) {
    try {
      final payload = _fromV6MessagePayload(m.payload);
      final type = _detectMessageType(m.payload);
      // V6 下 RoomMessage.properties 已随协议下线，系统消息的展示变量
      // （action / nickName / duration / durationText 等）由服务端写入
      // SystemPayload.arguments，解码后归入 payload.system.properties。
      // 这里转填回 properties，供 SystemMessageFormatter 与通知层统一读取，
      // 避免渲染出“-- 取消了通话”“通话已结束(无时长)”等残缺文案。
      final systemProps =
          payload?.system?.properties ?? const <String, String>{};
      return RoomMessage(
        messageId: m.messageId,
        clientMsgId: m.hasClientMessageId() ? m.clientMessageId : null,
        roomId: m.roomId,
        senderId: m.senderId.toInt(),
        messageType: type,
        payload: payload,
        properties: systemProps.isEmpty ? const {} : systemProps,
        seq: m.hasSeq() ? m.seq.toInt() : null,
        serverTimestamp: m.hasServerTimestampMs()
            ? m.serverTimestampMs.toInt()
            : null,
        clientTimestamp: m.hasClientTimestampMs()
            ? m.clientTimestampMs.toInt()
            : null,
      );
    } catch (e, st) {
      debugLog('[ImPacketV6] _fromV6RoomMessage failed', e, st);
      return null;
    }
  }

  static MessageType _detectMessageType(v6.MessagePayload p) {
    switch (p.whichBody()) {
      case v6.MessagePayload_Body.text:
        return MessageType.text;
      case v6.MessagePayload_Body.richText:
        return MessageType.richText;
      case v6.MessagePayload_Body.image:
        return MessageType.image;
      case v6.MessagePayload_Body.audio:
        return MessageType.audio;
      case v6.MessagePayload_Body.video:
        return MessageType.video;
      case v6.MessagePayload_Body.file:
        return MessageType.file;
      case v6.MessagePayload_Body.emoji:
        return MessageType.emoji;
      case v6.MessagePayload_Body.location:
        return MessageType.location;
      case v6.MessagePayload_Body.card:
        return MessageType.card;
      case v6.MessagePayload_Body.code:
        return MessageType.codeSnippet;
      case v6.MessagePayload_Body.system:
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  static MessagePayload? _fromV6MessagePayload(v6.MessagePayload p) {
    Attachment fromMedia(v6.MediaAttachment m) => Attachment(
      id: m.hasAttachmentId() ? m.attachmentId : null,
      kind: _fromAttachmentKind(m.kind),
      url: m.hasUrl() ? m.url : null,
      name: m.hasOriginalName() ? m.originalName : null,
      type: m.hasMimeType() ? m.mimeType : null,
      size: m.hasSizeBytes() ? m.sizeBytes.toInt() : null,
      sha256: m.hasSha256() ? m.sha256 : null,
      width: m.hasWidth() ? m.width : null,
      height: m.hasHeight() ? m.height : null,
      bitrate: m.hasBitrate() ? m.bitrate : null,
    );

    String? replyOf(v6.Interaction? inter) =>
        inter != null && inter.hasReplyToMessageId()
        ? inter.replyToMessageId
        : null;
    List<int>? mentionsOf(v6.Interaction? inter) =>
        inter != null && inter.mentionedUserIds.isNotEmpty
        ? inter.mentionedUserIds.map((e) => e.toInt()).toList()
        : null;
    bool? mentionAllOf(v6.Interaction? inter) =>
        inter != null && inter.hasMentionAll() ? inter.mentionAll : null;

    switch (p.whichBody()) {
      case v6.MessagePayload_Body.text:
        final t = p.text;
        return MessagePayload(
          content: t.hasContent() ? t.content : '',
          markdown: t.format == v6.TextFormat.TEXT_FORMAT_MARKDOWN
              ? t.content
              : null,
          replyTo: t.hasInteraction() ? replyOf(t.interaction) : null,
          mentions: t.hasInteraction() ? mentionsOf(t.interaction) : null,
          mentionAll: t.hasInteraction() ? mentionAllOf(t.interaction) : null,
        );
      case v6.MessagePayload_Body.richText:
        final r = p.richText;
        return MessagePayload(
          content: r.hasPlainText() ? r.plainText : '',
          quillDelta: r.hasDeltaJson() ? r.deltaJson : null,
          replyTo: r.hasInteraction() ? replyOf(r.interaction) : null,
          mentions: r.hasInteraction() ? mentionsOf(r.interaction) : null,
          mentionAll: r.hasInteraction() ? mentionAllOf(r.interaction) : null,
        );
      case v6.MessagePayload_Body.image:
        final im = p.image;
        return MessagePayload(
          content: im.hasCaption() ? im.caption : '[image]',
          image: im.hasImage() ? fromMedia(im.image) : null,
          replyTo: im.hasInteraction() ? replyOf(im.interaction) : null,
          mentions: im.hasInteraction() ? mentionsOf(im.interaction) : null,
          mentionAll: im.hasInteraction() ? mentionAllOf(im.interaction) : null,
        );
      case v6.MessagePayload_Body.audio:
        final a = p.audio;
        return MessagePayload(
          content: '[audio]',
          audio: a.hasAudio() ? fromMedia(a.audio) : null,
          audioDuration: a.hasDurationMs() ? a.durationMs : null,
          waveform: a.waveform.isNotEmpty
              ? String.fromCharCodes(a.waveform)
              : null,
        );
      case v6.MessagePayload_Body.video:
        final v = p.video;
        return MessagePayload(
          content: v.hasCaption() ? v.caption : '[video]',
          video: v.hasVideo() ? fromMedia(v.video) : null,
          cover: v.hasCover() ? fromMedia(v.cover) : null,
          audioDuration: v.hasDurationMs() ? v.durationMs : null,
          replyTo: v.hasInteraction() ? replyOf(v.interaction) : null,
          mentions: v.hasInteraction() ? mentionsOf(v.interaction) : null,
          mentionAll: v.hasInteraction() ? mentionAllOf(v.interaction) : null,
        );
      case v6.MessagePayload_Body.file:
        final f = p.file;
        return MessagePayload(
          content: f.hasCaption() ? f.caption : '[file]',
          file: f.hasFile() ? fromMedia(f.file) : null,
          replyTo: f.hasInteraction() ? replyOf(f.interaction) : null,
          mentions: f.hasInteraction() ? mentionsOf(f.interaction) : null,
          mentionAll: f.hasInteraction() ? mentionAllOf(f.interaction) : null,
        );
      case v6.MessagePayload_Body.emoji:
        final e = p.emoji;
        return MessagePayload(
          content: e.hasTextFallback() ? e.textFallback : e.emojiId,
          emojiCode: e.hasEmojiId() ? e.emojiId : null,
          asset: e.hasAsset() ? fromMedia(e.asset) : null,
        );
      case v6.MessagePayload_Body.location:
        final l = p.location;
        return MessagePayload(
          content: l.hasTitle() ? l.title : '[location]',
          location: LocationPayload(
            latitude: l.hasLatitude() ? l.latitude : null,
            longitude: l.hasLongitude() ? l.longitude : null,
            title: l.hasTitle() ? l.title : null,
            address: l.hasAddress() ? l.address : null,
          ),
        );
      case v6.MessagePayload_Body.card:
        final c = p.card;
        return MessagePayload(
          content: c.hasTitle() ? c.title : '[card]',
          card: CardPayload(
            cardType: c.hasCardType() ? c.cardType : null,
            entityId: c.hasEntityId() ? c.entityId : null,
            title: c.hasTitle() ? c.title : null,
            summary: c.hasSummary() ? c.summary : null,
            thumbnailUrl: c.hasThumbnailUrl() ? c.thumbnailUrl : null,
            properties: c.metadata.isNotEmpty
                ? Map<String, String>.from(c.metadata)
                : const {},
          ),
        );
      case v6.MessagePayload_Body.code:
        final co = p.code;
        return MessagePayload(
          content: co.hasTitle() && co.title.isNotEmpty ? co.title : co.code,
          code: CodePayload(
            code: co.hasCode() ? co.code : '',
            language: co.hasLanguage() ? co.language : null,
            title: co.hasTitle() ? co.title : null,
          ),
          replyTo: co.hasInteraction() ? replyOf(co.interaction) : null,
          mentions: co.hasInteraction() ? mentionsOf(co.interaction) : null,
          mentionAll: co.hasInteraction() ? mentionAllOf(co.interaction) : null,
        );
      case v6.MessagePayload_Body.system:
        final s = p.system;
        return MessagePayload(
          content: s.hasFallbackText() ? s.fallbackText : '',
          system: SystemPayload(
            eventCode: s.eventType.toString(),
            text: s.hasFallbackText() ? s.fallbackText : null,
            properties: s.arguments.isNotEmpty
                ? Map<String, String>.from(s.arguments)
                : const {},
          ),
        );
      default:
        return null;
    }
  }

  static AckV6 _fromV6Ack(v6.Ack a) => AckV6(
    code: a.code.value,
    message: a.hasMessage() ? a.message : null,
    retryable: a.retryable,
    meta:
        (a.hasMessageId() ||
            a.hasRoomId() ||
            a.hasSeq() ||
            a.hasServerTimestampMs())
        ? AckMetaV6(
            messageId: a.hasMessageId() ? a.messageId : null,
            roomId: a.hasRoomId() ? a.roomId : null,
            seq: a.hasSeq() ? a.seq.toInt() : null,
            timestamp: a.hasServerTimestampMs()
                ? a.serverTimestampMs.toInt()
                : null,
          )
        : null,
  );

  static EventMessage? _fromV6RoomEvent(v6.RoomEvent e) {
    final type = switch (e.type) {
      v6.RoomEventType.ROOM_EVENT_TYPE_CREATED => SystemEventType.roomCreated,
      v6.RoomEventType.ROOM_EVENT_TYPE_DISSOLVED =>
        SystemEventType.roomDissolved,
      v6.RoomEventType.ROOM_EVENT_TYPE_MEMBER_JOINED =>
        SystemEventType.userJoined,
      v6.RoomEventType.ROOM_EVENT_TYPE_MEMBER_LEFT => SystemEventType.userLeft,
      v6.RoomEventType.ROOM_EVENT_TYPE_MEMBER_KICKED =>
        SystemEventType.userKicked,
      v6.RoomEventType.ROOM_EVENT_TYPE_MUTED_CHANGED =>
        SystemEventType.roomMuted,
      v6.RoomEventType.ROOM_EVENT_TYPE_MEMBER_ROLE_CHANGED =>
        SystemEventType.userRoleChanged,
      v6.RoomEventType.ROOM_EVENT_TYPE_ANNOUNCEMENT_CHANGED =>
        SystemEventType.roomUpdated,
      _ => null,
    };
    if (type == null) return null;
    return EventMessage(
      eventType: type,
      operatorId: e.operatorUserId.toInt(),
      content: e.roomId,
      timestamp: e.serverTimestampMs.toInt(),
      extra: {
        ...e.metadata,
        'roomId': e.roomId,
        if (e.hasTargetUserId()) 'targetUserId': e.targetUserId.toInt(),
      },
    );
  }

  static HighMessage? _fromV6CallSignal(v6.CallSignal s) {
    final type = switch (s.type) {
      v6.CallSignalType.CALL_SIGNAL_TYPE_INVITE => HighMessageType.CALL_INVITE,
      v6.CallSignalType.CALL_SIGNAL_TYPE_ACCEPT => HighMessageType.CALL_ACCEPT,
      v6.CallSignalType.CALL_SIGNAL_TYPE_REJECT => HighMessageType.CALL_REJECT,
      v6.CallSignalType.CALL_SIGNAL_TYPE_CANCEL => HighMessageType.CALL_CANCEL,
      v6.CallSignalType.CALL_SIGNAL_TYPE_HANGUP => HighMessageType.CALL_END,
      v6.CallSignalType.CALL_SIGNAL_TYPE_SDP ||
      v6.CallSignalType.CALL_SIGNAL_TYPE_ICE => HighMessageType.CALL_CANDIDATE,
      v6.CallSignalType.CALL_SIGNAL_TYPE_BUSY => HighMessageType.CALL_BUSY,
      v6.CallSignalType.CALL_SIGNAL_TYPE_MEDIA_CHANGE =>
        HighMessageType.CALL_MEDIA_CHANGE,
      _ => null,
    };
    if (type == null) return null;
    return HighMessage(
      roomId: s.roomId,
      senderId: s.senderUserId.toInt(),
      targetId: s.hasTargetUserId() ? s.targetUserId.toInt() : null,
      type: type,
      content: s.content,
      timestamp: s.serverTimestampMs.toInt(),
    );
  }

  static HighMessage _fromV6Typing(v6.TypingEvent event) => HighMessage(
    roomId: event.roomId,
    senderId: event.senderUserId.toInt(),
    type: HighMessageType.TYPING_STATUS,
    content: event.isTyping.toString(),
    timestamp: event.serverTimestampMs.toInt(),
  );

  static Object _fromV6SystemEvent(v6.SystemEvent event) {
    if (event.type == v6.SystemEventType.SYSTEM_EVENT_TYPE_SESSION_KICKED) {
      return HighMessage(
        type: HighMessageType.SYSTEM_KICK,
        content: event.fallbackText,
        timestamp: event.serverTimestampMs.toInt(),
      );
    }
    return EventMessage(
      eventType: SystemEventType.fromCode(event.type.value),
      operatorId: event.hasOperatorUserId() ? event.operatorUserId.toInt() : 0,
      content: event.fallbackText,
      timestamp: event.serverTimestampMs.toInt(),
      extra: {
        ...event.metadata,
        if (event.hasTargetUserId()) 'targetUserId': event.targetUserId.toInt(),
      },
    );
  }

  static dynamic _fromV6Operation(v6.MessageOperationEvent op) {
    try {
      return {
        'roomId': op.roomId,
        'messageId': op.messageId,
        'seq': op.seq.toInt(),
        'operatorId': op.operatorUserId.toInt(),
        'type': op.type.value,
        'timestamp': op.serverTimestampMs.toInt(),
        'metadata': op.metadata,
      };
    } catch (_) {
      return null;
    }
  }
}

class DecodedV6 {
  final String type;
  final dynamic data;
  final String? requestId;
  final String? traceId;
  final int? errorCode;
  final String? errorMessage;
  final bool? retryable;

  DecodedV6._(
    this.type,
    this.data, {
    this.requestId,
    this.traceId,
    this.errorCode,
    this.errorMessage,
    this.retryable,
  });

  factory DecodedV6.message(
    RoomMessage m, {
    String? requestId,
    String? traceId,
  }) => DecodedV6._('message', m, requestId: requestId, traceId: traceId);
  factory DecodedV6.ack(AckV6 a, {String? requestId, String? traceId}) =>
      DecodedV6._('ack', a, requestId: requestId, traceId: traceId);
  factory DecodedV6.event(dynamic e, {String? requestId, String? traceId}) =>
      DecodedV6._('event', e, requestId: requestId, traceId: traceId);
  factory DecodedV6.callSignal(
    dynamic s, {
    String? requestId,
    String? traceId,
  }) => DecodedV6._('callSignal', s, requestId: requestId, traceId: traceId);
  factory DecodedV6.typing(
    HighMessage message, {
    String? requestId,
    String? traceId,
  }) => DecodedV6._('typing', message, requestId: requestId, traceId: traceId);
  factory DecodedV6.systemKick(
    HighMessage message, {
    String? requestId,
    String? traceId,
  }) => DecodedV6._(
    'systemKick',
    message,
    requestId: requestId,
    traceId: traceId,
  );
  factory DecodedV6.operation(
    dynamic o, {
    String? requestId,
    String? traceId,
  }) => DecodedV6._('operation', o, requestId: requestId, traceId: traceId);
  factory DecodedV6.announcement(
    AnnouncementEvent event, {
    String? requestId,
    String? traceId,
  }) => DecodedV6._(
    'announcement',
    event,
    requestId: requestId,
    traceId: traceId,
  );
  factory DecodedV6.error(
    String code,
    String message,
    bool retryable, {
    String? requestId,
    String? traceId,
  }) => DecodedV6._(
    'error',
    null,
    requestId: requestId,
    traceId: traceId,
    errorCode: int.tryParse(code),
    errorMessage: message,
    retryable: retryable,
  );
}

class AckV6 {
  final String? clientMessageId;
  final int code;
  final String? message;
  final bool retryable;
  final AckMetaV6? meta;
  const AckV6({
    this.clientMessageId,
    required this.code,
    this.message,
    this.retryable = false,
    this.meta,
  });
  bool get isSuccess => code == v6.AckCode.ACK_CODE_OK.value;
}

class AckMetaV6 {
  final String? messageId;
  final String? roomId;
  final int? seq;
  final int? timestamp;
  const AckMetaV6({this.messageId, this.roomId, this.seq, this.timestamp});
}
