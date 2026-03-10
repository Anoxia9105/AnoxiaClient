import 'package:anoxia/gen/assets.gen.dart';
import 'package:anoxia/pages/chat/component/widget/ChatAppBar.dart';
import 'package:anoxia/pages/chat/component/widget/ChatInputField.dart';
import 'package:anoxia/pages/chat/component/widget/ChatMessageBubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
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

  /// 消息列表的 padding，用于在消息气泡周围添加空白
  final bodyPadding = 50.00;

  @override
  Widget build(BuildContext context) {
    final activeId = ref.watch(activeRoomIdProvider);
    final entryTask = ref.watch(roomEntryTaskProvider(activeId ?? ''));

    //监听这个房间是否有更多消息
    final hasMore = ref.watch(
      chatHasMoreProvider.select((map) => map[activeId] ?? false),
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

    final room = ref.read(activeRoomProvider);

    if (room?.roomStatus == 2) {
      return Scaffold(
        appBar: AppBar(title: Text("${room?.roomName}")),
        drawerScrimColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //程序log
              Assets.images.appIconPng.image(width: 100, height: 100),
              Text("chat_room_banned".tr()),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: entryTask.isLoading ? AppBar() : ChatAppBar(),
      drawerScrimColor: Colors.transparent,
      body: entryTask.when(
        data: (_) {
          //消息为空
          if (messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedMessage01),
                  Text("chat_no_messages".tr()),
                ],
              ),
            );
          }

          //消息渲染
          return FlutterListView(
            controller: _listViewController,
            reverse: true,
            delegate: FlutterListViewDelegate(
              (context, index) {
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

                final msg = messages[messages.length - 1 - index];

                return ChatMessageBubble(
                  key: ValueKey(msg.messageId),
                  message: msg,
                );
              },
              childCount: messages.length + (hasMore ? 1 : 0),
              // 开启 keepPosition: true
              // 这能保证在分页加载旧消息时，滚动位置不会跳动
              keepPosition: true,
            ),
          );
        },
        error: (err, _) =>
            Center(child: Text('chat_initialization_failed'.tr() + ': $err')),
        loading: () {
          return Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: _showScrollDownButton
          ? SizedBox(
              width: 35,
              height: 35,
              child: IconButton(
                onPressed: _scrollToBottom,
                icon: HugeIcon(icon: HugeIcons.strokeRoundedCircleArrowDown02),
              ),
            )
          : null,

      bottomNavigationBar: entryTask.isLoading
          ? SizedBox.shrink()
          : Padding(
              padding: EdgeInsets.only(left: bodyPadding, right: bodyPadding, bottom: 10),
              child: () {
                if (room != null) {
                  if (room.roomStatus == 0) {
                    return ChatInputField(
                      bottomSheet: () => _scrollToBottom(animated: true),
                    );
                  }
                  if (room.roomStatus == 1)
                    return _bottomRoomStatus('chat_room_muted'.tr());
                  if (room.roomStatus == 2)
                    return _bottomRoomStatus('chat_room_banned_status'.tr());
                  if (room.roomStatus == 3)
                    return _bottomRoomStatus('chat_room_dissolved'.tr());

                  return SizedBox.shrink();
                }
              }(),
            ),
    );
  }

  Widget _bottomRoomStatus(String text) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          width: 1,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 滚动到底部（即 index 0）
  void _scrollToBottom({bool animated = true}) {
    if (!_listViewController.hasClients) return;
    final activeId = ref.read(activeRoomIdProvider);
    final messageCount = ref.read(chatMessagesProvider)[activeId]?.length ?? 0;
    print(messageCount);
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
