// 房间消息表情回应内存态
//
// 回应不占消息 seq、不进同步 backlog，也不落 drift 表：
// - 进房时按当前消息窗口 REST 补拉一次（`syncRoomMessages` 后触发）；
// - 房间广播 ReactionEvent 实时增删聚合（含回应者本人，多端同步）；
// - 本地点击先乐观切换，ACK 失败再回滚；服务端事件与本地回声按
//   「本人已处于目标态则忽略」去重，避免重复计数。
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 单消息单 emoji 的聚合（count 总数 + mine 我是否已回应）
class RoomReactionAggregate {
  final String emoji;
  final int count;
  final bool mine;

  const RoomReactionAggregate({
    required this.emoji,
    required this.count,
    required this.mine,
  });

  RoomReactionAggregate copyWith({int? count, bool? mine}) =>
      RoomReactionAggregate(
        emoji: emoji,
        count: count ?? this.count,
        mine: mine ?? this.mine,
      );
}

/// 一个房间全部消息的回应聚合：messageId → emoji → aggregate
class RoomReactionBoard {
  final Map<String, Map<String, RoomReactionAggregate>> byMessage;

  const RoomReactionBoard(this.byMessage);
}

/// 每房间内最多保留的消息数（超出按插入序淘汰最旧，防长会话无限增长）
const int _maximumMessagesPerRoom = 500;

final roomChatReactionsProvider =
    NotifierProvider<RoomChatReactions, Map<String, RoomReactionBoard>>(
      RoomChatReactions.new,
    );

class RoomChatReactions extends Notifier<Map<String, RoomReactionBoard>> {
  @override
  Map<String, RoomReactionBoard> build() => const {};

  /// 服务端 ReactionEvent 统一入口（广播 + 本人回声共用）。
  ///
  /// 幂等去重：本人已处于目标态（mine 与事件方向一致）时视为回声，不再计数。
  /// 其它用户的变更始终生效；isRemove 会把计数减到 0 时整组移除。
  void applyEvent({
    required String roomId,
    required String messageId,
    required String emoji,
    required bool isRemove,
    required int senderUserId,
    required int? currentUserId,
  }) {
    if (roomId.isEmpty ||
        messageId.isEmpty ||
        emoji.isEmpty) {
      return;
    }
    final current = state[roomId] ?? const RoomReactionBoard({});
    final groups = {
      ...?current.byMessage[messageId],
    };
    final agg = groups[emoji];

    if (isRemove) {
      if (agg == null) return;
      final fromMe = senderUserId == currentUserId;
      if (fromMe && !agg.mine) return; // 本地删除的回声
      final nextCount = agg.count - 1;
      if (nextCount <= 0) {
        groups.remove(emoji);
      } else {
        groups[emoji] = agg.copyWith(
          count: nextCount,
          mine: fromMe ? false : agg.mine,
        );
      }
    } else {
      if (agg == null) {
        groups[emoji] = RoomReactionAggregate(
          emoji: emoji,
          count: 1,
          mine: senderUserId == currentUserId,
        );
      } else {
        final fromMe = senderUserId == currentUserId;
        if (fromMe && agg.mine) return; // 本地添加的回声
        groups[emoji] = agg.copyWith(
          count: agg.count + 1,
          mine: agg.mine || fromMe,
        );
      }
    }

    state = {...state, roomId: _mergeRoom(current, messageId, groups)};
  }

  /// REST 补拉覆盖：以本次请求窗口为准整体重设，被窗口覆盖的消息
  /// 即使服务端已无回应也会被清干净（离线期间他人撤销的场景）。
  void replaceWindow(
    String roomId,
    List<String> messageIds,
    List<({
      String messageId,
      String emoji,
      int count,
      bool mine,
    })>
    rows,
  ) {
    if (roomId.isEmpty || messageIds.isEmpty) return;
    final window = messageIds.toSet();
    final grouped = <String, Map<String, RoomReactionAggregate>>{};
    for (final row in rows) {
      if (!window.contains(row.messageId) ||
          row.messageId.isEmpty ||
          row.emoji.isEmpty ||
          row.count <= 0) {
        continue;
      }
      grouped.putIfAbsent(row.messageId, () => {});
      grouped[row.messageId]![row.emoji] = RoomReactionAggregate(
        emoji: row.emoji,
        count: row.count,
        mine: row.mine,
      );
    }
    final current = state[roomId] ?? const RoomReactionBoard({});
    var next = current.byMessage;
    var changed = false;
    for (final messageId in window) {
      final incoming = grouped[messageId];
      final existing = current.byMessage[messageId];
      if (existing != null && existing.isNotEmpty && incoming == null) {
        next = {...next}..remove(messageId);
        changed = true;
      } else if (incoming != null) {
        if (_sameGroups(existing ?? const {}, incoming)) continue;
        next = {...next, messageId: incoming};
        changed = true;
      }
    }
    if (!changed) return;
    state = {...state, roomId: RoomReactionBoard(next)};
  }

  /// 本地点击乐观切换：mine=true → 撤销；mine=false → 添加。
  /// 返回切换后的 mine 态；发送失败时再次调用即可精确还原本次前的聚合。
  bool toggleLocal(String roomId, String messageId, String emoji) {
    if (roomId.isEmpty || messageId.isEmpty || emoji.isEmpty) return false;
    final current = state[roomId] ?? const RoomReactionBoard({});
    final groups = {...?current.byMessage[messageId]};
    final agg = groups[emoji];
    final resultingMine = agg == null || !agg.mine;
    if (agg == null) {
      if (!resultingMine) return false;
      groups[emoji] = RoomReactionAggregate(
        emoji: emoji,
        count: 1,
        mine: true,
      );
    } else if (resultingMine) {
      groups[emoji] = agg.copyWith(count: agg.count + 1, mine: true);
    } else {
      final nextCount = agg.count - 1;
      if (nextCount <= 0) {
        groups.remove(emoji);
      } else {
        groups[emoji] = agg.copyWith(count: nextCount, mine: false);
      }
    }
    state = {...state, roomId: _mergeRoom(current, messageId, groups)};
    return resultingMine;
  }

  /// 会话删除/登出时清理，防止 keepAlive 状态越积越多
  void clear(String roomId) {
    if (!state.containsKey(roomId)) return;
    final next = {...state}..remove(roomId);
    state = next;
  }

  RoomReactionBoard _mergeRoom(
    RoomReactionBoard current,
    String messageId,
    Map<String, RoomReactionAggregate> groups,
  ) {
    final byMessage = {...current.byMessage};
    if (groups.isEmpty) {
      byMessage.remove(messageId);
    } else {
      byMessage[messageId] = groups;
    }
    // 容量上限：消息数超限时按插入序淘汰最旧（Map 保持插入序）
    while (byMessage.length > _maximumMessagesPerRoom) {
      byMessage.remove(byMessage.keys.first);
    }
    return RoomReactionBoard(byMessage);
  }

  static bool _sameGroups(
    Map<String, RoomReactionAggregate> a,
    Map<String, RoomReactionAggregate> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null ||
          other.count != entry.value.count ||
          other.mine != entry.value.mine) {
        return false;
      }
    }
    return true;
  }
}

