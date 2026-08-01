import 'dart:async';
import 'dart:convert';
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/provider/chat/input/reply_target_provider.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';

/// 聊天消息上下文菜单组件
///
/// 为消息提供右键菜单（桌面端）和长按菜单（移动端/Web）功能，支持：
/// - 复制消息内容
/// - 收藏消息
/// - 撤回消息（仅自己发送的消息）
///
/// 全平台使用 Flutter 原生 [showMenu] 实现，无第三方依赖，WASM 安全。
class ChatMessageContextMenu extends ConsumerStatefulWidget {
  /// 包裹的子组件
  final Widget child;

  /// 消息数据
  final ChatMessage message;

  const ChatMessageContextMenu({
    super.key,
    required this.child,
    required this.message,
  });

  @override
  ConsumerState<ChatMessageContextMenu> createState() =>
      _ChatMessageContextMenuState();
}

class _ChatMessageContextMenuState
    extends ConsumerState<ChatMessageContextMenu> {
  @override
  Widget build(BuildContext context) {
    // 失败状态下不显示上下文菜单
    if (widget.message.deliveryStatus == DeliveryStatus.failed) {
      return widget.child;
    }

    if (DeviceUtil.isRealDesktop()) {
      // 桌面端：右键菜单
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapDown: (details) =>
            _showMenuAtPosition(context, details.globalPosition),
        child: widget.child,
      );
    }

    // 移动端 / Web：长按菜单
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (details) =>
          _showMenuAtPosition(context, details.globalPosition),
      child: widget.child,
    );
  }

  /// 在指定全局位置弹出原生菜单（桌面右键 / 移动端长按通用）
  Future<void> _showMenuAtPosition(
    BuildContext context,
    Offset globalPosition,
  ) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      globalPosition & const Size(40, 40),
      Offset.zero & overlay.size,
    );

    final action = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      items: _buildMenuItems(context),
      menuPadding: const EdgeInsets.symmetric(vertical: 6),
    );

    if (!context.mounted || action == null) return;
    _handleAction(context, action);
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    final currentUser = ref.read(authControllerProvider).value;
    final bool isMe = widget.message.senderId == currentUser?.userId;
    final items = <PopupMenuEntry<String>>[];

    if (widget.message.messageType == MessageType.text ||
        widget.message.messageType == MessageType.richText) {
      items.add(
        _buildItem(
          'copy',
          HugeIcons.strokeRoundedCopy01,
          'chat_copy'.tr(),
        ),
      );
    }

    final canReply =
        widget.message.deliveryStatus == DeliveryStatus.sent &&
        widget.message.messageId?.isNotEmpty == true;

    if (canReply) {
      items.add(
        _buildItem(
          'reply',
          HugeIcons.strokeRoundedMessageCircleReply,
          '引用',
        ),
      );
    }

    items.add(
      _buildItem(
        'favorite',
        HugeIcons.strokeRoundedFavourite,
        'chat_favorite'.tr(),
      ),
    );

    if (isMe) {
      items.add(
        _buildItem(
          'revoke',
          HugeIcons.strokeRoundedUndo,
          'chat_revoke'.tr(),
          color: Colors.redAccent,
        ),
      );
    }

    return items;
  }

  PopupMenuItem<String> _buildItem(
    String value,
    List<List<dynamic>> icon,
    String label, {
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 32,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(icon: icon, size: 16, color: color),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  // --- 动作处理逻辑 ---

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'copy':
        _handleCopy(context);
        break;
      case 'favorite':
        unawaited(_handleFavorite(context));
        break;
      case 'reply':
        _handleReply();
        break;
      case 'revoke':
        unawaited(_handleRevoke(context));
        break;
    }
  }

  void _handleCopy(BuildContext context) {
    final text = _getPlainContent();
    if (text.isEmpty) return;

    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (context.mounted) {
        Toast.showToast('chat_copy_success'.tr());
      }
    });
  }

  String _getPlainContent() {
    final payload = widget.message.payload;
    if (payload == null) return '';

    if (widget.message.messageType == MessageType.text) {
      return payload.content ?? '';
    }

    if (widget.message.messageType == MessageType.richText) {
      try {
        final deltaJson = jsonDecode(payload.quillDelta ?? '[]');
        final delta = Delta.fromJson(deltaJson);
        final sb = StringBuffer();

        for (final op in delta.operations) {
          if (op.data is String) {
            sb.write(op.data);
          } else if (op.data is Map) {
            final map = op.data as Map;
            if (map.containsKey('mention')) {
              final data = map['mention'] is String
                  ? jsonDecode(map['mention'])
                  : map['mention'];
              sb.write('@${data['userName'] ?? ''} ');
            }
          }
        }
        return sb.toString().trim();
      } catch (_) {
        return '';
      }
    }
    return '';
  }

  void _handleReply() {
    final roomId = widget.message.roomId;
    final messageId = widget.message.messageId;
    if (roomId == null ||
        roomId.isEmpty ||
        messageId == null ||
        messageId.isEmpty) {
      return;
    }

    ref
        .read(replyTargetControllerProvider.notifier)
        .set(roomId, widget.message);
    ref.read(chatFocusNodeProvider(roomId)).requestFocus();
  }

  Future<void> _handleFavorite(BuildContext context) async {
    final messageId = widget.message.messageId;
    if (messageId == null) return;

    try {
      final success = await ref
          .read(chatMessagesProvider.notifier)
          .addFavorite(messageId);
      if (context.mounted) {
        Toast.showToast(
          success ? 'chat_favorite_success'.tr() : 'chat_favorite_failed'.tr(),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Toast.showToast('chat_favorite_error'.tr());
      }
    }
  }

  Future<void> _handleRevoke(BuildContext context) async {
    final messageId = widget.message.messageId;
    if (messageId == null) return;

    try {
      final success = await ref
          .read(chatMessagesProvider.notifier)
          .recallMessage(messageId, widget.message.roomId ?? '');
      if (context.mounted) {
        Toast.showToast(
          success ? 'chat_revoke_success'.tr() : 'chat_revoke_failed'.tr(),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Toast.showToast('chat_revoke_error'.tr());
      }
    }
  }
}
