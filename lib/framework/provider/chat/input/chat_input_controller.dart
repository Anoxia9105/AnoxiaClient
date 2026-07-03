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
import 'package:anoxia/framework/provider/chat/input/reply_target_provider.dart';
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

/// 闁煎崬锕ら妵澶嬫綇閹惧啿寮抽柟璨夊啫鐓戦柛?
///
/// 閻犳劗鍠曢惌妤冪不閿涘嫭鍊為柤鍗烇工閵囧娼忛幘鍐插汲婵℃妫涘▓鎴︽偐閼哥鍋撴笟濠勭闁告牕鎳忕€氼參鏁?
/// - 閻庨潧鏈弸鍐嫉椤掑倻妞介弶鍫熷煀缁辨瑦鎷呯捄銊︽殢 [QuillController]闁?
/// - @闁圭粯鍔曞鐑芥偨閵婏箑鐓曢柛鏃傚枙閸?
/// - 闁搞儱澧芥晶?闁哄倸娲ｅ▎銏＄▔婵犱胶鐐?
/// - 婵繐绲藉﹢顏呮綇閹惧啿寮抽柣妯垮煐閳ь兛绀佽ぐ鍌炴焻?
/// - 婵炴垵鐗婃导鍛村矗閹达腹鍋撴笟鈧埀顒佹缁?
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
    // 闁圭粯鍔曟晶鐘碘偓瑙勭煯缁?controller 闁告瑦锕㈤崳娲晬鐏為棿绨板〒姘仢濠€顏堟⒒椤撶偛鐦跺☉鎿冨幒婵炲洭鎮?
    late QuillController controller;

    controller = QuillController.basic(
      config: QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(
          enableExternalRichPaste:
              false, // 缂佸倷鐒﹂娑氣偓闈涙湰閺嬪啴寮甸濠勭闂傚啫寮堕娑㈠冀閻撳海纭€闂佹寧鐟ょ拹?
          // --- 闁哄秶顭堢缓鐐┍椤旇姤鏆柨娑欒壘椤曨噣骞掗妷褏鐓掗悹鎰摠濠㈡﹢宕堕崜褍顣?---
          onImagePaste: (Uint8List imageBytes) async {
            log.info('pasted image bytes: ${imageBytes.lengthInBytes}');

            // 閻犲鍟伴弫?ChatImageUploadController 濠㈣泛瀚幃濠勫垝濡灝鍨?
            // 闂侇偅妲掔欢顐︽晬濮橆剛鎽犲☉鎾崇摠濡炲倿寮崶锔筋偨 -> 闁圭粯甯掗崣鍡橈紣閸曨噮娼?-> 闁告艾楠歌ぐ鎾濞嗘挾甯涘☉鎾筹梗缁?
            await ref
                .read(chatImageUploadControllerProvider.notifier)
                .handlePastedImage(controller, imageBytes);

            // 閺夆晜鏌ㄥú?null闁挎稑鐭侀妴鍐矆鐞涒檧鍋撳鍕亯鐎规瓕灏欑划锟犲箥鐎ｎ亜袟濠㈣泛瀚幃濠冪閸℃ê绲婚柛蹇嬪劵缁辨紕uill 濞达絿濮崇粭澶愭偨閵娿儱鏅欑紒鐘偓鑼晩闁?
            return null;
          },

          // 濠㈣泛瀚幃濠勭棯椤栨稒鐎柡鍫墰閻鎷规潏鍓х濞撴艾顑呴々褎娼婚崶銊﹀Б闁轰礁绻戦崝鍛嫚瀹ュ繒绀?
          onPlainTextPaste: (String plainText) async {
            log.info('婵☆偀鍋撴繛鏉戭儏閸╁EXT缂侇喗顭堥崚?plainText');
            return plainText;
          },
        ),
      ),
    );

    // 闁烩晜鍨甸幆澶愬棘閸ャ劍鎷遍柛娆惷€靛弶寰勯崟顓熷€為柍銉︾矋椤掓粓宕烽妸銊х炕闁稿繈鍎埀顒佺箞閳ь剚妲掔欢?
    controller.addListener(_onTextChanged);

    ref.onDispose(() {
      _typingTimer?.cancel();
      controller.dispose();
    });

    return controller;
  }

  /// 闁烩晜鍨甸幆澶愬棘閸ャ劍鎷遍柛娆惷€靛弶寰勯崟顓熷€?
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

    // 鐎点倖鍎肩换婊堝箥瑜戦、鎴︽晬瀹€鍕級闁稿繐绉村﹢?notifyListeners 闁哄牏鍠栧Λ鎸庣┍椤旇姤鏆?provider
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!ref.mounted) return;

      final selection = controller.selection;

      if (selection.baseOffset > 0) {
        final plainText = controller.document.toPlainText();
        final cursorPosition = selection.baseOffset;

        // 婵☆偀鍋撻柡灞诲劚閸樻粓寮介崶褍顤呴柣銊ュ閻⊙呯箔閿旇姤笑闁告熬闄勫Σ?@
        if (cursorPosition <= plainText.length &&
            plainText[cursorPosition - 1] == '@') {
          ref.read(mentionStateProvider.notifier).show(cursorPosition, '');
          return;
        }

        // 濠碘€冲€归悘澶婎啅閼碱剛鐥呴柛?@ 闁绘鍩栭埀?闁哄洤鐡ㄩ弻濠囧箹濠婂懎鍋嶉柡鍌氭处濠€?
        final mentionState = ref.read(mentionStateProvider);
        if (mentionState.isShowing) {
          // 婵☆偀鍋撻柡灞诲劚閸樻粓寮介崶銊π﹂柛姘剧畱濞叉牠鏌呴埀顒勫礆閻у懐绮敃鈧ぐ鎸庣▕鐎ｎ亜顤呴柨娑樼墢閺併倝骞嬪畡鏉跨仼闂傚嫨鍊撶花顡嗛柟瀛樼墵閳ь兘鍋撻柡宥囧帶閸╁瓐濞戞柨顑呮晶鐘绘晬?
          if (cursorPosition < mentionState.cursorPosition) {
            ref.read(mentionStateProvider.notifier).hide();
            return;
          }

          // 婵☆偀鍋撻柡宀婃缂佹绠戣ぐ鎸庢媴瀹ュ洨鏋傞柡鍕靛灠閹焦娼诲Ο缁樞缂佹绠戣ぐ?
          if (mentionState.cursorPosition > 0 &&
              mentionState.cursorPosition - 1 < plainText.length &&
              plainText[mentionState.cursorPosition - 1] != '@') {
            // @缂佹绠戣ぐ璺ㄦ偖椤愩垹鐏╅梻鍕╁€撶花?
            ref.read(mentionStateProvider.notifier).hide();
            return;
          }

          // 闁圭粯鍔曡ぐ?@ 闁告艾娴峰▓鎴﹀棘閸ャ劍鎷?
          final textAfterAt = plainText.substring(
            mentionState.cursorPosition,
            cursorPosition.clamp(mentionState.cursorPosition, plainText.length),
          );

          // 濠碘€冲€归悘澶愭焼閸パ冪厒缂佸瞼鍎ら悧鎼佸箣閺嶃劌搴婇悶?闁稿繑濞婂Λ鏉戭嚕閸︻厾宕?
          if (textAfterAt.contains(' ') || textAfterAt.contains('\n')) {
            ref.read(mentionStateProvider.notifier).hide();
          } else {
            ref.read(mentionStateProvider.notifier).updateSearch(textAfterAt);
          }
        }
      } else {
        // 闁稿繐顦伴悥锝夊捶閵娿儳纾诲鎯版彧缁辨繃淇婇崒娑氫函鐎殿喖婀遍悰銉ヮ潰閿濆懏韬柡鍕⒔閵囨岸宕氬▎蹇撳綘闂?
        final mentionState = ref.read(mentionStateProvider);
        if (mentionState.isShowing) {
          ref.read(mentionStateProvider.notifier).hide();
        }
      }
    });
  }

  /// 闁告瑦鍨块埀顑跨劍椤掓粓宕烽妸銊х炕闁稿繈鍎虫慨鎼佸箑?
  void _sendTypingStatus(bool isTyping) {
    if (!ref.mounted) return;
    final room = ref.read(currentRoomProvider(roomId));
    //闁规潙娼″Λ鍧楀箣閺嶎兘鍋撻崨顔煎闁衡偓閹壋鍋撻崨顔叫︾紒宀冩濞堟垶绋夊鍛岛闂? 闁挎稑鐗忛崗銏ゆ嚂婵犱胶鐟濋柛娆愬煀缁?
    if (room == null || room.peerId == null) return;

    //闁活潿鍔嶉崺娑㈠捶閵娧冩疇闁告瑦鍨块埀?TYPING_STATUS 濞戞挸绉村﹢顏嗙棯婢跺摜鐟濋柛娆愬灴閳?
    final roomMembers = ref.read(roomMembersProvider(room.roomId!));

    // 4.1 闁瑰瓨鍔曢幉鎶藉礆濡ゅ嫨鈧啯绋夐搹鍏夋晞闁挎稑鐗婂﹢顓㈠触鐏炵虎鍔勯柨娑橆檧缁辨繃绋夊鍛岛闂?
    if (roomMembers.isEmpty) {
      log.debug('room ${room.roomId} members not synced, skip typing');
      return;
    }

    // 闁哄秷顫夊畵涔竐erId闁哄被鍎叉竟妯尖偓浣冾潐閺岀喖骞嬮幇顒佸枀
    final matchedMembers = roomMembers
        .where((member) => member.userId == room.peerId)
        .toList();
    final peerMember = matchedMembers.isEmpty ? null : matchedMembers.first;

    if (peerMember == null) return;

    // 闁归潧褰炵粭澶愬礆閺夋鍤犻柡鍌濐潐閸ㄦ岸宕?闁?閻庝絻顫夐弻鐔虹矉閼姐倕娈犻柨娑樺缁楀宕ｉ幋锔瑰亾?
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

  /// 闁告瑦鍨块埀顑跨劍缁夌兘骞?
  void sendMessage() {
    final room = ref.read(currentRoomProvider(roomId));
    if (room == null || state.document.isEmpty()) return;

    final uploadState = {
      ...ref.read(chatImageUploadControllerProvider.notifier).urlMap,
      ...ref.read(chatFileUploadControllerProvider.notifier).urlMap,
    };
    final processor = DeltaProcessor(state.document.toDelta(), uploadState);
    final mentionIds = processor.mentionedUserIds;
    // 闁瑰嚖闄勯崺鍛存晬濮橆収鍔€闁革负鍔嬬粭鍌涘閻樿精鍘?
    final imageState = ref.read(chatImageUploadControllerProvider);
    final fileState = ref.read(chatFileUploadControllerProvider);
    final allEntries = [...imageState.values, ...fileState.values];

    if (allEntries.any((e) => e.isUploading)) return;
    if (allEntries.any((e) => e.isFailed)) return;

    // 闁瑰嚖闄勯崺鍛存晬濮橆収姊鹃柡灞诲劜濡叉悂宕ラ敂鑺ョ畳濠㈡儼绮剧憴?闁哄牜浜欑粭鍌涘閻樺灚鐣遍柡鍌氭矗濞?
    if (!processor.isAllUploaded) {
      return;
    }
    // --- 缂佹稒鐗滈弳鎰版晬濮橆厼顎曢柛鎺戞瑜板倿鏌?---
    if (processor.images.isNotEmpty) {
      for (final image in processor.images) {
        _doSend(
          type: MessageType.image,
          payload: const MessagePayload(content: '[image]'),
          attachments: [image],
          clearReplyAfterSend: false,
        );
      }
    }
    // 闁告瑦鍨块埀顑跨劍閺嬪啯绂?
    if (processor.files.isNotEmpty) {
      _doSend(
        type: MessageType.file,
        payload: const MessagePayload(content: '[file]'),
        attachments: processor.files,
        clearReplyAfterSend: false,
      );
    }
    // 闁告瑦鍨块埀顑跨劍閺嬪啰鈧?Emoji (闁告牕鎳庨幆鍫⑩偓闈涙湰閺嬪啴寮甸浣哄鐎?
    if (processor.plainText.isNotEmpty ||
        processor.mentionedUserIds.isNotEmpty) {
      final cleanDelta = processor.filteredDelta;
      // 闁告劕绉甸鐓幬涢埀顒勫蓟閵夛妇顏搁柣鐐叉閹鎯?Delta 闁哄嫷鍨伴幆渚€寮垫径瀣珡闁挎稑鐗撴导鈺呭礂瀹ュ懎娑ч柛娆愬灣缁ㄢ剝绋夐埀顒佺▔椤忓懎搴婇悶娑樼灱椤戜線鏁?
      if (cleanDelta.length == 0 ||
          (cleanDelta.length == 1 &&
              cleanDelta.first.data == '\n' &&
              processor.mentionedUserIds.isEmpty)) {
        // 濠碘€冲€归悘澶娿€掗崨顖涘€為悗鐟拌嫰濞存﹢鎮ч崶褎鍊甸柛娆樹簻婢ц法绮氶悜妯哄簥閻炴稑鐭夌槐婵囩▔閺冣偓閻ュ懘寮?@闁挎稑鑻崹顖涚▔瀹ュ懎绲洪梺?
        return;
      }

      if (processor.isSingleEmoji) {
        final emoji = processor.plainText.characters.first;
        _doSend(
          type: MessageType.emoji,
          payload: MessagePayload(content: emoji, emojiCode: emoji),
          clearReplyAfterSend: false,
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
          clearReplyAfterSend: false,
        );
      }
    }
    // 4. 婵炴挸鎳愰埞鏍ㄦ綇閹惧啿寮?
    clearInput();
    if (DeviceUtil.isRealDesktop()) {
      ref.read(chatFocusNodeProvider(room.roomId!)).requestFocus();
    }
  }

  /// Android 闁哄拋鍣ｉ埀顒佷亢缁额參宕楅妷锔绘敱闁告瑦鍨块埀顑胯兌閸戜粙寮崶銊︽嫳闁挎稑鐗嗚ぐ鑼暜?@mention闁?
  void sendPlainTextMessage(String text, {List<int>? mentionIds}) {
    final room = ref.read(currentRoomProvider(roomId));
    final content = text.trim();
    if (room == null || content.isEmpty) return;

    final isSingleEmoji =
        content.characters.length == 1 && _isEmoji(content.characters.first);

    _doSend(
      type: isSingleEmoji ? MessageType.emoji : MessageType.text,
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

    for (var i = 0; i < uploaded.length; i++) {
      _doSend(
        type: MessageType.image,
        payload: const MessagePayload(content: '[image]'),
        attachments: [uploaded[i]],
        clearReplyAfterSend: i == uploaded.length - 1,
      );
    }
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
      payload: const MessagePayload(content: '[file]'),
      attachments: uploaded,
    );
  }

  /// 濞?Android 闁哄拋鍣ｉ埀顒佷亢缁额參宕楅妷锔绘敱濠㈣泛绉堕弫銈夊灳濠婂嫷鍔€闁革负鍔忕欢顓㈠礂閵夆懇鍋撳┑鍫澬﹂柟?
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

  /// 闁告瑦鍨块埀顑挎祰椤曘垽妫呴搹顐ばラ柟?
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

    // 1. 缂佹柨顑呭畵鍡涘箵閹烘垵寮抽柡鍫墮濠€鎾础閻樿京绉存繛鎴濈墛娴煎懘鏁嶉崼銏犘﹂柟?sending闁挎稑鐦坮l 闁活潿鍔嶅﹢浼村捶閹峰瞼鐔呯€垫澘瀚哥槐?
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
      // 2. 闁告艾楠歌ぐ瀛樼▔婵犱胶鐐?
      final res = await DioClient().uploadFiles(
        '/file/uploadBatch',
        files: [file],
      );

      final rawList = res.data is Map ? res.data['data'] : res.data;
      if (rawList is! List || rawList.isEmpty) {
        // 濞戞挸锕ｇ槐鑸靛緞鏉堫偉袝闁挎稑鏈ú鍧楀棘妫颁浇绀?failed 闁绘鍩栭埀?
        ref
            .read(chatMessagesProvider.notifier)
            .upsertMessage(
              localMsg.copyWith(deliveryStatus: DeliveryStatus.failed),
            );
        log.warning('voice upload failed: empty response');
        return;
      }

      final url = rawList.first.toString();

      // 3. 濞戞挸锕ｇ槐鍫曞箣閹邦剙顫犻柨娑樼焸閳ь剚淇虹换?WS 闁告瑦鍨块埀顑胯兌濠€鈥愁潰閿濆洦鐣辨繛鎴濈墛娴?
      _doSendVoice(
        clientMsgId: clientMsgId,
        url: url,
        duration: duration,
        fileSize: file.lengthSync(),
      );

      // 4. 闁告帞濞€濞呭酣寮甸鈧﹢瀛樼▔鐎涙ɑ顦ч柡鍌氭矗濞?
      try {
        file.deleteSync();
      } catch (_) {}
    } catch (e) {
      ref
          .read(chatMessagesProvider.notifier)
          .upsertMessage(
            localMsg.copyWith(deliveryStatus: DeliveryStatus.failed),
          );
      log.error('閻犲浂鍙冮悡璺衡槈閸喍绱栭柛娆愬灴閳ь兛绀侀妵鎴犳嫻? $e');
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

    // 闁哄洤鐡ㄩ弻濠囧嫉椤掆偓濠€鏉戔槈閸喍绱栭柣?url 濞戞捁娅ｅ﹢锛勨偓?url
    final updatedMsg = ChatMessage(
      messageId: clientMsgId,
      clientMsgId: clientMsgId,
      roomId: roomId,
      senderId: user.userId,
      messageType: MessageType.audio,
      content: '[audio]',
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

    log.info('妫ｅ啯鐣?闁告瑦鍨块埀顑挎祰椤曘垽妫呴搹顐ばラ柟? $clientMsgId');
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
    ref.read(replyTargetControllerProvider.notifier).clear(roomId);
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
    ref.read(replyTargetControllerProvider.notifier).clear(roomId);
  }

  // 缂備胶鍠嶇粩鎾儍閸曨偄鏁堕梺顔哄妼瑜板倿鏌呮担瑙勭厵婵?
  MessagePayload _withReplyTarget(MessageType type, MessagePayload payload) {
    if (!_supportsInteraction(type)) return payload;

    final target = ref.read(replyTargetProvider(roomId));
    final messageId = target?.messageId;
    if (messageId == null || messageId.isEmpty) return payload;

    return payload.copyWith(replyTo: messageId);
  }

  bool _supportsInteraction(MessageType type) {
    return type == MessageType.text ||
        type == MessageType.richText ||
        type == MessageType.image ||
        type == MessageType.file ||
        type == MessageType.video;
  }

  void _doSend({
    required MessageType type,
    required MessagePayload payload,
    List<Attachment>? attachments,
    bool clearReplyAfterSend = true,
  }) {
    final String clientMsgId = const Uuid().v4();
    final user = ref.read(authControllerProvider).value;
    if (user == null) {
      log.error('send failed: missing user');
      return;
    }
    final payloadWithReply = _withReplyTarget(type, payload);
    final payloadWithMedia = payloadWithReply.withMedia(
      type,
      attachments ?? const [],
    );
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

    log.info('妫ｅ啯鐣?闁告瑦鍨块埀顑跨劍缁夌兘骞?[$type]: clientMsgId=$clientMsgId');
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
    if (clearReplyAfterSend) {
      ref.read(replyTargetControllerProvider.notifier).clear(roomId);
    }
  }
}

