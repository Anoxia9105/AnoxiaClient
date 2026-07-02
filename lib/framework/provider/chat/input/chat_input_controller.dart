// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/framework/codec/v5/ImPacketV5.dart';
import 'package:anoxia/framework/domain/ChatMessage.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:anoxia/framework/protocol/message/Attachment.dart';
import 'package:anoxia/framework/protocol/message/MessageEunm.dart';
import 'package:anoxia/framework/protocol/message/MessagePayload.dart';
import 'package:anoxia/framework/protocol/message/HighMessage.dart';
import 'package:anoxia/framework/protocol/message/RoomMessage.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/input/DeltaProcessor.dart';
import 'package:anoxia/framework/provider/chat/input/UploadValidator.dart';
import 'package:anoxia/framework/provider/chat/input/files/chat_file_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/input/images/chat_image_upload_controller.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../logs/talker.dart';
import '../room/room_member_service.dart';

part 'chat_input_controller.g.dart';

/// 鑱婂ぉ杈撳叆鎺у埗鍣?
///
/// 璐熻矗绠＄悊鑱婂ぉ杈撳叆妗嗙殑鐘舵€侊紝鍖呮嫭锛?
/// - 瀵屾枃鏈紪杈戯紙浣跨敤 [QuillController]锛?
/// - @鎻愬強鐢ㄦ埛鍔熻兘
/// - 鍥剧墖/鏂囦欢涓婁紶
/// - 姝ｅ湪杈撳叆鐘舵€佸彂閫?
/// - 娑堟伅鍙戦€侀€昏緫
@Riverpod(keepAlive: true)
class ChatInputController extends _$ChatInputController {
  bool _isTyping = false;
  Timer? _typingTimer;

  int _resolveSendTimeoutSeconds({
    required MessageType type,
    List<Attachment>? attachments,
  }) {
    final attachmentCount = attachments?.length ?? 0;
    var timeout = 10 + (attachmentCount * 2);

    if (type == MessageType.audio ||
        type == MessageType.file ||
        type == MessageType.video) {
      timeout += 5;
    }

    return timeout.clamp(10, 30);
  }

  @override
  QuillController build(String roomId) {
    // 鎻愬墠瀹氫箟 controller 鍙橀噺锛屼互渚垮湪闂寘涓娇鐢?
    late QuillController controller;

    controller = QuillController.basic(
      config: QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(
          enableExternalRichPaste: false, // 绂佹瀵屾枃鏈紝闃叉鏍煎紡閿欎贡
          // --- 鏍稿績淇敼锛氬鎺ョ矘璐存澘鍥剧墖 ---
          onImagePaste: (Uint8List imageBytes) async {
            log.info('妫€娴嬪埌鍥剧墖绮樿创锛屽ぇ灏? ${imageBytes.lengthInBytes} 瀛楄妭');

            // 璋冪敤 ChatImageUploadController 澶勭悊绮樿创
            // 閫昏緫锛氬瓨涓存椂鏂囦欢 -> 鎻掑叆棰勮 -> 鍚庡彴闈欓粯涓婁紶
            await ref
                .read(chatImageUploadControllerProvider.notifier)
                .handlePastedImage(controller, imageBytes);

            // 杩斿洖 null锛岃〃绀衡€滄垜宸茬粡鎵嬪姩澶勭悊浜嗘彃鍏ワ紝Quill 浣犱笉鐢ㄥ啀绠′簡鈥?
            return null;
          },

          // 澶勭悊绾枃鏈矘璐达紙渚嬪杩囨护鏁忔劅璇嶏級
          onPlainTextPaste: (String plainText) async {
            log.info('妫€娴嬪埌TEXT绮樿创$plainText');
            return plainText;
          },
        ),
      ),
    );

    // 鐩戝惉鏂囨湰鍙樺寲澶勭悊鈥滄鍦ㄨ緭鍏モ€濋€昏緫
    controller.addListener(_onTextChanged);

    ref.onDispose(() {
      _typingTimer?.cancel();
      controller.dispose();
    });

