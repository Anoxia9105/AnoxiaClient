import 'package:anoxia/pages/chat/component/widget/ChatAppBar.dart';
import 'package:anoxia/pages/chat/component/widget/ChatInputField.dart';
import 'package:anoxia/pages/chat/component/widget/ChatMessageBubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../framework/provider/chat/message/room_message_service.dart';
import '../../../framework/provider/chat/room/room_list_service.dart';

class ChatRoomDetail extends ConsumerStatefulWidget {
  const ChatRoomDetail({super.key});

  @override
  ConsumerState<ChatRoomDetail> createState() => _ChatRoomDetailState();
}

class _ChatRoomDetailState extends ConsumerState<ChatRoomDetail> {
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
      if (currentMessages.length >= 10 &&
          maxVisibleIndex >= currentMessages.length - 5) {
        ref.read(chatMessagesProvider.notifier).loadMoreHistory(activeId);
      }
    };
  }

  @override
  void dispose() {
    _listViewController.dispose();
    super.dispose();
  }

  final bodyPadding = 50.00;

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

    //当房间 ID 改变时，重置滚动按钮状态
    ref.listen<String?>(activeRoomIdProvider, (previous, next) {
      if (previous != next) {
        setState(() {
          _showScrollDownButton = false;
        });
      }
    });

    return Scaffold(
      appBar: ChatAppBar(),
      drawerScrimColor: Colors.transparent,
      body: entryTask.when(
        data: (_) {
          return FlutterListView(
            controller: _listViewController,
            reverse: true,
            delegate: FlutterListViewDelegate(
              (context, index) {
                print("message hasMore：$hasMore");
                //如果还有更多消息，且当前是最后一个消息
                if (messages.isNotEmpty &&
                    hasMore &&
                    index == messages.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (index < 0 || index >= messages.length) {
                  return const SizedBox.shrink();
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
              // 开启 keepPosition: true
              // 这能保证在分页加载旧消息时，滚动位置不会跳动
              keepPosition: true,

              // 性能优化：给一个大概的预估高度
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
              elevation: 1,
              onPressed: () => _scrollToBottom(animated: true),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedCircleArrowDown02,
                size: 20,
                strokeWidth: 2,
              ),
            )
          : null,

      bottomNavigationBar: entryTask.isLoading
          ? SizedBox.shrink()
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: bodyPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChatInputField(
                    bottomSheet: () => _scrollToBottom(animated: true),
                  ),
                  SizedBox(height: 28),
                  /* Container(
                    height: 28, // 桌面端状态栏通常很窄
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: Colors.greenAccent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "已连接到 http://8.137.14.21:7880",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        // 中间：快捷键提示（淡淡的显示）
                        Text(
                          "Enter 发送 / Shift+Enter 换行",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                        const Spacer(),
                        // 右侧：延迟和版本
                        // Icon(Icons.speed, size: 14, color: Colors.grey[400]),
                        // const SizedBox(width: 4),
                        // Text(
                        //   "42ms",
                        //   style: TextStyle(
                        //     fontSize: 11,
                        //     color: Colors.grey[600],
                        //   ),
                        // ),
                        // const SizedBox(width: 12),
                        Text(
                          "v1.0.2-alpha",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),*/
                ],
              ),
            ),
    );
  }

  /// 滚动到底部（即 index 0）
  void _scrollToBottom({bool animated = true}) {
    if (!_listViewController.hasClients) return;
    final activeId = ref.read(activeRoomIdProvider);
    final messageCount = ref.read(chatMessagesProvider)[activeId]?.length ?? 0;
    // 如果没消息，滚个寂寞，直接返回
    if (messageCount == 0) return;
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