/// 闁煎崬锕ら妵澶嬫綇閹惧啿寮虫俊妤€妫涢崝宥夋倷?Provider
///
/// 濞戞挾鍎ら惁鈩冪▔椤忓懎鐓ｉ梻鍌氼嚟鐎氼厾绮╃€ｎ剦鍚€闁荤偛妫滅欢顓㈠礂閵夛富鏀遍柣鎺炲閸嬶綁鎮╅懜纰樺亾?
@riverpod
FocusNode chatFocusNode(Ref ref, String roomId) {
  final node = FocusNode();
  ref.onDispose(() => node.dispose());
  return node;
}

// 闁?chat_input_controller.dart 濞戞搩鍘介崸濠囧礉?
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

/// @闁圭粯鍔曞鐑芥偐閼哥鍋撴担瑙勬闁?
///
/// 閻庢稒锚閸嬪秹骞撻幇顒€鎸ょ€殿喖婀遍悰銉╂儍閸曨剚鈻旂紒鈧搹鐟靶﹂柟顑跨閹蜂即鎯勭粙鍨綘濞ｅ洠鍓濇导?
class MentionStateData {
  final bool isShowing;
  final int cursorPosition;
  final String searchText;
  final Offset? atSymbolOffset; // @ 缂佹绠戣ぐ鍧楀捶閵娿儳娼屾鐐存磻缁楀倿鎯冮崟顏嗙Т缂?

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
