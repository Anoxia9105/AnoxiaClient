/// 记事本分享到聊天（快照卡片）
///
/// 将笔记以 `cardType='note'` 的卡片消息快照发送到指定聊天室：
/// 标题 + 摘要 + 完整纯文本快照写入 `properties['content']`，
/// 接收方无需访问原始笔记即可阅读（无泄漏风险）。
library;

import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../chat/presentation/widgets/chat_room_picker_dialog.dart';

/// 分享笔记到聊天室。
///
/// [noteId] 原笔记 ID（用于所有者跳转打开）；
/// [title] 卡片标题；[content] 完整纯文本快照；
/// [preview] 可选短摘要，缺省截取 [content] 前 200 字符；
/// [updatedAt] 可选更新时间戳字符串。
Future<void> shareNoteToChat(
  BuildContext context,
  WidgetRef ref, {
  required int noteId,
  required String title,
  required String content,
  String? preview,
  String? updatedAt,
}) async {
  final room = await showChatRoomPicker(context);
  final roomId = room?.roomId;
  if (roomId == null || roomId.isEmpty) return;

  final ownerId = ref.read(authControllerProvider).value?.userId;
  final displayTitle = title.trim().isEmpty ? 'note_untitled'.tr() : title.trim();
  final summary = (preview?.trim().isNotEmpty == true ? preview! : content)
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
  final card = CardPayload(
    cardType: 'note',
    entityId: noteId.toString(),
    title: displayTitle,
    summary: summary.length > 200 ? summary.substring(0, 200) : summary,
    properties: {
      'noteId': noteId.toString(),
      if (ownerId != null) 'ownerId': ownerId.toString(),
      if (updatedAt != null && updatedAt.isNotEmpty) 'updatedAt': updatedAt,
      'content': content.length > 10000 ? content.substring(0, 10000) : content,
    },
  );

  final sent = ref
      .read(chatInputControllerProvider(roomId).notifier)
      .sendCardMessage(card);
  Toast.showToast(
    sent
        ? 'note_share_sent'.tr(args: [room?.roomName ?? ''])
        : 'note_share_failed'.tr(),
    type: sent ? ToastType.success : ToastType.error,
  );
}