    return controller;
  }

  /// 鐩戝惉鏂囨湰鍙樺寲澶勭悊
  void _onTextChanged() {
    if (!ref.mounted) return;
    final controller = state;
    final bool hasContent = controller.document.length > 1;

    if (hasContent && !_isTyping) {
      _isTyping = true;
      _sendTypingStatus(true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (!ref.mounted) return;
      if (_isTyping) {
        _isTyping = false;
        _sendTypingStatus(false);
      }
    });

    // 寤惰繜鎵ц锛岄伩鍏嶅湪 notifyListeners 鏈熼棿淇敼 provider
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!ref.mounted) return;

      final selection = controller.selection;

      if (selection.baseOffset > 0) {
        final plainText = controller.document.toPlainText();
        final cursorPosition = selection.baseOffset;

        // 妫€鏌ュ厜鏍囧墠鐨勫瓧绗︽槸鍚︽槸 @
        if (cursorPosition <= plainText.length &&
            plainText[cursorPosition - 1] == '@') {
          ref.read(mentionStateProvider.notifier).show(cursorPosition, '');
          return;
        }

        // 濡傛灉宸茬粡鍦?@ 鐘舵€?鏇存柊鎼滅储鏂囨湰
        final mentionState = ref.read(mentionStateProvider);
        if (mentionState.isShowing) {
          // 妫€鏌ュ厜鏍囨槸鍚﹀洖閫€鍒癅绗﹀彿涔嬪墠锛堢敤鎴峰垹闄や簡@鎴栭€€鏍煎埌@涔嬪墠锛?
          if (cursorPosition < mentionState.cursorPosition) {
            ref.read(mentionStateProvider.notifier).hide();
            return;
          }

          // 妫€鏌绗﹀彿浣嶇疆鏄惁杩樻槸@绗﹀彿
          if (mentionState.cursorPosition > 0 &&
              mentionState.cursorPosition - 1 < plainText.length &&
              plainText[mentionState.cursorPosition - 1] != '@') {
            // @绗﹀彿琚垹闄や簡
            ref.read(mentionStateProvider.notifier).hide();
            return;
          }

          // 鎻愬彇 @ 鍚庣殑鏂囨湰
          final textAfterAt = plainText.substring(
            mentionState.cursorPosition,
            cursorPosition.clamp(mentionState.cursorPosition, plainText.length),
          );

          // 濡傛灉閬囧埌绌烘牸鎴栨崲琛?鍏抽棴寮圭獥
          if (textAfterAt.contains(' ') || textAfterAt.contains('\n')) {
            ref.read(mentionStateProvider.notifier).hide();
          } else {
            ref.read(mentionStateProvider.notifier).updateSearch(textAfterAt);
          }
        }
      } else {
        // 鍏夋爣鍦ㄥ紑澶达紝濡傛灉寮圭獥姝ｅ湪鏄剧ず鍒欏叧闂?
        final mentionState = ref.read(mentionStateProvider);
        if (mentionState.isShowing) {
          ref.read(mentionStateProvider.notifier).hide();
        }
      }
    });
  }

  /// 鍙戦€佹鍦ㄨ緭鍏ョ姸鎬?
  void _sendTypingStatus(bool isTyping) {
    if (!ref.mounted) return;
    final room = ref.read(currentRoomProvider(roomId));
    //鎴块棿鎴栬€呮帴鏀惰€呮槸绌虹殑涓嶅彂閫? 锛堢兢鑱婁笉鍙戯級
    if (room == null || room.peerId == null) return;

    //鐢ㄦ埛鍦ㄧ嚎鍙戦€?TYPING_STATUS 涓嶅湪绾夸笉鍙戦€?
    final roomMembers = ref.read(roomMembersProvider(room.roomId!));

    // 4.1 鎴愬憳鍒楄〃涓虹┖锛堟湭鍚屾锛夛紝涓嶅彂閫?
    if (roomMembers.isEmpty) {
      log.debug('room ${room.roomId} members not synced, skip typing');
      return;
    }

    // 鏍规嵁peerId鏌ユ壘瀵规柟鎴愬憳
    final matchedMembers = roomMembers
        .where((member) => member.userId == room.peerId)
        .toList();
    final peerMember = matchedMembers.isEmpty ? null : matchedMembers.first;

    if (peerMember == null) return;

    // 鎵句笉鍒板鏂规垚鍛?鎴?瀵规柟绂荤嚎锛屼笉鍙戦€?
    if (peerMember.onlineStatus != true) {
      log.debug('${peerMember.nickName} offline, skip typing: $isTyping');
      return;
    }

    final highMsg = HighMessage(
      type: HighMessageType.TYPING_STATUS,
      roomId: room.roomId,
      targetId: room.peerId,
      content: isTyping.toString(),
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    final bytes = ImPacketV5.encodeHighMessageFrame(highMsg);
    ref.read(wsControllerProvider.notifier).sendMessage(bytes);
  }

  /// 鍙戦€佹秷鎭?
  void sendMessage() {
    final room = ref.read(currentRoomProvider(roomId));
    if (room == null || state.document.isEmpty()) return;

    final uploadState = {
      ...ref.read(chatImageUploadControllerProvider.notifier).urlMap,
      ...ref.read(chatFileUploadControllerProvider.notifier).urlMap,
    };
    final processor = DeltaProcessor(state.document.toDelta(), uploadState);
    final mentionIds = processor.mentionedUserIds;
    // 鎷︽埅锛氭鍦ㄤ笂浼犱腑
    final imageState = ref.read(chatImageUploadControllerProvider);
    final fileState = ref.read(chatFileUploadControllerProvider);
    final allEntries = [...imageState.values, ...fileState.values];

    if (allEntries.any((e) => e.isUploading)) return;
    if (allEntries.any((e) => e.isFailed)) return;

    // 鎷︽埅锛氭鏌ユ槸鍚︽湁澶辫触/鏈笂浼犵殑鏂囦欢
    if (!processor.isAllUploaded) {
      return;
    }
    // --- 绛栫暐锛氭媶鍒嗗彂閫?---
    if (processor.images.isNotEmpty) {
      _doSend(
        type: MessageType.image,
        payload: MessagePayload(content: '[鍥剧墖]'),
        attachments: processor.images,
      );
    }
    // 鍙戦€佹枃浠?
    if (processor.files.isNotEmpty) {
      _doSend(
        type: MessageType.file,
        payload: MessagePayload(content: '[鏂囦欢]'),
        attachments: processor.files,
      );
    }
    // 鍙戦€佹枃瀛?Emoji (鍖呭惈瀵屾枃鏈牱寮?
    if (processor.plainText.isNotEmpty ||
        processor.mentionedUserIds.isNotEmpty) {
      final cleanDelta = processor.filteredDelta;
      // 鍐嶆妫€鏌ユ竻鐞嗗悗鐨?Delta 鏄惁鏈夋晥锛堥伩鍏嶅彧鍙戜簡涓€涓崲琛岀锛?
      if (cleanDelta.length == 0 ||
          (cleanDelta.length == 1 &&
              cleanDelta.first.data == '\n' &&
              processor.mentionedUserIds.isEmpty)) {
        // 濡傛灉娓呯悊瀹屽浘鐗囧悗鍙墿绌烘崲琛岋紝涓旀病鏈?@锛屽垯涓嶅彂閫?
        return;
      }

      if (processor.isSingleEmoji) {
        _doSend(
          type: MessageType.text,
          payload: MessagePayload(
            content: processor.plainText, // emoji鍐呭
            emojiCode: processor.plainText.characters.first,
          ),
        );
      } else {
        final isRich = processor.hasAttributes || mentionIds.isNotEmpty;
        _doSend(
          type: isRich ? MessageType.richText : MessageType.text,
          payload: isRich
              ? MessagePayload(
                  content: processor.plainText.characters.take(100).toString(),
                  quillDelta: jsonEncode(cleanDelta.toJson()),
                  mentions: mentionIds,
                )
              : MessagePayload(content: processor.plainText),
        );
      }
    }
    // 4. 娓呯┖杈撳叆
    clearInput();
    if (DeviceUtil.isRealDesktop()) {
      ref.read(chatFocusNodeProvider(room.roomId!)).requestFocus();
    }
  }

  /// Android 鏅€氳緭鍏ユ鍙戦€佺函鏂囨湰锛堝彲甯?@mention锛?
  void sendPlainTextMessage(String text, {List<int>? mentionIds}) {
    final room = ref.read(currentRoomProvider(roomId));
    final content = text.trim();
    if (room == null || content.isEmpty) return;

    final isSingleEmoji =
        content.characters.length == 1 && _isEmoji(content.characters.first);

    _doSend(
      type: MessageType.text,
      payload: MessagePayload(
        content: content,
        mentions: (mentionIds != null && mentionIds.isNotEmpty)
            ? mentionIds
            : null,
        emojiCode: isSingleEmoji ? content.characters.first : null,
      ),
    );
  }

  Future<void> sendPickedImages(List<PlatformFile> files) async {
    if (files.isEmpty) return;

    final List<Attachment> uploadList = [];
    for (final file in files.where((f) => f.path != null)) {
      if (!UploadValidator.validateSingleFile(file)) continue;
      final imageSize = await _readImageSizeFromFile(file.path!);
      uploadList.add(
        Attachment(
          id: const Uuid().v4(),
          kind: 'IMAGE',
          url: file.path!,
          name: _basenameWithoutExtension(file.name),
          size: file.size,
          type: _imageMimeType(file.extension),
          width: imageSize.$1,
          height: imageSize.$2,
        ),
      );
    }
    if (uploadList.isEmpty) return;

    final uploader = ref.read(chatImageUploadControllerProvider.notifier);
    await uploader.uploadImages(uploadList);

    final urlMap = uploader.urlMap;
    final uploaded = uploadList
        .where((item) => urlMap[item.id] != null)
        .map((item) => item.copyWith(url: urlMap[item.id]))
        .toList();

    if (uploaded.isEmpty) return;

    _doSend(
      type: MessageType.image,
      payload: MessagePayload(content: '[鍥剧墖]'),
      attachments: uploaded,
    );
  }

  Future<void> sendPickedFiles(List<PlatformFile> files) async {
    if (files.isEmpty) return;

    final List<Attachment> uploadList = [];
    for (final file in files.where((f) => f.path != null)) {
      if (!UploadValidator.validateSingleFile(file)) continue;
      uploadList.add(
        Attachment(
          id: const Uuid().v4(),
          kind: 'FILE',
          url: file.path!,
          name: _basenameWithoutExtension(file.name),
          size: file.size,
          type: file.extension ?? 'bin',
        ),
      );
    }
    if (uploadList.isEmpty) return;

    final uploader = ref.read(chatFileUploadControllerProvider.notifier);
    await uploader.uploadFiles(uploadList);

    final urlMap = uploader.urlMap;
    final uploaded = uploadList
        .where((item) => urlMap[item.id] != null)
        .map((item) => item.copyWith(url: urlMap[item.id]))
        .toList();

    if (uploaded.isEmpty) return;

    _doSend(
      type: MessageType.file,
      payload: MessagePayload(content: '[鏂囦欢]'),
      attachments: uploaded,
    );
  }

  /// 渚?Android 鏅€氳緭鍏ユ澶嶇敤鈥滄鍦ㄨ緭鍏モ€濈姸鎬?
  void handlePlainTextChanged(String text) {
    final hasContent = text.trim().isNotEmpty;

    if (hasContent && !_isTyping) {
      _isTyping = true;
      _sendTypingStatus(true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (!ref.mounted) return;
      if (_isTyping) {
        _isTyping = false;
        _sendTypingStatus(false);
      }
    });

    if (!hasContent && _isTyping) {
      _isTyping = false;
      _sendTypingStatus(false);
    }
  }

  /// 鍙戦€佽闊虫秷鎭?
  Future<void> sendVoiceMessage({
    required String filePath,
    required int duration,
  }) async {
    final room = ref.read(currentRoomProvider(roomId));
    if (room == null) return;

    final clientMsgId = const Uuid().v4();
    final file = File(filePath);

    // 1. 绔嬪嵆鎻掑叆鏈湴鍗犱綅娑堟伅锛堢姸鎬?sending锛寀rl 鐢ㄦ湰鍦拌矾寰勶級
    final localMsg = ChatMessage(
      messageId: clientMsgId,
      clientMsgId: clientMsgId,
      roomId: roomId,
      senderId: ref.read(authControllerProvider).value?.userId,
      messageType: MessageType.audio,
      content: '[璇煶]',
      payload: MessagePayload(content: '[璇煶]', audioDuration: duration),
      attachments: [
        Attachment(
          id: clientMsgId,
          kind: 'AUDIO',
          url: filePath, // 鍏堢敤鏈湴璺緞锛屾覆鏌撴椂鍙互鐩存帴鎾斁鏈湴鏂囦欢
          name: 'voice_message',
          size: file.lengthSync(),
          type: 'audio/m4a',
        ),
      ],
      timestamp: DateTime.now().millisecondsSinceEpoch,
      deliveryStatus: DeliveryStatus.sending,
      seq: 0,
    );

    ref.read(chatMessagesProvider.notifier).upsertMessage(localMsg);

    try {
      // 2. 鍚庡彴涓婁紶
      final res = await DioClient().uploadFiles(
        '/file/uploadBatch',
        files: [file],
      );

      final rawList = res.data is Map ? res.data['data'] : res.data;
      if (rawList is! List || rawList.isEmpty) {
        // 涓婁紶澶辫触锛屾洿鏂颁负 failed 鐘舵€?
        ref
            .read(chatMessagesProvider.notifier)
            .upsertMessage(
              localMsg.copyWith(deliveryStatus: DeliveryStatus.failed),
            );
        log.warning('voice upload failed: empty response');
        return;
      }

      final url = rawList.first.toString();

      // 3. 涓婁紶鎴愬姛锛岄€氳繃 WS 鍙戦€佺湡姝ｇ殑娑堟伅
      _doSendVoice(
        clientMsgId: clientMsgId,
        url: url,
        duration: duration,
        fileSize: file.lengthSync(),
      );

      // 4. 鍒犻櫎鏈湴涓存椂鏂囦欢
      try {
        file.deleteSync();
      } catch (_) {}
    } catch (e) {
      ref
          .read(chatMessagesProvider.notifier)
          .upsertMessage(
            localMsg.copyWith(deliveryStatus: DeliveryStatus.failed),
          );
      log.error('璇煶娑堟伅鍙戦€佸け璐? $e');
    }
  }

  void _doSendVoice({
    required String clientMsgId,
    required String url,
    required int duration,
    required int fileSize,
  }) {
    final room = ref.read(currentRoomProvider(roomId));
    final user = ref.read(authControllerProvider).value;
    if (room == null || user == null) return;

    final attachments = [
      Attachment(
        id: clientMsgId,
        kind: 'AUDIO',
        url: url,
        name: 'voice_message',
        size: fileSize,
        type: 'audio/m4a',
      ),
    ];
    final payload = MessagePayload(
      content: '[audio]',
      audioDuration: duration,
    ).withMedia(MessageType.audio, attachments);

    // 鏇存柊鏈湴娑堟伅鐨?url 涓虹湡瀹?url
    final updatedMsg = ChatMessage(
      messageId: clientMsgId,
      clientMsgId: clientMsgId,
      roomId: roomId,
      senderId: user.userId,
      messageType: MessageType.audio,
      content: '[璇煶]',
      payload: payload,
      attachments: attachments,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      deliveryStatus: DeliveryStatus.sending,
      seq: 0,
    );
    ref.read(chatMessagesProvider.notifier).upsertMessage(updatedMsg);

    final protoMsg = RoomMessage(
      messageId: '',
      clientMsgId: clientMsgId,
      roomId: roomId,
      senderId: user.userId,
      messageType: MessageType.audio,
      payload: payload,
      clientTimestamp: DateTime.now().millisecondsSinceEpoch,
    );

    log.info('馃殌 鍙戦€佽闊虫秷鎭? $clientMsgId');
    ref
        .read(wsControllerProvider.notifier)
        .sendMessage(ImPacketV5.encodeRoomMessageFrame(protoMsg));

    final timeoutSeconds = _resolveSendTimeoutSeconds(
      type: MessageType.audio,
      attachments: attachments,
    );
    Timer(Duration(seconds: timeoutSeconds), () {
      ref
          .read(chatMessagesProvider.notifier)
          .handleTimeout(roomId, clientMsgId);
    });
  }

  bool _isEmoji(String char) {
    final codePoint = char.runes.first;
    return (codePoint >= 0x1F300 && codePoint <= 0x1FAFF) ||
        (codePoint >= 0x2600 && codePoint <= 0x27BF);
  }

  String _basenameWithoutExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0) return fileName;
    return fileName.substring(0, dot);
  }

  Future<(int?, int?)> _readImageSizeFromFile(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final size = (image.width, image.height);
      image.dispose();
      codec.dispose();
      return size;
    } catch (_) {
      return (null, null);
    }
  }

  String _imageMimeType(String? extension) {
    final ext = extension?.toLowerCase();
    if (ext == null || ext.isEmpty) return 'image/jpeg';
    if (ext == 'jpg') return 'image/jpeg';
    return 'image/$ext';
  }

  void clearInput() {
    state.clear();
    _isTyping = false;
    ref.read(mentionStateProvider.notifier).hide();
  }

  // 缁熶竴鐨勫唴閮ㄥ彂閫佹柟娉?
  void _doSend({
    required MessageType type,
    required MessagePayload payload,
    List<Attachment>? attachments,
  }) {
    final String clientMsgId = const Uuid().v4();
    final user = ref.read(authControllerProvider).value;
    if (user == null) {
      log.error('鍙戦€佸け璐? 鐢ㄦ埛淇℃伅缂哄け');
      return;
    }
    final payloadWithMedia = payload.withMedia(type, attachments ?? const []);
    final derivedAttachments = payloadWithMedia.mediaAttachments;

    final localMsg = ChatMessage(
      messageId: clientMsgId,
      clientMsgId: clientMsgId,
      roomId: roomId,
      senderId: user.userId,
      messageType: type,
      content: payloadWithMedia.content ?? '',
      payload: payloadWithMedia,
      attachments: derivedAttachments,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      deliveryStatus: DeliveryStatus.sending,
      seq: 0,
    );

    ref.read(chatMessagesProvider.notifier).upsertMessage(localMsg);

    final protoMsg = RoomMessage(
      messageId: '',
      clientMsgId: clientMsgId,
      roomId: roomId,
      senderId: user.userId,
      messageType: type,
      payload: payloadWithMedia,
      clientTimestamp: DateTime.now().millisecondsSinceEpoch,
    );

    log.info('馃殌 鍙戦€佹秷鎭?[$type]: clientMsgId=$clientMsgId');
    ref
        .read(wsControllerProvider.notifier)
        .sendMessage(ImPacketV5.encodeRoomMessageFrame(protoMsg));
    final timeoutSeconds = _resolveSendTimeoutSeconds(
      type: type,
      attachments: derivedAttachments,
    );
    Timer(Duration(seconds: timeoutSeconds), () {
      ref
          .read(chatMessagesProvider.notifier)
          .handleTimeout(roomId, clientMsgId);
    });
  }
}

