import 'dart:async';

import 'package:anoxia/domain/repositories/chat_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../domain/chat_message.dart';
import '../domain/chat_room_vo.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import '../protocol/message/message_enum.dart';
import 'local_data_source.dart';
import 'remote_data_source.dart';

class SyncRepository implements ChatRepository {
  SyncRepository({
    required LocalDataSource local,
    required RemoteDataSource remote,
    Connectivity? connectivity,
  }) : _local = local,
       _remote = remote,
       _connectivity = connectivity ?? Connectivity();

  final LocalDataSource _local;
  final RemoteDataSource _remote;
  final Connectivity _connectivity;

  /// 正在进行的 syncConversations Future（去重用）
  Future<void>? _syncConversationsInflight;

  /// 正在进行的 syncMessages Future，按 convId 去重
  final Map<String, Future<void>> _syncMessagesInflight = {};

  @override
  Stream<List<ChatRoomVO>> watchConversations() {
    return _local.watchConversations();
  }

  @override
  Stream<List<ChatMessage>> watchMessages(
    String convId, {
    int? limit = 50,
    int offset = 0,
  }) {
    return _local.watchMessagesForConversation(
      convId,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<List<ChatRoomVO>> getConversations({bool sync = true}) async {
    final localRooms = await _local.getConversations();
    if (sync) unawaited(syncConversations());
    return localRooms;
  }

  @override
  Future<List<ChatMessage>> getMessagesForConversation(
    String convId, {
    int limit = 50,
    int offset = 0,
    int? beforeSeq,
    bool sync = true,
  }) async {
    final localMessages = await _local.getMessagesForConversation(
      convId,
      limit: limit,
      offset: offset,
      beforeSeq: beforeSeq,
    );
    if (sync) unawaited(syncMessages(convId));
    return localMessages;
  }

  @override
  Future<void> syncConversations() {
    // 已有正在进行的同步，直接复用，避免并发重复请求
    return _syncConversationsInflight ??= _doSyncConversations().whenComplete(
      () => _syncConversationsInflight = null,
    );
  }

  Future<void> _doSyncConversations() async {
    if (!await _hasNetwork()) return;

    try {
      final since = await _local.latestConversationUpdatedAt();
      final remoteRooms = await _remote.fetchConversations(since: since);
      // 服务端响应异常（null）时不视为「用户无房间」，跳过合并与对账，
      // 避免用一次错误响应把本地缓存清空。
      if (remoteRooms == null) return;
      await _mergeConversations(remoteRooms);
      await _local.updateSyncState(
        scope: 'conversations',
        lastSyncedAt: DateTime.now(),
      );
    } catch (e, st) {
      debugLog('syncConversations failed', e, st);
      await _local.logSyncFailure(
        scope: 'conversations',
        action: 'syncConversations',
        error: e,
      );
    }
  }

  @override
  Future<void> syncMessages(String convId, {DateTime? since}) {
    // 同一会话已在同步中，直接复用，避免并发重复请求
    return _syncMessagesInflight[convId] ??= _doSyncMessages(convId)
        .whenComplete(() {
          // 注意：不能写成 `return _syncMessagesInflight.remove(convId)`。
          // remove 返回被移除的 future 自身，而 whenComplete 会等待回调返回的
          // Future 完成，等于「未来等待自己」，导致该 future 永不完成。
          _syncMessagesInflight.remove(convId);
        });
  }

  Future<void> _doSyncMessages(String convId) async {
    if (!await _hasNetwork()) return;

    try {
      var lastSeq = await _local.messageSyncWatermark(convId);
      var maxSeq = lastSeq;

      // 循环拉取：服务端单次最多返回 pageSize(≤100) 条。若会话积压超过一页，
      // 连续拉取直至追平，避免「一次进房只同步一批，中间消息缺失」。
      while (true) {
        final remoteMessages = await _remote.fetchMessages(
          convId,
          lastSeq: lastSeq,
        );
        if (remoteMessages.isEmpty) break;
        await _local.upsertMessages(remoteMessages);
        final orderedSeqs =
            remoteMessages
                .map((message) => message.seq ?? 0)
                .where((seq) => seq > lastSeq)
                .toList()
              ..sort();
        if (orderedSeqs.isEmpty) break;
        // 响应是服务端单条 SQL 的连续区间，区间内所有 seq 均已落库；
        // 即便窗口内存在空洞（被撤回/硬删除的消息行，服务端永久缺失），
        // 直接跳到响应最大 seq 也不会丢数据，又能避免水位卡死在空洞处。
        maxSeq = orderedSeqs.last;
        lastSeq = maxSeq;
        if (remoteMessages.length < 100) break;
      }

      await _local.updateSyncState(
        scope: 'messages',
        scopeId: convId,
        lastSyncedAt: DateTime.now(),
        lastSeq: maxSeq,
      );
    } catch (e, st) {
      debugLog('syncMessages failed: $convId', e, st);
      await _local.logSyncFailure(
        scope: 'messages',
        scopeId: convId,
        action: 'syncMessages',
        error: e,
      );
    }
  }

  @override
  Future<void> cacheIncomingMessage(ChatMessage message) async {
    await _local.upsertMessage(
      message.copyWith(deliveryStatus: DeliveryStatus.sent),
    );
  }

  @override
  Future<void> cacheLocalMessage(ChatMessage message) {
    return _local.upsertMessage(message);
  }

  @override
  Future<void> onNetworkRecovered() async {
    await syncConversations();
    // 待发送消息由 WebSocket 建连成功后统一重编码为 V6 ClientFrame 并重放。
    // 这里不能再通过 REST 发送，否则会绕过 V6 request_id/ACK 幂等链路。
  }

  Future<void> _mergeConversations(List<ChatRoomVO> remoteRooms) async {
    final localRooms = await _local.getConversations();
    final localById = {
      for (final room in localRooms)
        if (room.roomId != null) room.roomId!: room,
    };

    final merged = <ChatRoomVO>[];
    for (final remote in remoteRooms) {
      final id = remote.roomId;
      if (id == null) continue;
      final local = localById[id];
      if (local == null) {
        merged.add(remote);
        continue;
      }

      final localUpdated = _roomVersion(local);
      final remoteUpdated = _roomVersion(remote);
      if (remoteUpdated == null ||
          localUpdated == null ||
          remoteUpdated.isAfter(localUpdated) ||
          remoteUpdated.isAtSameMomentAs(localUpdated)) {
        merged.add(
          remote.copyWith(
            unreadCount: remote.unreadCount ?? local.unreadCount,
            lastReadSeq: remote.lastReadSeq ?? local.lastReadSeq,
          ),
        );
      } else {
        merged.add(local);
      }
    }
    await _local.upsertConversations(merged);
    // 对账：服务端 /chat/rooms 是完整的权威列表，本地多余的行
    //（残留账号数据 / 已退群被移除房间 / 非成员 stub 行）
    // 一律清除，否则它们会一直出现在聊天列表。
    final remoteIds = remoteRooms
        .map((r) => r.roomId)
        .whereType<String>()
        .toList();
    await _local.deleteConversationsNotIn(remoteIds);
  }

  DateTime? _roomVersion(ChatRoomVO room) {
    final lastTimestamp = room.lastMessage?.timestamp;
    if (lastTimestamp != null && lastTimestamp > 0) {
      return DateTime.fromMillisecondsSinceEpoch(lastTimestamp);
    }
    return room.createdAt;
  }

  Future<bool> _hasNetwork() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}
