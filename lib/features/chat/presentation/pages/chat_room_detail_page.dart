import 'package:anoxia/common/utils/DateUtil.dart';
import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/SkeletonBox.dart';
import 'package:anoxia/framework/domain/ChatMessage.dart';
import 'package:anoxia/features/chat/presentation/widgets/chat_app_bar.dart';
import 'package:anoxia/features/chat/presentation/widgets/chat_input_field.dart';
import 'package:anoxia/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/room/room_list_service.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:anoxia/framework/provider/ws/ws_state.dart';

/// 展平列表的条目类型：时间分隔条 或 消息气泡
sealed class _ChatListItem {}

/// 时间分隔条条目
class _TimeDividerItem extends _ChatListItem {
  /// 时间戳（毫秒）
  final int timestamp;
  _TimeDividerItem(this.timestamp);
}

/// 消息气泡条目
class _MessageItem extends _ChatListItem {
  /// 聊天消息对象
  final ChatMessage message;
  _MessageItem(this.message);
}

/// 聊天房间详情页面
///
/// 显示房间内的消息列表、输入框、房间状态等信息
/// 支持时间分隔、滚动定位、加载更多历史消息、WebSocket连接状态显示等功能
class ChatRoomDetail extends ConsumerStatefulWidget {
  const ChatRoomDetail({super.key});

  @override
  ConsumerState<ChatRoomDetail> createState() => _ChatRoomDetailState();
}

class _ChatRoomDetailState extends ConsumerState<ChatRoomDetail> {
  /// FlutterListView 控制器，用于控制列表滚动和定位
  final FlutterListViewController _listViewController =
      FlutterListViewController();
  
  /// 是否显示滚动到底部按钮
  bool _showScrollDownButton = false;

