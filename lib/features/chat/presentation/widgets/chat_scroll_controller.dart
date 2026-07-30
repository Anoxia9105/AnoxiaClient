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
  final FlutterListViewController listViewController;
  final String roomId;
  final WidgetRef ref;
  final void Function() onChanged;

  /// 是否显示滚动到底部按钮
  bool _showScrollDownButton = false;
  bool get showScrollDownButton => _showScrollDownButton;

  bool _historyEdgeArmed = true;
  bool _historyLoadScheduled = false;

  ChatScrollController({
    required this.listViewController,
    required this.roomId,
    required this.ref,
    required this.onChanged,
  });

  /// 设置滚动监听，检测历史消息边缘并触发加载
  void setupScrollListeners() {
    listViewController.addListener(_onScrollOffsetChanged);

    listViewController.sliverController.onPaintItemPositionsCallback =
        (height, positions) {
          _onPaintItemPositions(height, positions);
        };
  }

  void _onScrollOffsetChanged() {
    final bool isFarFromBottom = listViewController.offset > 300;
    if (isFarFromBottom != _showScrollDownButton) {
      _showScrollDownButton = isFarFromBottom;
      onChanged();
    }
  }

  void _onPaintItemPositions(
    double height,
    List positions,
  ) {
    if (positions.isEmpty) return;
    if (roomId.isEmpty) return;

    // 像素级边缘检测：当可见区域底部接近内容顶部 2 倍视口高度时触发
    // positions 中最大 trailing 对应最靠近历史边缘的 item
    double maxTrailing = 0;
    for (final p in positions) {
      final trailing = (p as dynamic).itemTrailing as double? ?? 0;
      if (trailing > maxTrailing) maxTrailing = trailing;
    }
    final nearHistoryEdge = maxTrailing > height * 2;

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
    final messages =
        ref.read(roomMessagesProvider(roomId)).value ?? const [];
    if (messages.isEmpty) return;

    if (animated) {
      listViewController.sliverController.animateToIndex(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      listViewController.sliverController.jumpToIndex(0);
    }
  }

  /// 滚动到指定消息
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
    listViewController.sliverController.animateToIndex(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }
}