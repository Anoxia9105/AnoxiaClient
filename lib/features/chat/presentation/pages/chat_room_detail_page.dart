import 'package:anoxia/common/utils/DateUtil.dart';
import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/SkeletonBox.dart';
import 'package:anoxia/common/widgets/ws_connection_banner.dart';
import 'package:anoxia/features/chat/models/message_item.dart';
import 'package:anoxia/features/chat/presentation/pages/banned_content_page.dart';
import 'package:anoxia/features/chat/presentation/pages/empty_messages_page.dart';
import 'package:anoxia/features/chat/presentation/pages/no_conversation_page.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/chat_room_detail_bottom_bar.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/chat_room_detail_scroll_down_button.dart';
import 'package:anoxia/features/chat/presentation/widgets/skeleton/chat_room_detail_skeleton.dart';
import 'package:anoxia/features/chat/presentation/widgets/appbar/chat_app_bar.dart';
import 'package:anoxia/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:anoxia/framework/domain/ChatRoomVO.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_ui_item_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';

/// 聊天房间详情页面
///
/// 显示房间内的消息列表、输入框、房间状态等信息
/// 支持时间分隔、滚动定位、加载更多历史消息、WebSocket连接状态显示等功能
class ChatRoomDetail extends ConsumerStatefulWidget {
  final String roomId;
  const ChatRoomDetail({super.key, required this.roomId});

  @override
  ConsumerState<ChatRoomDetail> createState() => _ChatRoomDetailState();
}

class _ChatRoomDetailState extends ConsumerState<ChatRoomDetail> {
  /// FlutterListView 控制器，用于控制列表滚动和定位
  final FlutterListViewController _listViewController =
      FlutterListViewController();

  /// 是否显示滚动到底部按钮
  bool _showScrollDownButton = false;

  /// 构建时间分隔 UI
  ///
  /// [timestamp] 时间戳（毫秒）
  /// [context] 构建上下文
  /// 返回 时间分隔条 Widget
  Widget _buildTimeDividerWidget(int timestamp, BuildContext context) {
    final locale = context.locale.languageCode;
    final text = DateUtil.formatWeChatTimeDivider(timestamp, locale);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _setupScrollListeners();
  }

  @override
  void dispose() {
    _listViewController.dispose();
    super.dispose();
  }