  /// 将原始消息列表展平为 [时间分隔条 + 消息] 的混合列表
  ///
  /// 消息列表按时间升序排列（index 0 = 最旧）
  /// 规则：第一条消息强制插入时间条，之后两条消息间隔 > 30分钟才插入
  ///
  /// [messages] 原始聊天消息列表
  /// 返回 包含时间分隔条和消息的混合列表
  List<_ChatListItem> _buildFlatList(List<ChatMessage> messages) {
    final List<_ChatListItem> items = [];
    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final prevMsg = i > 0 ? messages[i - 1] : null;

      bool showTime = false;
      if (prevMsg == null) {
        // 第一条消息，强制显示时间
        showTime = true;
      } else if (msg.timestamp != null && prevMsg.timestamp != null) {
        final diff = msg.timestamp! - prevMsg.timestamp!;
        showTime = diff > 30 * 60 * 1000; // 30分钟
      }

      if (showTime && msg.timestamp != null) {
        items.add(_TimeDividerItem(msg.timestamp!));
      }
      items.add(_MessageItem(msg));
    }
    return items;
  }

  /// 构建微信风格的时间分隔 UI
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

      // 构建展平列表以获取实际 item 总数（含时间分隔条）
      final flatItems = _buildFlatList(currentMessages);

      // 1. 找出当前可见的最大索引（在 reverse:true 中，最大索引就是最顶部的旧消息）
      int maxVisibleIndex = 0;
      for (var pos in positions) {
        if (pos.index > maxVisibleIndex) maxVisibleIndex = pos.index;
      }

      // 2. 阈值判断：如果滑到了倒数第 5 个 item 附近
      if (currentMessages.length >= 10 &&
          maxVisibleIndex >= flatItems.length - 5) {
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
  ///
  /// 移动端：8.0
  /// 桌面端：50.0
  final bodyPadding = DeviceUtil.isRealMobile() ? 8.00 : 50.00;

  @override
  Widget build(BuildContext context) {
    final activeId = ref.watch(activeRoomIdProvider);
    final entryTask = activeId == null
        ? const AsyncValue<void>.data(null)
        : ref.watch(roomEntryTaskProvider(activeId));
    final wsState = ref.watch(wsControllerProvider);

    //监听这个房间是否有更多消息
    final hasMore = ref.watch(
      chatHasMoreProvider.select((map) => map[activeId] ?? false),
    );

    final messages = ref.watch(
      chatMessagesProvider.select((map) => map[activeId] ?? []),
    );
    final hasCachedMessages = messages.isNotEmpty;
    final showInitialSkeleton = entryTask.isLoading && !hasCachedMessages;

    //当房间 ID 改变时，重置滚动按钮状态
    ref.listen<String?>(activeRoomIdProvider, (previous, next) {
      if (previous != next) {
        setState(() {
          _showScrollDownButton = false;
        });
      }
    });

    final room = ref.watch(activeRoomProvider);
    final isRoomBanned = room?.roomStatus == 2;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    if (activeId == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(),
        body: Center(child: Text('chat_no_conversations'.tr())),
      );
    }

    final contentBody = showInitialSkeleton
        ? const _ChatRoomDetailSkeleton()
        : entryTask.hasError && !hasCachedMessages
        ? Center(
            child: Text(
              '${'chat_initialization_failed'.tr()}: ${entryTask.error}',
            ),
          )
        : isRoomBanned
        ? _buildBannedContentView()
        : () {
            //消息为空
            if (messages.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HugeIcon(icon: HugeIcons.strokeRoundedMessage01),
                    Text('chat_no_messages'.tr()),
                  ],
                ),
              );
            }

            //消息渲染 —— 构建展平列表（时间分隔条 + 消息气泡）
            final flatItems = _buildFlatList(messages);

            return FlutterListView(
              controller: _listViewController,
              reverse: true,
              delegate: FlutterListViewDelegate(
                (context, index) {
                  // loading indicator（加载更多历史消息）
                  if (hasMore && index == flatItems.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: SkeletonBox(width: 120, height: 12, radius: 10),
                      ),
                    );
                  }

                  /// reverse 模式下索引反转
                  final realIndex = flatItems.length - 1 - index;
                  final item = flatItems[realIndex];

                  return switch (item) {
                    _TimeDividerItem(:final timestamp) =>
                      _buildTimeDividerWidget(timestamp, context),
                    _MessageItem(:final message) => ChatMessageBubble(
                      key: ValueKey(message.messageId),
                      message: message,
                    ),
                  };
                },
                childCount: flatItems.length + (hasMore ? 1 : 0),
                keepPosition: true,
              ),
            );
          }();

    return Scaffold(
      backgroundColor: DeviceUtil.isRealDesktop()
          ? Colors.transparent
          : Theme.of(context).colorScheme.surface,
      appBar: showInitialSkeleton ? AppBar() : const ChatAppBar(),
      drawerScrimColor: Colors.transparent,
      body: Column(
        children: [
          _WsConnectionBanner(state: wsState),
          Expanded(child: contentBody),
        ],
      ),
      floatingActionButton: _showScrollDownButton
          ? SizedBox(
              width: 35,
              height: 35,
              child: IconButton(
                onPressed: _scrollToBottom,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCircleArrowDown02,
                ),
              ),
            )
          : null,

      bottomNavigationBar: showInitialSkeleton
          ? const _ChatInputSkeleton()
          : SafeArea(
              top: false,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  left: bodyPadding,
                  right: bodyPadding,
                  bottom: (keyboardInset > 0 ? keyboardInset : 0) + 10,
                ),
                child: () {
                  if (room == null) {
                    return const SizedBox.shrink();
                  }

                  return switch (room.roomStatus) {
                    0 => ChatInputField(
                      bottomSheet: () => _scrollToBottom(animated: true),
                    ),
                    1 => _bottomRoomStatusTag(
                      'chat_room_muted'.tr(),
                      icon: HugeIcons.strokeRoundedVolumeMute01,
                    ),
                    2 => const SizedBox.shrink(),
                    3 => _bottomRoomStatusTag(
                      'chat_room_dissolved'.tr(),
                      icon: HugeIcons.strokeRoundedDelete02,
                    ),
                    _ => const SizedBox.shrink(),
                  };
                }(),
              ),
            ),
    );
  }

  /// 构建房间状态标签（用于禁言、解散等状态）
  ///
  /// [text] 标签文本
  /// [icon] 标签图标（可选）
  /// 返回 房间状态标签 Widget
  Widget _bottomRoomStatusTag(String text, {dynamic icon}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          width: 1,
          color: cs.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: icon ?? HugeIcons.strokeRoundedAlert02,
            size: 16,
            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建封禁状态的内容视图
  ///
  /// 显示图标 + 标题 + 提示语
  /// 返回 封禁状态视图 Widget
  Widget _buildBannedContentView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: _buildBannedView(),
      ),
    );
  }

  /// 构建封禁状态的具体视图内容
  ///
  /// 返回 封禁状态视图内容 Widget
  Widget _buildBannedView() {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.center,
      heightFactor: 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedAlert02,
                size: 28,
                color: cs.error,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'chat_room_banned_status'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: cs.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'chat_room_banned_hint'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
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

/// WebSocket 连接状态横幅组件
///
/// 显示当前 WebSocket 连接状态（连接中、连接失败、已断开等）
class _WsConnectionBanner extends StatelessWidget {
  /// WebSocket 状态对象
  final WsState state;

  const _WsConnectionBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status == WsStatus.connected) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    final (icon, text, bg, fg) = switch (state.status) {
      WsStatus.connecting => (
        Icons.wifi_protected_setup_rounded,
        'appbar_connecting'.tr(),
        cs.primaryContainer.withValues(alpha: .7),
        cs.primary,
      ),
      WsStatus.error => (
        Icons.error_outline_rounded,
        state.error?.trim().isNotEmpty == true
            ? 'appbar_connection_lost'.tr()
            : 'appbar_connection_lost'.tr(),
        cs.errorContainer.withValues(alpha: .85),
        cs.error,
      ),
      WsStatus.disconnected => (
        Icons.portable_wifi_off_rounded,
        'appbar_connection_lost'.tr(),
        cs.errorContainer.withValues(alpha: .85),
        cs.error,
      ),
      WsStatus.connected => (
        Icons.check,
        '',
        Colors.transparent,
        Colors.transparent,
      ),
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 聊天房间详情页面骨架屏
///
/// 用于在消息加载过程中显示占位内容
class _ChatRoomDetailSkeleton extends StatelessWidget {
  const _ChatRoomDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      itemCount: 14,
      itemBuilder: (context, index) {
        final isSelf = index % 2 == 0;
        final showTime = index % 4 == 0;
        final bubbleWidth = isSelf
            ? 120.0 + (index % 3) * 34
            : 150.0 + (index % 3) * 42;
        final bubbleHeight = 34.0 + (index % 3) * 12;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              if (showTime)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: SkeletonLine(width: 84, height: 11),
                ),
              Row(
                mainAxisAlignment: isSelf
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isSelf) ...[
                    const SkeletonBox(width: 30, height: 30, circle: true),
                    const SizedBox(width: 8),
                  ],
                  SkeletonBox(
                    width: bubbleWidth,
                    height: bubbleHeight,
                    radius: 14,
                  ),
                  if (isSelf) ...[
                    const SizedBox(width: 8),
                    const SkeletonBox(width: 30, height: 30, circle: true),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 聊天输入框骨架屏
///
/// 用于在输入框加载过程中显示占位内容
class _ChatInputSkeleton extends StatelessWidget {
  const _ChatInputSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(50, 0, 50, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            width: 1,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: SkeletonBox(height: 18, radius: 9)),
                SizedBox(width: 12),
                SkeletonBox(width: 22, height: 22, circle: true),
                SizedBox(width: 8),
                SkeletonBox(width: 22, height: 22, circle: true),
              ],
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: SkeletonLine(width: 120, height: 10),
            ),
          ],
        ),
      ),
    );
  }
}
