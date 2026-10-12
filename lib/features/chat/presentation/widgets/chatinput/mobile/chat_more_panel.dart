// 移动端聊天附件和通话操作面板。
//
// 提供图片、文件、@提及、语音通话和视频通话等快捷操作入口。
import 'package:anoxia/common/utils/device_util.dart' show DeviceUtil;
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/provider/ai/ai_feature_flags_provider.dart';
import 'package:anoxia/features/chat/presentation/widgets/appbar/chat_bar_handlers.dart';
import 'package:anoxia/framework/provider/chat/call/call_initial_media.dart';
import 'package:anoxia/framework/provider/chat/call/call_status_provider.dart';
import 'package:anoxia/framework/provider/chat/call/call_window_controller.dart';
import 'package:anoxia/framework/provider/chat/call/mobile_call_session_provider.dart';
import 'package:anoxia/framework/provider/chat/call/room_controller.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_action_item.dart';
import 'chat_action_pager.dart';
import 'chat_content_picker.dart';
import 'package:anoxia/features/chat/presentation/pages/chat_capture_page.dart';
import 'package:anoxia/features/chat/application/saved_message_payload.dart';
import 'package:anoxia/framework/domain/chat_contact_vo.dart';
import 'package:anoxia/framework/domain/chat_favorite.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/common/widgets/toast.dart';

/// Mobile chat attachment and call actions.
class ChatMorePanel extends ConsumerWidget {
  /// 聊天房间 ID。
  final String roomId;

  /// 文件选择回调。
  /// [type] 文件类型，[isImage] 是否为图片。
  final Function(FileType type, bool isImage) onPickFile;

  /// @提及点击回调。
  final VoidCallback onMentionTap;
  final VoidCallback? onAiTap;

  const ChatMorePanel({
    super.key,
    required this.roomId,
    required this.onPickFile,
    required this.onMentionTap,
    this.onAiTap,
  });

  Future<void> _capture(BuildContext context, WidgetRef ref) async {
    if (!DeviceUtil.isRealMobile() && !DeviceUtil.isWeb) {
      Toast.showToast('chat_capture_mobile_only'.tr());
      return;
    }
    // 通话中不争抢摄像头与麦克风。
    if (ref.read(mobileCallSessionControllerProvider) != null ||
        ref.read(callWindowControllerProvider) != null) {
      Toast.showToast('chat_capture_call_busy'.tr());
      return;
    }
    final result = await Navigator.of(context).push<ChatCaptureResult>(
      MaterialPageRoute(builder: (_) => const ChatCapturePage()),
    );
    if (result == null || !context.mounted) return;
    try {
      final size = await result.file.length();
      final bytes = DeviceUtil.isWeb ? await result.file.readAsBytes() : null;
      if (!context.mounted) return;
      await ref
          .read(chatInputControllerProvider(roomId).notifier)
          .sendPickedAttachments([
            PlatformFile(
              // Web 相机返回 blob URL / 无扩展名文件，补齐后缀供媒体分类使用。
              name: DeviceUtil.isWeb
                  ? 'capture.${result.isVideo ? (result.file.mimeType?.contains('mp4') == true ? 'mp4' : 'webm') : 'jpg'}'
                  : result.file.name,
              size: size,
              path: DeviceUtil.isWeb ? null : result.file.path,
              bytes: bytes,
            ),
          ]);
    } catch (_) {
      if (context.mounted) {
        Toast.showToast('chat_share_failed'.tr(), type: ToastType.error);
      }
    }
  }

  Future<void> _pickContent(
    BuildContext context,
    WidgetRef ref,
    bool favorites,
  ) async {
    final selected = await Navigator.of(context).push<Object>(
      MaterialPageRoute(
        builder: (_) => ChatContentPicker(favorites: favorites),
      ),
    );
    if (selected == null || !context.mounted) return;
    final input = ref.read(chatInputControllerProvider(roomId).notifier);
    bool sent = false;
    if (selected is ChatFavorite) {
      final message = selected.toChatMessage();
      final payload = message.payload;
      if (payload != null && message.messageType != MessageType.system) {
        sent = input.sendSavedMessage(
          message.messageType ?? MessageType.text,
          savedMessagePayload(payload),
        );
      }
    } else if (selected is ChatContactVO) {
      // 名片只发送公开昵称，不泄露本地好友备注。
      sent = input.sendCardMessage(
        CardPayload(
          cardType: 'contact',
          entityId: selected.contactId.toString(),
          title: selected.nickName?.trim().isNotEmpty == true
              ? selected.nickName
              : selected.contactId.toString(),
          thumbnailUrl: selected.avatar,
          properties: {if (selected.sex != null) 'sex': selected.sex!},
        ),
      );
    }
    if (!sent) Toast.showToast('chat_share_failed'.tr(), type: ToastType.error);
  }

