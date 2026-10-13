import 'dart:async';

import 'package:anoxia/domain/models/chat_effect_rule.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';

class ChatEffectEvent {
  const ChatEffectEvent({
    required this.roomId,
    required this.rule,
    required this.observedAt,
  });

  final String roomId;
  final ChatEffectRule rule;

  /// 保留网络事件最初到达时间，不能用异步落库结束时间替代。
  final DateTime observedAt;
}

/// 不可重放的视觉事件总线；不持久化特效、不改变消息投递状态。
class ChatEffectDispatcher {
  ChatEffectDispatcher({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const cooldown = Duration(seconds: 8);
  static const freshness = Duration(seconds: 15);
  static const _aliasTtl = Duration(minutes: 10);
  final DateTime Function() _clock;
  final _events = StreamController<ChatEffectEvent>.broadcast(sync: true);
  final _aliases = <(String, String), DateTime>{};
  final _lastPlayed = <String, DateTime>{};

  Stream<ChatEffectEvent> get events => _events.stream;

  void offer(ChatMessage message, {required DateTime observedAt}) {
    if (_events.isClosed || message.deliveryStatus != DeliveryStatus.sent) {
      return;
    }
    final roomId = message.roomId;
    if (roomId == null || roomId.isEmpty) return;
    final now = _clock();
    _aliases.removeWhere((_, time) => now.difference(time) > _aliasTtl);
    final keys = <(String, String)>[
      if (message.messageId?.isNotEmpty == true)
        (roomId, 'm:${message.messageId}'),
      if (message.clientMsgId?.isNotEmpty == true)
        (roomId, 'c:${message.clientMsgId}'),
      // 与入站缓存相同，缺少 ID 时使用稳定序号，不用正文或列表下标。
      if (message.messageId?.isNotEmpty != true &&
          message.clientMsgId?.isNotEmpty != true &&
          (message.seq ?? 0) > 0)
        (roomId, 's:${message.senderId}:${message.seq}'),
    ];
    if (keys.isEmpty) return;
    final duplicate = keys.any(_aliases.containsKey);
    // 重复事件也注册新别名，兼容 ACK 与回显任何先后顺序。
    for (final key in keys) {
      _aliases.putIfAbsent(key, () => now);
    }
    while (_aliases.length > 1024) {
      _aliases.remove(_aliases.keys.first);
    }
    if (duplicate) return;
    final timestamp = message.timestamp;
    if (timestamp == null) return;
    final age = now.millisecondsSinceEpoch - timestamp;
    if (age > freshness.inMilliseconds || age < -5000) return;
    if (now.difference(observedAt) > freshness) return;
    final rule = matchChatEffect(message);
    if (rule == null) return;
    _events.add(
      ChatEffectEvent(roomId: roomId, rule: rule, observedAt: observedAt),
    );
  }

  /// 可见页面确认能播放后才占用冷却；隐藏页不会影响后来真实的新消息。
  bool claim(ChatEffectEvent event) {
    if (_events.isClosed) return false;
    final now = _clock();
    if (now.difference(event.observedAt) > freshness) return false;
    final previous = _lastPlayed[event.roomId];
    if (previous != null && now.difference(previous) < cooldown) return false;
    _lastPlayed.remove(event.roomId);
    _lastPlayed[event.roomId] = now;
    while (_lastPlayed.length > 128) {
      _lastPlayed.remove(_lastPlayed.keys.first);
    }
    return true;
  }

  void dispose() {
    unawaited(_events.close());
    _aliases.clear();
    _lastPlayed.clear();
  }
}
