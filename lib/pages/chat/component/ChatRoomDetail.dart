import 'package:anoxia/pages/chat/component/widget/ChatAppBar.dart';
import 'package:anoxia/pages/chat/component/widget/ChatInputField.dart';
import 'package:anoxia/pages/chat/component/widget/ChatMessageBubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../framework/services/room_list_service.dart';
import '../../../framework/services/room_message_service.dart';

class ChatRoomDetail extends ConsumerStatefulWidget {
  const ChatRoomDetail({super.key});

  @override
  ConsumerState<ChatRoomDetail> createState() => _ChatRoomDetailState();
}

class _ChatRoomDetailState extends ConsumerState<ChatRoomDetail> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterListViewController _listViewController =
      FlutterListViewController();
  bool _showScrollDownButton = false;

  @override
  void initState() {
    super.initState();

    _listViewController.addListener(() {
      // offset 为 0 代表在最底部（最新消息处）
      // 当向上滚动超过 300 像素时，显示按钮
      final bool isFarFromBottom = _listViewController.offset > 300;

      if (isFarFromBottom != _showScrollDownButton) {
        setState(() {
          _showScrollDownButton = isFarFromBottom;
        });
      }
    });

    _listViewController
        .sliverController
        .onPaintItemPositionsCallback = (widgetHeight, positions) {
      if (positions.isEmpty) return;

      final activeId = ref.read(activeRoomIdProvider);
      if (activeId == null) return;

      final currentMessages = ref.read(chatMessagesProvider)[activeId] ?? [];
      if (currentMessages.isEmpty) return;

      // 1. 找出当前可见的最大索引（在 reverse:true 中，最大索引就是最顶部的旧消息）
      int maxVisibleIndex = 0;
      for (var pos in positions) {
        if (pos.index > maxVisibleIndex) maxVisibleIndex = pos.index;
      }

      // 2. 阈值判断：如果滑到了倒数第 5 条消息
      // currentMessages.length - 1 是最顶端
      if (maxVisibleIndex >= currentMessages.length - 5) {
        // 💡 触发加载
        ref.read(chatMessagesProvider.notifier).loadMoreHistory(activeId);
      }
    };
  }

  @override
  void dispose() {
    _listViewController.dispose();
    super.dispose();
  }

  final bodyPadding = 60.00;

  @override
  Widget build(BuildContext context) {
    final activeId = ref.watch(activeRoomIdProvider);
    final entryTask = ref.watch(roomEntryTaskProvider(activeId ?? ''));
    //监听这个房间是否有更多消息
    final hasMore = ref.watch(
      chatHasMoreProvider.select((map) => map[activeId] ?? true),
    );

    final messages = ref.watch(
      chatMessagesProvider.select((map) => map[activeId] ?? []),
    );

    return Scaffold(
      key: _scaffoldKey,
      appBar: ChatAppBar(
        onTap: () {
          _scaffoldKey.currentState?.openEndDrawer();
        },
      ),
      endDrawer: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Drawer(
          width: 80.w,
          child: const Center(child: Text("成员列表")),
        ),
      ),
      body: entryTask.when(
        data: (_) {
          return FlutterListView(
            controller: _listViewController,
            reverse: true,
            delegate: FlutterListViewDelegate(
              (context, index) {
                // 💡 如果有更多数据，且到了最后一个索引，显示加载圈
                if (hasMore && index == messages.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final msg = messages[messages.length - 1 - index];

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: bodyPadding),
                  child: ChatMessageBubble(
                    key: ValueKey(msg.messageId),
                    message: msg,
                  ),
                );
              },
              childCount: messages.length + (hasMore ? 1 : 0),
              // 💡 建议开启 keepPosition: true
              // 这能保证在分页加载旧消息时，滚动位置不会跳动
              keepPosition: true,

              // 💡 性能优化：给一个大概的预估高度
              preferItemHeight: 60,
            ),
          );
        },
        error: (err, _) => Center(child: Text("初始化失败: $err")),
        loading: () {
          return Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: _showScrollDownButton
          ? FloatingActionButton.small(
              // 使用小号按钮更精致
              backgroundColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.8),
              onPressed: () {
                _listViewController.sliverController.animateToIndex(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              child: const Icon(Icons.arrow_downward, color: Colors.white),
            )
          : null,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: bodyPadding),
        child: ChatInputField(
          onSend: () {
            _scrollToBottom(animated: true);
          },
        ),
      ),
    );
  }

  /// 滚动到底部（即 index 0）
  void _scrollToBottom({bool animated = true}) {
    // 1. 安全检查：确保控制器已关联到 Widget
    if (!_listViewController.hasClients) return;

    if (animated) {
      // 💡 使用 sliverController 提供的动画接口
      _listViewController.sliverController.animateToIndex(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      // 💡 瞬移到底部
      _listViewController.sliverController.jumpToIndex(0);
    }
  }
}
