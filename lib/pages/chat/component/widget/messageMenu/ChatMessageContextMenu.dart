import 'package:anoxia/framework/protocol/message/MessageEunm.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:anoxia/framework/domain/ChatMessage.dart';
import 'package:hugeicons/hugeicons.dart';

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

  void _showMenu(BuildContext context, Offset globalPosition) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final position = RelativeRect.fromRect(
      globalPosition & const Size(40, 40),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      items: _buildMenuItems(context),
      menuPadding: EdgeInsets.all(4),
    ).then((action) {
      if (action == null) return;
      _handleAction(context, action);
    });
  }

  // 动态生成菜单项
  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    final List<PopupMenuEntry<String>> items = [];

    final currentUser = ref.read(authControllerProvider).value;
    final currentUserId = currentUser?.userId;

    final bool isMe = message.senderId == currentUserId;

    // 只有文本消息才显示复制 (这里你可以根据具体业务调整)
    if (message.messageType == MessageType.text ||
        message.messageType == MessageType.quill) {
      items.add(
        _buildItem('copy', HugeIcons.strokeRoundedCopy01, "chat_copy".tr()),
      );
    }

    items.add(
      _buildItem(
        'favorite',
        HugeIcons.strokeRoundedFavourite,
        "chat_favorite".tr(),
      ),
    );

    if (isMe) {
      items.add(
        _buildItem('revoke', HugeIcons.strokeRoundedUndo, "chat_revoke".tr()),
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
          HugeIcon(icon: icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }

  // 处理点击事件
  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'copy':
        // TODO: 实现复制到剪贴板逻辑
        break;
      case 'favorite':
        // TODO: 实现回复逻辑
        break;
      case 'revoke':
        // TODO: ref.read(...).deleteMessage(message.messageId);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 移动端：长按触发
      onLongPressStart: (details) => _showMenu(context, details.globalPosition),
      // 桌面/Web端：鼠标右键触发
      onSecondaryTapDown: (details) =>
          _showMenu(context, details.globalPosition),
      child: child,
    );
  }
}
