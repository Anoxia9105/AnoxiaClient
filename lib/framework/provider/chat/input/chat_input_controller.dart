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

/// 閼卞﹤銇夋潏鎾冲弳閹貉冨煑閸?
///
/// 鐠愮喕鐭楃粻锛勬倞閼卞﹤銇夋潏鎾冲弳濡楀棛娈戦悩鑸碘偓渚婄礉閸栧懏瀚敍?
/// - 鐎靛本鏋冮張顒傜椽鏉堟埊绱欐担璺ㄦ暏 [QuillController]閿?
/// - @閹绘劕寮烽悽銊﹀煕閸旂喕鍏?
/// - 閸ュ墽澧?閺傚洣娆㈡稉濠佺炊
/// - 濮濓絽婀潏鎾冲弳閻樿埖鈧礁褰傞柅?
/// - 濞戝牊浼呴崣鎴︹偓渚€鈧槒绶?
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
    // 閹绘劕澧犵€规矮绠?controller 閸欐﹢鍣洪敍灞间簰娓氬灝婀梻顓炲瘶娑擃厺濞囬悽?
    late QuillController controller;

    controller = QuillController.basic(
      config: QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(
          enableExternalRichPaste: false, // 缁備焦顒涚€靛本鏋冮張顒婄礉闂冨弶顒涢弽鐓庣础闁挎瑤璐?
          // --- 閺嶇绺炬穱顔芥暭閿涙艾顕幒銉х煒鐠愬瓨婢橀崶鍓у ---
          onImagePaste: (Uint8List imageBytes) async {
            log.info('pasted image bytes: ${imageBytes.lengthInBytes}');

            // 鐠嬪啰鏁?ChatImageUploadController 婢跺嫮鎮婄划妯垮垱
            // 闁槒绶敍姘摠娑撳瓨妞傞弬鍥︽ -> 閹绘帒鍙嗘０鍕潔 -> 閸氬骸褰撮棃娆撶帛娑撳﹣绱?
            await ref
                .read(chatImageUploadControllerProvider.notifier)
                .handlePastedImage(controller, imageBytes);

            // 鏉╂柨娲?null閿涘矁銆冪粈琛♀偓婊勫灉瀹歌尙绮￠幍瀣З婢跺嫮鎮婃禍鍡樺絻閸忋儻绱漄uill 娴ｇ姳绗夐悽銊ュ晙缁犫€茬啊閳?
            return null;
          },

          // 婢跺嫮鎮婄痪顖涙瀮閺堫剛鐭樼拹杈剧礄娓氬顩ф潻鍥ㄦ姢閺佸繑鍔呯拠宥忕礆
          onPlainTextPaste: (String plainText) async {
            log.info('濡偓濞村鍩孴EXT缁鍒?plainText');
            return plainText;
          },
        ),
      ),
    );

    // 閻╂垵鎯夐弬鍥ㄦ拱閸欐ê瀵叉径鍕倞閳ユ粍顒滈崷銊ㄧ翻閸忋儮鈧繈鈧槒绶?
    controller.addListener(_onTextChanged);

    ref.onDispose(() {
      _typingTimer?.cancel();
      controller.dispose();
    });

    return controller;
  }

  /// 閻╂垵鎯夐弬鍥ㄦ拱閸欐ê瀵叉径鍕倞
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

    // 瀵ゆ儼绻滈幍褑顢戦敍宀勪缉閸忓秴婀?notifyListeners 閺堢喖妫挎穱顔芥暭 provider
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!ref.mounted) return;

      final selection = controller.selection;

      if (selection.baseOffset > 0) {
        final plainText = controller.document.toPlainText();
        final cursorPosition = selection.baseOffset;

        // 濡偓閺屻儱鍘滈弽鍥у閻ㄥ嫬鐡х粭锔芥Ц閸氾附妲?@
        if (cursorPosition <= plainText.length &&
            plainText[cursorPosition - 1] == '@') {
          ref.read(mentionStateProvider.notifier).show(cursorPosition, '');
          return;
        }

        // 婵″倹鐏夊鑼病閸?@ 閻樿埖鈧?閺囧瓨鏌婇幖婊呭偍閺傚洦婀?
        final mentionState = ref.read(mentionStateProvider);
        if (mentionState.isShowing) {
          // 濡偓閺屻儱鍘滈弽鍥ㄦЦ閸氾箑娲栭柅鈧崚鐧呯粭锕€褰挎稊瀣閿涘牏鏁ら幋宄板灩闂勩倓绨閹存牠鈧偓閺嶇厧鍩孈娑斿澧犻敍?
          if (cursorPosition < mentionState.cursorPosition) {
            ref.read(mentionStateProvider.notifier).hide();
            return;
          }

          // 濡偓閺岊檰缁楋箑褰挎担宥囩枂閺勵垰鎯佹潻妯绘Ц@缁楋箑褰?
          if (mentionState.cursorPosition > 0 &&
              mentionState.cursorPosition - 1 < plainText.length &&
              plainText[mentionState.cursorPosition - 1] != '@') {
            // @缁楋箑褰跨悮顐㈠灩闂勩倓绨?
            ref.read(mentionStateProvider.notifier).hide();
            return;
          }

          // 閹绘劕褰?@ 閸氬海娈戦弬鍥ㄦ拱
          final textAfterAt = plainText.substring(
            mentionState.cursorPosition,
            cursorPosition.clamp(mentionState.cursorPosition, plainText.length),
          );

          // 婵″倹鐏夐柆鍥у煂缁岀儤鐗搁幋鏍ㄥ床鐞?閸忔娊妫村鍦崶
          if (textAfterAt.contains(' ') || textAfterAt.contains('\n')) {
            ref.read(mentionStateProvider.notifier).hide();
          } else {
            ref.read(mentionStateProvider.notifier).updateSearch(textAfterAt);
          }
        }
      } else {
        // 閸忓鐖ｉ崷銊ョ磻婢惰揪绱濇俊鍌涚亯瀵湱鐛ュ锝呮躬閺勫墽銇氶崚娆忓彠闂?
        final mentionState = ref.read(mentionStateProvider);
        if (mentionState.isShowing) {
          ref.read(mentionStateProvider.notifier).hide();
        }
      }
    });
  }

  /// 閸欐垿鈧焦顒滈崷銊ㄧ翻閸忋儳濮搁幀?
  void _sendTypingStatus(bool isTyping) {
    if (!ref.mounted) return;
    final room = ref.read(currentRoomProvider(roomId));
    //閹村潡妫块幋鏍偓鍛复閺€鎯扳偓鍛Ц缁岃櫣娈戞稉宥呭絺闁? 閿涘牏鍏㈤懕濠佺瑝閸欐埊绱?
    if (room == null || room.peerId == null) return;

    //閻劍鍩涢崷銊у殠閸欐垿鈧?TYPING_STATUS 娑撳秴婀痪澶哥瑝閸欐垿鈧?
    final roomMembers = ref.read(roomMembersProvider(room.roomId!));

    // 4.1 閹存劕鎲抽崚妤勩€冩稉铏光敄閿涘牊婀崥灞绢劄閿涘绱濇稉宥呭絺闁?
    if (roomMembers.isEmpty) {
      log.debug('room ${room.roomId} members not synced, skip typing');
      return;
    }

    // 閺嶈宓乸eerId閺屻儲澹樼€佃鏌熼幋鎰喅
    final matchedMembers = roomMembers
        .where((member) => member.userId == room.peerId)
        .toList();
    final peerMember = matchedMembers.isEmpty ? null : matchedMembers.first;

    if (peerMember == null) return;

    // 閹靛彞绗夐崚鏉款嚠閺傝鍨氶崨?閹?鐎佃鏌熺粋鑽ゅ殠閿涘奔绗夐崣鎴︹偓?
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

  /// 閸欐垿鈧焦绉烽幁?
  void sendMessage() {
    final room = ref.read(currentRoomProvider(roomId));
    if (room == null || state.document.isEmpty()) return;

    final uploadState = {
      ...ref.read(chatImageUploadControllerProvider.notifier).urlMap,
      ...ref.read(chatFileUploadControllerProvider.notifier).urlMap,
    };
    final processor = DeltaProcessor(state.document.toDelta(), uploadState);
    final mentionIds = processor.mentionedUserIds;
    // 閹凤附鍩呴敍姘劀閸︺劋绗傛导鐘辫厬
    final imageState = ref.read(chatImageUploadControllerProvider);
    final fileState = ref.read(chatFileUploadControllerProvider);
    final allEntries = [...imageState.values, ...fileState.values];

    if (allEntries.any((e) => e.isUploading)) return;
    if (allEntries.any((e) => e.isFailed)) return;

    // 閹凤附鍩呴敍姘梾閺屻儲妲搁崥锔芥箒婢惰精瑙?閺堫亙绗傛导鐘垫畱閺傚洣娆?
    if (!processor.isAllUploaded) {
      return;
    }
    // --- 缁涙牜鏆愰敍姘閸掑棗褰傞柅?---
    if (processor.images.isNotEmpty) {
      _doSend(
        type: MessageType.image,
        payload: MessagePayload(content: '[閸ュ墽澧朷'),
        attachments: processor.images,
      );
    }
    // 閸欐垿鈧焦鏋冩禒?
    if (processor.files.isNotEmpty) {
      _doSend(
        type: MessageType.file,
        payload: MessagePayload(content: '[閺傚洣娆'),
        attachments: processor.files,
      );
    }
    // 閸欐垿鈧焦鏋冪€?Emoji (閸栧懎鎯堢€靛本鏋冮張顒佺壉瀵?
    if (processor.plainText.isNotEmpty ||
        processor.mentionedUserIds.isNotEmpty) {
      final cleanDelta = processor.filteredDelta;
      // 閸愬秵顐煎Λ鈧弻銉︾閻炲棗鎮楅惃?Delta 閺勵垰鎯侀張澶嬫櫏閿涘牓浼╅崗宥呭涧閸欐垳绨℃稉鈧稉顏呭床鐞涘瞼顑侀敍?
      if (cleanDelta.length == 0 ||
          (cleanDelta.length == 1 &&
              cleanDelta.first.data == '\n' &&
              processor.mentionedUserIds.isEmpty)) {
        // 婵″倹鐏夊〒鍛倞鐎瑰苯娴橀悧鍥ф倵閸欘亜澧跨粚鐑樺床鐞涘矉绱濇稉鏃€鐥呴張?@閿涘苯鍨稉宥呭絺闁?
        return;
      }

      if (processor.isSingleEmoji) {
        _doSend(
          type: MessageType.text,
          payload: MessagePayload(
            content: processor.plainText, // emoji閸愬懎顔?
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
    // 4. 濞撳懐鈹栨潏鎾冲弳
    clearInput();
    if (DeviceUtil.isRealDesktop()) {
      ref.read(chatFocusNodeProvider(room.roomId!)).requestFocus();
    }
  }

  /// Android 閺咁噣鈧俺绶崗銉︻攱閸欐垿鈧胶鍑介弬鍥ㄦ拱閿涘牆褰茬敮?@mention閿?
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
      payload: MessagePayload(content: '[閸ュ墽澧朷'),
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
      payload: MessagePayload(content: '[閺傚洣娆'),
      attachments: uploaded,
    );
  }

  /// 娓?Android 閺咁噣鈧俺绶崗銉︻攱婢跺秶鏁ら垾婊勵劀閸︺劏绶崗銉⑩偓婵堝Ц閹?
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

  /// 閸欐垿鈧浇顕㈤棅铏Х閹?
  Future<void> sendVoiceMessage({
    required String filePath,
    required int duration,
  }) async {
    final room = ref.read(currentRoomProvider(roomId));
    if (room == null) return;

    final clientMsgId = const Uuid().v4();
    final file = File(filePath);
    final localAudioAttachments = [
      Attachment(
        id: clientMsgId,
        kind: 'AUDIO',
        url: filePath,
        name: 'voice_message',
        size: file.lengthSync(),
        type: 'audio/m4a',
      ),
    ];
    final localPayload = MessagePayload(
      content: '[audio]',
      audioDuration: duration,
    ).withMedia(MessageType.audio, localAudioAttachments);

    // 1. 缁斿宓嗛幓鎺戝弳閺堫剙婀撮崡鐘辩秴濞戝牊浼呴敍鍫㈠Ц閹?sending閿涘瘈rl 閻劍婀伴崷鎷岀熅瀵板嫸绱?
    final localMsg = ChatMessage(
      messageId: clientMsgId,
      clientMsgId: clientMsgId,
      roomId: roomId,
      senderId: ref.read(authControllerProvider).value?.userId,
      messageType: MessageType.audio,
      content: localPayload.content ?? '',
      payload: localPayload,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      deliveryStatus: DeliveryStatus.sending,
      seq: 0,
    );

    ref.read(chatMessagesProvider.notifier).upsertMessage(localMsg);

    try {
      // 2. 閸氬骸褰存稉濠佺炊
      final res = await DioClient().uploadFiles(
        '/file/uploadBatch',
        files: [file],
      );

      final rawList = res.data is Map ? res.data['data'] : res.data;
      if (rawList is! List || rawList.isEmpty) {
        // 娑撳﹣绱舵径杈Е閿涘本娲块弬棰佽礋 failed 閻樿埖鈧?
        ref
            .read(chatMessagesProvider.notifier)
            .upsertMessage(
              localMsg.copyWith(deliveryStatus: DeliveryStatus.failed),
            );
        log.warning('voice upload failed: empty response');
        return;
      }

      final url = rawList.first.toString();

      // 3. 娑撳﹣绱堕幋鎰閿涘矂鈧俺绻?WS 閸欐垿鈧胶婀″锝囨畱濞戝牊浼?
      _doSendVoice(
        clientMsgId: clientMsgId,
        url: url,
        duration: duration,
        fileSize: file.lengthSync(),
      );

      // 4. 閸掔娀娅庨張顒€婀存稉瀛樻閺傚洣娆?
      try {
        file.deleteSync();
      } catch (_) {}
    } catch (e) {
      ref
          .read(chatMessagesProvider.notifier)
          .upsertMessage(
            localMsg.copyWith(deliveryStatus: DeliveryStatus.failed),
          );
      log.error('鐠囶參鐓跺☉鍫熶紖閸欐垿鈧礁銇戠拹? $e');
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

    // 閺囧瓨鏌婇張顒€婀村☉鍫熶紖閻?url 娑撹櫣婀＄€?url
    final updatedMsg = ChatMessage(
      messageId: clientMsgId,
      clientMsgId: clientMsgId,
      roomId: roomId,
      senderId: user.userId,
      messageType: MessageType.audio,
      content: '[鐠囶參鐓禲',
      payload: payload,
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

    log.info('棣冩畬 閸欐垿鈧浇顕㈤棅铏Х閹? $clientMsgId');
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

  // 缂佺喍绔撮惃鍕敶闁劌褰傞柅浣规煙濞?
  void _doSend({
    required MessageType type,
    required MessagePayload payload,
    List<Attachment>? attachments,
  }) {
    final String clientMsgId = const Uuid().v4();
    final user = ref.read(authControllerProvider).value;
    if (user == null) {
      log.error('send failed: missing user');
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

    log.info('棣冩畬 閸欐垿鈧焦绉烽幁?[$type]: clientMsgId=$clientMsgId');
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

/// 閼卞﹤銇夋潏鎾冲弳濡楀棛鍔嶉悙?Provider
///
/// 娑撶儤鐦℃稉顏呭煣闂傚瀚粩瀣吀閻炲棜绶崗銉︻攱閻掞妇鍋ｉ悩鑸碘偓?
@riverpod
FocusNode chatFocusNode(Ref ref, String roomId) {
  final node = FocusNode();
  ref.onDispose(() => node.dispose());
  return node;
}

// 閸?chat_input_controller.dart 娑擃厽鍧婇崝?
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

/// @閹绘劕寮烽悩鑸碘偓浣规殶閹?
///
/// 鐎涙ê鍋嶉幓鎰挤瀵湱鐛ラ惃鍕▔缁€铏瑰Ц閹礁鎷伴惄绋垮彠娣団剝浼?
class MentionStateData {
  final bool isShowing;
  final int cursorPosition;
  final String searchText;
  final Offset? atSymbolOffset; // @ 缁楋箑褰块崷銊ョ潌楠炴洑绗傞惃鍕秴缂?

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