  void _setupScrollListeners() {
    _listViewController.addListener(() {
      final bool isFarFromBottom = _listViewController.offset > 300;
      if (isFarFromBottom != _showScrollDownButton) {
        setState(() => _showScrollDownButton = isFarFromBottom);
      }
    });

    _listViewController
        .sliverController
        .onPaintItemPositionsCallback = (height, positions) {
      if (positions.isEmpty) return;
      final currentRoomId = widget.roomId;
      if (currentRoomId.isEmpty) return;

      // 直接看滑动到的 maxVisibleIndex
      int maxVisibleIndex = positions
          .map((p) => p.index)
          .reduce((a, b) => a > b ? a : b);

      // 通过 Riverpod 异步高效读取平铺列表长度
      final flatItemsLength = ref
          .read(chatUiListProvider(currentRoomId))
          .items
          .length;

      // 触底（反转列表的顶部，即触及历史边界）触发翻页
      if (flatItemsLength >= 10 && maxVisibleIndex >= flatItemsLength - 5) {
        ref.read(chatMessagesProvider.notifier).loadMoreHistory(currentRoomId);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final currentRoom = ref.watch(currentRoomProvider(widget.roomId));
    if (currentRoom == null) return const NoConversationPage();

    /// 监听房间详情初始化状态
    final entryTask = ref.watch(roomEntryTaskProvider(widget.roomId));

    /// 监听 WebSocket 连接状态
    final wsState = ref.watch(wsControllerProvider);

    /// 监听这个房间是否有更多消息
    final hasMore = ref.watch(
      chatHasMoreProvider.select((map) => map[widget.roomId] ?? false),
    );

    // 监听清洗平铺后的 UI 专属混合列表
    final chatUiListResult = ref.watch(chatUiListProvider(widget.roomId));
    final flatItems = chatUiListResult.items;

    /// 加载中且没有缓存消息时显示骨架屏
    final showInitialSkeleton = entryTask.isLoading && flatItems.isEmpty;

    //当房间 ID 改变时，重置滚动按钮状态
    ref.listen<String?>(activeRoomIdProvider, (prev, next) {
      if (prev != next) setState(() => _showScrollDownButton = false);
    });

    return Scaffold(
      backgroundColor: DeviceUtil.isRealDesktop()
          ? Colors.transparent
          : Theme.of(context).colorScheme.surface,
      appBar: showInitialSkeleton
          ? AppBar()
          : ChatAppBar(roomId: widget.roomId),
      drawerScrimColor: Colors.transparent,
      body: Column(
        children: [
          /// 仅移动端显示 WebSocket 连接状态横幅，桌面端通过更显眼的全局状态提示（标题栏图标）来展示连接状态
          if (DeviceUtil.isRealMobile()) WsConnectionBanner(state: wsState),
          Expanded(
            child: _buildChatBody(
              showInitialSkeleton: showInitialSkeleton,
              entryTask: entryTask,
              flatItems: flatItems,
              hasMore: hasMore,
              currentRoom: currentRoom,
            ),
          ),
        ],
      ),

      /// 根据滚动位置显示滚动到底部按钮，点击后平滑滚动到底部（即 index 0）
      floatingActionButton: _showScrollDownButton
          ? ChatRoomDetailScrollDownButton(
              onPressed: () => _scrollToBottom(animated: true),
            )
          : null,

      /// 底部输入栏
      bottomNavigationBar: ChatRoomDetailBottomBar(
        showSkeleton: showInitialSkeleton,
        roomStatus: currentRoom.roomStatus,
        onFieldTap: () => _scrollToBottom(animated: true),
      ),
    );
  }

  /// 集中管理聊天主体的多状态分支
  Widget _buildChatBody({
    required bool showInitialSkeleton,
    required AsyncValue<void> entryTask,
    required List<ChatListItem> flatItems,
    required bool hasMore,
    required ChatRoomVO currentRoom,
  }) {
    if (showInitialSkeleton) return const ChatRoomDetailSkeleton();
    if (entryTask.hasError && flatItems.isEmpty) {
      return Center(
        child: Text('${'chat_initialization_failed'.tr()}: ${entryTask.error}'),
      );
    }
    if (currentRoom.roomStatus == 2) return const BannedContentPage();
    if (flatItems.isEmpty) return const EmptyMessagesPage();

    return FlutterListView(
      controller: _listViewController,
      reverse: true, // 保持反转状态
      delegate: FlutterListViewDelegate(
        (context, index) {
          // 由于列表反转，加载更多（旧消息）的 Loading 骨架屏出现在列表的最后一项
          if (hasMore && index == flatItems.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: SkeletonBox(width: 120, height: 12, radius: 10),
              ),
            );
          }

          // 关键变动：无需再用 flatItems.length - 1 - index 倒序计算
          // 因为 flatItems 在 Provider 里已经被反转过了，此处直接一一映射即可！
          final item = flatItems[index];

          return switch (item) {
            TimeDividerItem(:final timestamp) => _buildTimeDividerWidget(
              timestamp,
              context,
            ),
            MessageItem(:final message) => ChatMessageBubble(
              key: ValueKey(message.messageId ?? message.clientMsgId),
              message: message,
            ),
            // ignore: unreachable_switch_case
            _ => const SizedBox.shrink(),
          };
        },
        childCount: flatItems.length + (hasMore ? 1 : 0),
        keepPosition: true,
      ),
    );
  }

  /// 滚动到底部（即 index 0，因为列表是 reverse 的）
  ///
  /// [animated] 是否使用动画，默认为 true
  void _scrollToBottom({bool animated = true}) {
    if (!_listViewController.hasClients) return;
    final activeId = ref.read(activeRoomIdProvider);
    final messageCount = ref.read(chatMessagesProvider)[activeId]?.length ?? 0;
    // 如果没消息直接返回
    if (messageCount == 0 || messageCount < 10) return;
    if (animated) {
      _listViewController.sliverController.animateToIndex(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _listViewController.sliverController.jumpToIndex(0);
    }
  }
}
