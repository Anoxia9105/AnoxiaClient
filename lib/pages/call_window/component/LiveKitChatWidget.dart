import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:livekit_client/livekit_client.dart' hide ChatMessage;
import '../../chat/model/ChatMessage.dart';
import '../../chat/provider/ChatNotifier.dart';

/// 聊天Widget - 实时聊天界面
class LiveKitChatWidget extends ConsumerStatefulWidget {
  /// 本地参与者
  final LocalParticipant? localParticipant;

  /// 事件监听器
  final EventsListener<RoomEvent>? listener;

  /// 高度 - 可选，默认50%屏幕高度
  final double? height;

  const LiveKitChatWidget({
    super.key,
    required this.localParticipant,
    required this.listener,
    this.height,
  });

  @override
  ConsumerState<LiveKitChatWidget> createState() => _LiveKitChatWidgetState();
}

class _LiveKitChatWidgetState extends ConsumerState<LiveKitChatWidget> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 自动滚动到底部
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 发送消息
  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      // 获取ChatManager
      final chatManager = ref.read(
        chatManagerProvider(
          (
            localParticipant: widget.localParticipant,
            listener: widget.listener,
          ),
        ),
      );

      // 发送消息
      await chatManager.sendMessage(content);

      // 清空输入框
      _messageController.clear();

      // 滚动到底部
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取ChatManager和消息列表
    final chatManager = ref.watch(
      chatManagerProvider(
        (
          localParticipant: widget.localParticipant,
          listener: widget.listener,
        ),
      ),
    );

    return Container(
      height: widget.height ?? MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '聊天',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${chatManager.messages.length}条消息',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ),

          // 消息列表
          Expanded(
            child: chatManager.messages.isEmpty
                ? Center(
                    child: Text(
                      '暂无消息',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(12.w),
                    itemCount: chatManager.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatManager.messages[index];
                      return _buildMessageBubble(context, message);
                    },
                  ),
          ),

          // 输入框
          _buildInputArea(),
        ],
      ),
    );
  }

  /// 构建消息气泡
  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final isLocal = message.isLocal;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: isLocal ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isLocal) ...[
            // 远端消息 - 左侧显示
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 8.w, bottom: 2.h),
                    child: Text(
                      message.senderName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      message.content,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 8.w, top: 2.h),
                    child: Text(
                      _formatTime(message.timestamp),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // 本地消息 - 右侧显示
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      message.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 8.w, top: 2.h),
                    child: Text(
                      _formatTime(message.timestamp),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建输入区域
  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: 1,
              decoration: InputDecoration(
                hintText: '输入消息...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            tooltip: '发送',
          ),
        ],
      ),
    );
  }

  /// 格式化时间
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return '昨天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${messageDate.month}/${messageDate.day}';
    }
  }
}
