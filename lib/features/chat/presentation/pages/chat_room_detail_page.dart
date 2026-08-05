import 'package:anoxia/common/utils/date_util.dart';
import 'package:anoxia/features/chat/models/message_item.dart';
import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/features/chat/presentation/pages/banned_content_page.dart';
import 'package:anoxia/features/chat/presentation/pages/empty_messages_page.dart';
import 'package:anoxia/features/chat/presentation/pages/no_conversation_page.dart';
import 'package:anoxia/features/chat/presentation/widgets/chat_scroll_controller.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/chat_room_detail_bottom_bar.dart';
import 'package:anoxia/features/chat/presentation/widgets/chatinput/chat_room_detail_scroll_down_button.dart';
import 'package:anoxia/features/chat/presentation/widgets/history_load_indicator.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_bubble/chat_message_bubble.dart';
import 'package:anoxia/features/chat/presentation/widgets/skeleton/chat_room_detail_skeleton.dart';
import 'package:anoxia/features/chat/presentation/widgets/appbar/chat_app_bar.dart';
import 'package:anoxia/features/chat/presentation/widgets/group_announcement_banner.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/provider/chat/message/reply_jump_provider.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_ui_item_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';

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
  /// flutter_list_view 的滚动控制器，支持按索引精确定位（Web 与原生一致）。
  late final ScrollController _listViewController;

  /// 滚动控制器，封装滚动相关的全部逻辑
  late ChatScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _listViewController = FlutterListViewController();
    _scrollController = ChatScrollController(
      listViewController: _listViewController,
      roomId: widget.roomId,
      ref: ref,
      onChanged: _onScrollStateChanged,
    );
    _scrollController.setupScrollListeners();
  }

  void _onScrollStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant ChatRoomDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId != widget.roomId) {
      _scrollController.dispose();
      _scrollController = ChatScrollController(
        listViewController: _listViewController,
        roomId: widget.roomId,
        ref: ref,
        onChanged: _onScrollStateChanged,
      );
      _scrollController.setupScrollListeners();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _listViewController.dispose();
    super.dispose();
  }

  /// 构建时间分隔 UI
  Widget _buildTimeDividerWidget(int timestamp, BuildContext context) {
    final locale = context.locale.languageCode;
    final text = DateUtil.formatWeChatTimeDivider(timestamp, locale);

    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRoom = ref.watch(currentRoomProvider(widget.roomId));
    if (currentRoom == null) return const NoConversationPage();

    final entryTask = ref.watch(roomEntryTaskProvider(widget.roomId));

    final chatUiListResult = ref.watch(chatUiListProvider(widget.roomId));
    final flatItems = chatUiListResult.items;

    final showInitialSkeleton = entryTask.isLoading && flatItems.isEmpty;

    // 当激活房间变化时，新 controller 会重置按钮状态

    // 引用消息跳转
    ref.listen<ReplyJumpRequest?>(replyJumpControllerProvider, (
      previous,
      next,
    ) {
      if (next == null || next.roomId != widget.roomId) return;
      _scrollController.scrollToMessage(next.messageId, flatItems);
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: showInitialSkeleton
          ? AppBar()
          : ChatAppBar(roomId: widget.roomId),
      drawerScrimColor: Colors.transparent,
      body: Column(
        children: [
          if (!showInitialSkeleton && currentRoom.roomType == 1)
            GroupAnnouncementBanner(
              roomId: widget.roomId,
              announcement: currentRoom.roomDescription ?? '',
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildChatBody(
                showInitialSkeleton: showInitialSkeleton,
                entryTask: entryTask,
                flatItems: flatItems,
                currentRoom: currentRoom,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _scrollController.showScrollDownButton
          ? ChatRoomDetailScrollDownButton(
              onPressed: () => _scrollController.scrollToBottom(animated: true),
            )
          : null,
      bottomNavigationBar: ChatRoomDetailBottomBar(
        showSkeleton: showInitialSkeleton,
        roomStatus: currentRoom.roomStatus,
        onFieldTap: () => _scrollController.scrollToBottom(animated: true),
      ),
    );
  }

  /// 集中管理聊天主体的多状态分支
  Widget _buildChatBody({
    required bool showInitialSkeleton,
    required AsyncValue<void> entryTask,
    required List<ChatListItem> flatItems,
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

    return Stack(
      children: [
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          child: _buildMessageList(flatItems),
        ),
        // 历史加载状态指示器，替换原来的内联骨架屏
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: HistoryLoadIndicator(roomId: widget.roomId),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageList(List<ChatListItem> flatItems) {
    Widget itemBuilder(BuildContext context, int index) {
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
      };
    }

    // 注意：此处刻意不使用 keepPosition: true。
    // 原因：本列表为 reverse: true 的聊天消息流，第二个房间在「切换瞬间」仍在
    // 实时加载（roomEntryTask 同步 + drift 流增量推送），childCount 会频繁变化。
    // 在 reverse + 动态 item 高度下，keepPosition 会在每次 childCount 变化时反复
    // 重算并保持滚动锚点，引发主线程布局抖动直至 ANR（表现为「第二次切换列表
    // 直接卡死、无 log」）。逆向聊天列表的正确语义本就是「停在最新消息底部」，
    // 关闭 keepPosition 后：切换/新消息到达自动停在底部，上滑看历史也不跳位，
    // 且不再触发锚点重算抖动。
    //
    // 关闭自动 keepalive：气泡本身无状态（ConsumerWidget），离屏即销毁滚回重建
    // 无成本，无需保留；RepaintBoundary 由 delegate（addRepaintBoundaries 默认
    // true）自动包，滚动时命中缓存图层、只上传不重绘。
    final list = FlutterListView(
      key: ValueKey(widget.roomId),
      controller: _listViewController as FlutterListViewController,
      reverse: true,
      delegate: FlutterListViewDelegate(
        itemBuilder,
        childCount: flatItems.length,
        keepPosition: false,
        addAutomaticKeepAlives: false,
      ),
    );

    if (!DeviceUtil.isWeb) return list;

    // Web 滚动条：Material 自动 Scrollbar 的拖拽映射在列表高度变化
    // （历史加载/新消息）时 thumb 会与鼠标脱开（框架缺陷）。这里禁用
    // 自动滚动条，改为 RawScrollbar 仅做位置指示（interactive 默认
    // false），滚动交给滚轮/触摸板/拖列表区，与微信网页版交互一致。
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(
        context,
      ).copyWith(scrollbars: false),
      child: RawScrollbar(
        controller: _listViewController,
        thumbVisibility: true,
        thickness: 6,
        radius: const Radius.circular(3),
        child: list,
      ),
    );
  }
}
