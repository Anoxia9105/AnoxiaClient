import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:anoxia/framework/domain/ChatMessage.dart';
import 'package:anoxia/framework/protocol/message/MessageEunm.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';

class ChatMessageContextMenu extends StatelessWidget {
  final Widget child;
  final ChatMessage message;
  final WidgetRef ref;

  const ChatMessageContextMenu({
    super.key,
    required this.child,
    required this.message,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    // 失败状态下不显示上下文菜单
    if (message.deliveryStatus == DeliveryStatus.failed) return child;

    return GestureDetector(
      onLongPressStart: (details) => _showMenu(context, details.globalPosition),
      onSecondaryTapDown: (details) =>
          _showMenu(context, details.globalPosition),
      child: child,
    );
  }

  // --- 菜单显示逻辑 ---

  Future<void> _showMenu(BuildContext context, Offset globalPosition) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
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
    final List<PopupMenuEntry<String>> items = [];
    final currentUser = ref.read(authControllerProvider).value;
    final bool isMe = message.senderId == currentUser?.userId;

    // 复制选项
    if (message.messageType == MessageType.text ||
        message.messageType == MessageType.quill) {
      items.add(
        _buildItem('copy', HugeIcons.strokeRoundedCopy01, 'chat_copy'.tr()),
      );
    }

    // 收藏选项
    items.add(
      _buildItem(
        'favorite',
        HugeIcons.strokeRoundedFavourite,
        'chat_favorite'.tr(),
      ),
    );

    // 撤回选项
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 16),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
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
        _showSnackBar(context, 'chat_copy_success'.tr());
      }
    });
  }

  String _getPlainContent() {
    final payload = message.payload;
    if (payload == null) return '';

    if (message.messageType == MessageType.text) {
      return payload.content ?? '';
    }

    if (message.messageType == MessageType.quill) {
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

  Future<void> _handleFavorite(BuildContext context) async {
    final messageId = message.messageId;
    if (messageId == null) return;

    try {
      final success = await ref
          .read(chatMessagesProvider.notifier)
          .addFavorite(messageId);
      if (context.mounted) {
        _showSnackBar(
          context,
          success ? 'chat_favorite_success'.tr() : 'chat_favorite_failed'.tr(),
          isError: !success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'chat_favorite_error'.tr(), isError: true);
      }
    }
  }

  Future<void> _handleRevoke(BuildContext context) async {
    final messageId = message.messageId;
    if (messageId == null) return;

    try {
      final success = await ref
          .read(chatMessagesProvider.notifier)
          .recallMessage(messageId, message.roomId ?? '');
      if (context.mounted) {
        _showSnackBar(
          context,
          success ? 'chat_revoke_success'.tr() : 'chat_revoke_failed'.tr(),
          isError: !success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'chat_revoke_error'.tr(), isError: true);
      }
    }
  }

  // 统一反馈 UI
  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : null,
      ),
    );
  }
}
