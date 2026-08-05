import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_list_view/flutter_list_view.dart';

import '../../../../framework/provider/chat/message/room_message_service.dart';
import '../../models/message_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 聊天消息列表滚动控制器
///
/// 封装了消息列表的滚动相关逻辑，包括：
/// - 滚动到底部
/// - 滚动到指定消息（引用跳转）
/// - 历史消息边缘检测（像素级阈值）
/// - 历史加载触发调度
class ChatScrollController {
  final ScrollController listViewController;
  final String roomId;
  final WidgetRef ref;
  final void Function() onChanged;

  /// 是否显示滚动到底部按钮
  bool _showScrollDownButton = false;
  bool get showScrollDownButton => _showScrollDownButton;

  bool _historyEdgeArmed = true;
  bool _historyLoadScheduled = false;

  /// `scrollToBottom` 在消息未 settle 时的重试次数上限，
  /// 避免 provider 长时间处于 loading 时每帧无限自我调度。
  static const int _maxBottomScrollRetries = 10;
  int _bottomScrollRetries = 0;

  ChatScrollController({
    required this.listViewController,
    required this.roomId,
    required this.ref,
    required this.onChanged,
  });

  /// 设置滚动监听，检测历史消息边缘并触发加载
  void setupScrollListeners() {
    listViewController.addListener(_onScrollOffsetChanged);
  }

  void dispose() {
    listViewController.removeListener(_onScrollOffsetChanged);
  }

  void _onScrollOffsetChanged() {
    // ScrollController 未 attach（或同时 attach 了多个 position）时读取 offset
    // 会直接抛异常，房间切换的过渡帧非常容易命中，必须先守卫再取值。
    if (!listViewController.hasClients) return;

    // 滚动到底部按钮的显示/隐藏
    final bool isFarFromBottom = listViewController.offset > 300;
    if (isFarFromBottom != _showScrollDownButton) {
      _showScrollDownButton = isFarFromBottom;
      onChanged();
    }

    // 历史消息边缘检测：当滚动位置接近顶部（maxScrollExtent）时触发加载
    final maxScroll = listViewController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    final distanceToHistoryEdge = maxScroll - listViewController.offset;
    final nearHistoryEdge = distanceToHistoryEdge < 300;

    if (!nearHistoryEdge) {
      _historyEdgeArmed = true;
      return;
    }

    final hasMore = ref.read(chatHasMoreProvider)[roomId] ?? false;
    final isFetching = ref
        .read(chatMessagesProvider.notifier)
        .fetchingHistoryRoomIds
        .contains(roomId);

    if (hasMore && _historyEdgeArmed && !isFetching) {
      _historyEdgeArmed = false;
      _scheduleHistoryLoad();
    }
  }

  void _scheduleHistoryLoad() {
    if (_historyLoadScheduled) return;
    _historyLoadScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _historyLoadScheduled = false;
      unawaited(_loadMoreHistory());
    });
  }

  Future<void> _loadMoreHistory() async {
    await ref.read(chatMessagesProvider.notifier).loadMoreHistory(roomId);
  }

  /// 滚动到底部（index 0，因为列表是 reverse 的）
  void scrollToBottom({bool animated = true}) {
    if (!listViewController.hasClients) return;
    final messageState = ref.read(roomMessagesProvider(roomId));
    final messages = messageState.value ?? const [];
    final optimistic =
        ref.read(optimisticRoomMessagesProvider)[roomId] ?? const [];
    if (messages.isEmpty && optimistic.isEmpty) {
      // 仍处于加载态（.value 为 null）时，等 provider settle 后重试，
      // 避免“点击跳转底部无反应”；已稳定但确实为空则直接返回。
      if (messageState.isLoading &&
          _bottomScrollRetries < _maxBottomScrollRetries) {
        _bottomScrollRetries++;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => scrollToBottom(animated: animated),
        );
      }
      return;
    }
    _bottomScrollRetries = 0;

    // Web 与原生统一使用 flutter_list_view 的按索引跳转（精确到底）
    final indexedController = listViewController as FlutterListViewController;
    if (animated) {
      indexedController.sliverController.animateToIndex(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      indexedController.sliverController.jumpToIndex(0);
    }
  }

  /// 滚动到指定消息（按索引精确跳转，Web 与原生一致）
  void scrollToMessage(String messageId, List<ChatListItem> flatItems) {
    if (!listViewController.hasClients) return;

    final index = flatItems.indexWhere((item) {
      return switch (item) {
        MessageItem(:final message) =>
          message.messageId == messageId || message.clientMsgId == messageId,
        _ => false,
      };
    });

    if (index < 0) return;
    final indexedController = listViewController as FlutterListViewController;
    indexedController.sliverController.animateToIndex(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }
}
