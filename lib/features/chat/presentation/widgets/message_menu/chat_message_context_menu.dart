import 'dart:async';
import 'dart:convert';
import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:custom_pop_up_menu_fork/custom_pop_up_menu.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:anoxia/framework/domain/ChatMessage.dart';
import 'package:anoxia/framework/protocol/message/MessageEunm.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/provider/chat/input/reply_target_provider.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';

/// 聊天消息上下文菜单组件
///
/// 为消息提供右键菜单（桌面端）和长按菜单（移动端）功能，支持：
/// - 复制消息内容
/// - 收藏消息
/// - 撤回消息（仅自己发送的消息）
class ChatMessageContextMenu extends StatefulWidget {
  /// 包裹的子组件
  final Widget child;

  /// 消息数据
  final ChatMessage message;

  /// Riverpod 状态引用
  final WidgetRef ref;

  const ChatMessageContextMenu({
    super.key,
    required this.child,
    required this.message,
    required this.ref,
  });

  @override
  State<ChatMessageContextMenu> createState() => _ChatMessageContextMenuState();
}

class _ChatMessageContextMenuState extends State<ChatMessageContextMenu> {
  final CustomPopupMenuController _menuController = CustomPopupMenuController();

  @override
  Widget build(BuildContext context) {
    // 失败状态下不显示上下文菜单
    if (widget.message.deliveryStatus == DeliveryStatus.failed) {
      return widget.child;
    }

    if (DeviceUtil.isRealDesktop()) {
      return GestureDetector(
        onSecondaryTapDown: (details) =>
            _showDesktopMenu(context, details.globalPosition),
        child: widget.child,
      );
    }

    final popup = CustomPopupMenu(
      controller: _menuController,
      pressType: PressType.longPress,
      barrierColor: Colors.transparent,
      showArrow: false,
      horizontalMargin: 8,
      verticalMargin: 8,
      menuBuilder: () => _buildMenuPanel(context),
      child: widget.child,
    );

    return popup;
  }

  Future<void> _showDesktopMenu(
    BuildContext context,
    Offset globalPosition,
  ) async {
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
      items: _buildDesktopMenuItems(context),
      menuPadding: const EdgeInsets.symmetric(vertical: 6),
    );

    if (!context.mounted || action == null) return;
    _handleAction(context, action);
  }

  List<PopupMenuEntry<String>> _buildDesktopMenuItems(BuildContext context) {
    final currentUser = widget.ref.read(authControllerProvider).value;
    final bool isMe = widget.message.senderId == currentUser?.userId;
    final items = <PopupMenuEntry<String>>[];

    if (widget.message.messageType == MessageType.text ||
        widget.message.messageType == MessageType.richText) {
      items.add(
        _buildDesktopItem(
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
        _buildDesktopItem(
          'reply',
          HugeIcons.strokeRoundedMessageCircleReply,
          '引用',
        ),
      );
    }

    items.add(
      _buildDesktopItem(
        'favorite',
        HugeIcons.strokeRoundedFavourite,
        'chat_favorite'.tr(),
      ),
    );

    if (isMe) {
      items.add(
        _buildDesktopItem(
          'revoke',
          HugeIcons.strokeRoundedUndo,
          'chat_revoke'.tr(),
          color: Colors.redAccent,
        ),
      );
    }

    return items;
  }

  PopupMenuItem<String> _buildDesktopItem(
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

  Widget _buildMenuPanel(BuildContext context) {
    final currentUser = widget.ref.read(authControllerProvider).value;
    final bool isMe = widget.message.senderId == currentUser?.userId;

    final items = <Widget>[
      if (widget.message.messageType == MessageType.text ||
          widget.message.messageType == MessageType.richText)
        _buildMenuItem(
          context,
          action: 'copy',
          icon: HugeIcons.strokeRoundedCopy01,
          label: 'chat_copy'.tr(),
        ),
      if (widget.message.deliveryStatus == DeliveryStatus.sent &&
          widget.message.messageId?.isNotEmpty == true)
        _buildMenuItem(
          context,
          action: 'reply',
          icon: HugeIcons.strokeRoundedMessageCircleReply,
          label: '引用',
        ),
      _buildMenuItem(
        context,
        action: 'favorite',
        icon: HugeIcons.strokeRoundedFavourite,
        label: 'chat_favorite'.tr(),
      ),
      if (isMe)
        _buildMenuItem(
          context,
          action: 'revoke',
          icon: HugeIcons.strokeRoundedUndo,
          label: 'chat_revoke'.tr(),
          color: Colors.redAccent,
        ),
    ];

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minWidth: 130),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: items),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String action,
    required List<List<dynamic>> icon,
    required String label,
    Color? color,
  }) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: () {
        _menuController.hideMenu();
        _handleAction(context, action);
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: icon, size: 16, color: c),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 12, color: c)),
          ],
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

    widget.ref
        .read(replyTargetControllerProvider.notifier)
        .set(roomId, widget.message);
    widget.ref.read(chatFocusNodeProvider(roomId)).requestFocus();
  }

  Future<void> _handleFavorite(BuildContext context) async {
    final messageId = widget.message.messageId;
    if (messageId == null) return;

    try {
      final success = await widget.ref
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
      final success = await widget.ref
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
