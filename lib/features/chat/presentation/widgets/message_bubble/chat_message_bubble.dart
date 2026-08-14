/// 聊天消息气泡组件 - 主入口
///
/// 职责：根据消息类型选择渲染策略，分发到系统消息或用户消息布局。
/// 依赖：通过 Riverpod 获取当前用户、房间成员等数据，使用策略模式渲染不同消息类型。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/base/message_render_factory.dart';
import 'package:anoxia/framework/provider/chat/message/chat_content_density_controller.dart';

// 导入拆分后的子组件
import 'system_message_bubble.dart';
import 'user_message_bubble.dart';
import 'message_bubble_view_data.dart';

/// 单条消息气泡组件（顶层入口）
///
/// 根据消息类型自动选择渲染策略，构建系统消息或用户消息的气泡展示。
/// 外部使用时只需传入 [message] 对象。
class ChatMessageBubble extends ConsumerWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      // 1. 根据消息类型获取对应的渲染策略（文本、图片、文件等）
      final strategy = MessageRenderFactory.getStrategy(message.messageType);

      // 2. 聚合所有展示所需的视图数据（颜色、是否自己、是否@我等）
      final view = MessageBubbleViewData.resolve(context, ref, message);
      final density = ref.watch(chatContentDensityProvider);
      final layout = resolveChatMessageLayout(
        density,
        isCurrentUser: view.isCurrentUser,
        baseHorizontalPadding: view.horizontalPadding,
      );

      // 3. 系统消息单独处理（无头像、无气泡、居中显示）
      if (message.messageType == MessageType.system) {
        return SystemMessageBubble(
          message: message,
          strategy: strategy,
          textColor: view.textColor,
          horizontalPadding: layout.horizontalPadding,
          verticalPadding: layout.verticalMargin,
        );
      }

      // 4. 普通用户消息（含头像、昵称、气泡、状态指示器）
      return UserMessageBubble(
        message: message,
        strategy: strategy,
        view: view,
        layout: layout,
      );
    } catch (e, stack) {
      // 单条消息渲染失败不影响整个列表。WASM 下可能因 Platform._operatingSystem
      // 等异常导致渲染中断，这里隔离错误并显示降级 UI，同时记录原始堆栈以便定位。
      debugPrint('消息渲染失败 [type=${message.messageType}]: $e\n$stack');
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 4),
        child: Material(
          color: const Color(0x1AFF0000),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              '消息渲染失败: $e',
              style: const TextStyle(fontSize: 11, color: Colors.red),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }
  }
}
