import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_service.dart';
import 'package:anoxia/framework/provider/chat/message/room_message_ui_item_service.dart';

import '../../models/message_item.dart';

/// 聊天消息列表滚动控制器
///
/// 封装了消息列表的滚动相关逻辑，包括：
/// - 滚动到底部
/// - 滚动到指定消息（引用跳转，目标不在窗口时先补拉历史再跳转）
/// - 历史消息边缘检测（像素级阈值）
/// - 历史加载触发调度
///
/// Web 与原生统一使用 flutter_list_view 的 [FlutterListViewController]，
/// 按 index 精确滚动（消息高度不一，不能用偏移线性插值估算）。
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

  /// 引用跳转补拉历史的页数上限：窗口上限 1000 / 每页 50，从初始 100 起最多约 18 页
  static const int _maxHistoryLoadPages = 20;

  /// 补拉历史后等待 drift 流推送新窗口快照的轮询次数。
  /// drift 查询流异步推送（web 端数据库跑在 worker 中，延迟更明显），
  /// 需要短暂轮询等窗口扩大后再判定目标是否已进入窗口。
  static const int _windowPollRetries = 10;

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
      // 避免"点击跳转底部无反应"；已稳定但确实为空则直接返回。
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

  /// 跳转到指定消息（引用跳转入口）。
  ///
  /// 目标消息不在当前加载窗口时，先循环补拉历史直到目标出现；
  /// 补拉结束仍找不到（消息已撤回/删除或超出窗口上限）则 Toast 提示。
  Future<void> jumpToMessage(String messageId) async {
    var items = ref.read(chatUiListProvider(roomId)).items;
    if (_indexOfMessage(items, messageId) >= 0) {
      scrollToMessage(messageId, items);
      return;
    }

    for (var page = 0; page < _maxHistoryLoadPages; page++) {
      if (!(ref.read(chatHasMoreProvider)[roomId] ?? false)) break;
      await ref.read(chatMessagesProvider.notifier).loadMoreHistory(roomId);

      // drift 流推送新窗口快照有延迟，轮询等待窗口扩大后再判定。
      var prevLength = items.length;
      var windowGrew = false;
      for (var i = 0; i < _windowPollRetries; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        items = ref.read(chatUiListProvider(roomId)).items;
        if (items.length != prevLength) {
          windowGrew = true;
          break;
        }
      }

      final index = _indexOfMessage(items, messageId);
      if (index >= 0) {
        scrollToMessage(messageId, items);
        return;
      }
      if (!windowGrew) break;
    }

    Toast.showToast('chat_jump_message_not_found'.tr());
  }

  /// 滚动到指定消息（按索引精确跳转，Web 与原生一致）
  void scrollToMessage(String messageId, List<ChatListItem> flatItems) {
    if (!listViewController.hasClients) return;

    final index = _indexOfMessage(flatItems, messageId);
    if (index < 0) return;
    final indexedController = listViewController as FlutterListViewController;
    indexedController.sliverController.animateToIndex(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  int _indexOfMessage(List<ChatListItem> flatItems, String messageId) {
    return flatItems.indexWhere((item) {
      return switch (item) {
        MessageItem(:final message) =>
          message.messageId == messageId || message.clientMsgId == messageId,
        _ => false,
      };
    });
  }
}