  Future<void> _handleCallTap(
    BuildContext context,
    WidgetRef ref,
    CallInitialMedia initialMedia,
  ) async {
    final mobileSession = ref.read(mobileCallSessionControllerProvider);
    final callWindow = ref.read(callWindowControllerProvider);
    final hasActiveCall =
        callWindow != null ||
        (DeviceUtil.isRealMobile() && mobileSession != null);

    if (hasActiveCall && DeviceUtil.isRealMobile()) {
      if (mobileSession != null && mobileSession.roomId == roomId) {
        ref.read(mobileCallSessionControllerProvider.notifier).enterCallPage();
        return;
      }

      final switchConfirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('call_switch_confirm_title'.tr()),
          content: Text('call_switch_confirm_message'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('cancel'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('confirm'.tr()),
            ),
          ],
        ),
      );
      if (switchConfirmed != true || !context.mounted) return;
      // 切换通话前先断开旧通话的 LiveKit 房间，释放摄像头/麦克风。
      final oldToken = mobileSession?.token;
      ref.read(mobileCallSessionControllerProvider.notifier).end();
      if (oldToken != null && oldToken.isNotEmpty) {
        try {
          await ref.read(roomControllerProvider(oldToken).notifier).leave();
        } catch (e) {
          debugLog('切换通话时清理旧房间失败: $e');
        }
      }
    }

    final room = ref.read(currentRoomProvider(roomId));
    if (room == null || !context.mounted) return;
    await ChatBarHandlers.onCallPressed(
      context,
      ref,
      room,
      initialMedia: initialMedia,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callWindow = ref.watch(callWindowControllerProvider);
    final mobileCallSession = ref.watch(mobileCallSessionControllerProvider);
    final callStatus = ref.watch(roomCallStatusProvider(roomId));

    ref.read(callStatusControllerProvider.notifier).ensureLoaded(roomId);

    final hasActiveCall =
        callWindow != null ||
        (DeviceUtil.isRealMobile() && mobileCallSession != null);
    final isCallingNow = callStatus.calling;
    final callIcon = hasActiveCall
        ? HugeIcons.strokeRoundedVideoReplay
        : HugeIcons.strokeRoundedCallRinging03;
    final callLabel = hasActiveCall
        ? 'appbar_call_back_to_window'.tr()
        : 'appbar_call_join'.tr();

    return ChatActionPager(
      actions: [
        if (onAiTap != null &&
            (ref.watch(aiFeatureFlagsProvider).value?.noteAvailable ?? true))
          ChatActionItem(
            icon: HugeIcons.strokeRoundedSparkles,
            label: 'chat_ai.assist_title'.tr(),
            onTap: onAiTap!,
          ),
        ChatActionItem(
          icon: HugeIcons.strokeRoundedCamera01,
          label: 'chat_capture'.tr(),
          onTap: () => _capture(context, ref),
        ),
        ChatActionItem(
          icon: HugeIcons.strokeRoundedImage02,
          label: 'toolbar_image'.tr(),
          onTap: () => onPickFile(FileType.image, true),
        ),
        ChatActionItem(
          icon: HugeIcons.strokeRoundedFiles02,
          label: 'toolbar_file'.tr(),
          onTap: () => onPickFile(FileType.any, false),
        ),
        ChatActionItem(
          icon: HugeIcons.strokeRoundedAt,
          label: '@',
          onTap: onMentionTap,
        ),
        ChatActionItem(
          icon: HugeIcons.strokeRoundedBookmark01,
          label: 'chat_share_favorite'.tr(),
          onTap: () => _pickContent(context, ref, true),
        ),
        ChatActionItem(
          icon: HugeIcons.strokeRoundedContact01,
          label: 'chat_share_contact'.tr(),
          onTap: () => _pickContent(context, ref, false),
        ),
        if (hasActiveCall || isCallingNow)
          ChatActionItem(
            icon: callIcon,
            label: callLabel,
            onTap: () => _handleCallTap(context, ref, CallInitialMedia.audio),
          )
        else ...[
          ChatActionItem(
            icon: HugeIcons.strokeRoundedCall02,
            label: 'call_audio_call'.tr(),
            onTap: () => _handleCallTap(context, ref, CallInitialMedia.audio),
          ),
          ChatActionItem(
            icon: HugeIcons.strokeRoundedVideo01,
            label: 'call_video_call'.tr(),
            onTap: () => _handleCallTap(context, ref, CallInitialMedia.video),
          ),
        ],
      ],
    );
  }
}