/// 鑱婂ぉ杈撳叆妗嗙劍鐐?Provider
///
/// 涓烘瘡涓埧闂寸嫭绔嬬鐞嗚緭鍏ユ鐒︾偣鐘舵€?
@riverpod
FocusNode chatFocusNode(Ref ref, String roomId) {
  final node = FocusNode();
  ref.onDispose(() => node.dispose());
  return node;
}

// 鍦?chat_input_controller.dart 涓坊鍔?
@Riverpod(keepAlive: true)
class MentionState extends _$MentionState {
  @override
  MentionStateData build() => MentionStateData();

  void show(int cursorPosition, String searchText, {Offset? atSymbolOffset}) {
    state = state.copyWith(
      isShowing: true,
      cursorPosition: cursorPosition,
      searchText: searchText,
      atSymbolOffset: atSymbolOffset,
    );
  }

  void hide() {
    state = state.copyWith(isShowing: false);
  }

  void updateSearch(String text) {
    state = state.copyWith(searchText: text);
  }
}

/// @鎻愬強鐘舵€佹暟鎹?
///
/// 瀛樺偍鎻愬強寮圭獥鐨勬樉绀虹姸鎬佸拰鐩稿叧淇℃伅
class MentionStateData {
  final bool isShowing;
  final int cursorPosition;
  final String searchText;
  final Offset? atSymbolOffset; // @ 绗﹀彿鍦ㄥ睆骞曚笂鐨勪綅缃?

  MentionStateData({
    this.isShowing = false,
    this.cursorPosition = 0,
    this.searchText = '',
    this.atSymbolOffset,
  });

  MentionStateData copyWith({
    bool? isShowing,
    int? cursorPosition,
    String? searchText,
    Offset? atSymbolOffset,
  }) {
    return MentionStateData(
      isShowing: isShowing ?? this.isShowing,
      cursorPosition: cursorPosition ?? this.cursorPosition,
      searchText: searchText ?? this.searchText,
      atSymbolOffset: atSymbolOffset ?? this.atSymbolOffset,
    );
  }
}
