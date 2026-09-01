import 'dart:async';
import 'package:hugeicons/hugeicons.dart';
import 'dart:convert';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_quill/quill_delta.dart';

import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/ai/ai_feature_flags_provider.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/chat/input/chat_input_controller.dart';
import 'package:anoxia/framework/provider/chat/favorite/chat_favorite_service.dart';
import 'package:anoxia/framework/provider/chat/input/reply_target_provider.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/features/chat/presentation/widgets/mention_list_widget.dart';

import 'ai_ask_bubble.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

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
  /// 最近一次菜单弹出的全局坐标（「问AI」气泡锚定用）
  Offset? _lastMenuPosition;

  @override
  Widget build(BuildContext context) {
    // 失败状态下不显示上下文菜单
    if (widget.message.deliveryStatus == DeliveryStatus.failed) {
      return widget.child;
    }

    // 全平台注册右键和长按：
    // - 鼠标右键直接弹菜单（用原始指针监听而非 onSecondaryTapDown）
    // - 移动端 / 触屏 Web 长按弹出菜单
    //
    // 右键必须用 Listener 原始指针监听：GestureDetector 的 onSecondaryTapDown
    // 依赖手势竞技场裁决，而 flutter_quill 只读气泡内部（EditorTextSelectionGestureDetector
    // 的 _TransparentTapGestureRecognizer）会注册同级的右击识别器且位于更深的命中路径，
    // 竞技场总是先裁决给 quill，导致富文本消息文字区域右键菜单偶发弹不出来。
    // 原始指针事件不受竞技场影响，沿命中路径必然触发，故改用 onPointerDown 拦截右键。
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        // PointerDownEvent.position 本身已是全局坐标，直接使用；
        // 不要再经 localToGlobal 二次变换，否则菜单会偏移气泡的全局位置。
        if (event.buttons & kSecondaryMouseButton == 0) return;
        _showMenuAtPosition(context, event.position);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPressStart: (details) =>
            _showMenuAtPosition(context, details.globalPosition),
        child: widget.child,
      ),
    );
  }

  /// 在指定全局位置弹出原生菜单（桌面右键 / 移动端长按通用）
  Future<void> _showMenuAtPosition(
    BuildContext context,
    Offset globalPosition,
  ) async {
    _lastMenuPosition = globalPosition;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      globalPosition & const Size(40, 40),
      Offset.zero & overlay.size,
    );

    final action = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RadiusToken.lg)),
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
        _buildItem('copy', HugeIcons.strokeRoundedCopy01, 'chat_copy'.tr()),
      );
      // 问AI：受服务端 chatEnabled 开关控制，关闭时不展示入口
      final chatEnabled = ref.watch(aiFeatureFlagsProvider).value?.chatEnabled ?? true;
      if (chatEnabled) {
        items.add(
          _buildItem(
            'aiAsk',
            HugeIcons.strokeRoundedSparkles,
            'chat_ai.ask'.tr(),
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }

    final canReply =
        widget.message.deliveryStatus == DeliveryStatus.sent &&
        widget.message.messageId?.isNotEmpty == true;

    if (canReply) {
      items.add(
        _buildItem(
          'reply',
          HugeIcons.strokeRoundedMessageCircleReply,
          'chat_reply'.tr(),
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
      case 'aiAsk':
        _handleAiAsk(context);
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

  /// 问AI：以消息纯文本为上下文弹出 AI 气泡
  void _handleAiAsk(BuildContext context) {
    final text = _getPlainContent().trim();
    if (text.isEmpty) {
      Toast.showToast('chat_ai.empty_content'.tr(), type: ToastType.warning);
      return;
    }
    final anchor = _lastMenuPosition;
    if (anchor == null) return;
    // 菜单关闭后再弹气泡：延迟一帧避免与 showMenu 的移除动画同帧竞争浮层
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showAiAskBubble(context: context, anchor: anchor, quotedText: text);
    });
  }

  void _handleCopy(BuildContext context) {
    final text = _getPlainContent();
    if (text.isEmpty) return;

    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (context.mounted) {
        Toast.showToast('chat_copy_success'.tr(), type: ToastType.success);
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
              final userName = MentionUser.displayName(map['mention']) ?? '';
              sb.write('@$userName ');
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
      if (success) {
        ref.invalidate(chatFavoriteListProvider);
      }
      if (context.mounted) {
        Toast.showToast(
          success ? 'chat_favorite_success'.tr() : 'chat_favorite_failed'.tr(),
          type: success ? ToastType.success : ToastType.error,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Toast.showToast('chat_favorite_error'.tr(), type: ToastType.error);
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
          type: success ? ToastType.success : ToastType.error,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Toast.showToast('chat_revoke_error'.tr(), type: ToastType.error);
      }
    }
  }
}
