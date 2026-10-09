import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/local_cache/database.dart';
import 'package:anoxia/framework/local_cache/local_data_source.dart';
import 'package:anoxia/framework/local_cache/remote_data_source.dart';
import 'package:anoxia/framework/local_cache/sync_repository.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _Connected implements Connectivity {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [
    ConnectivityResult.wifi,
  ];
}

class _Remote extends RemoteDataSource {
  List<({int id, String messageId})> recalls = [];
  List<ChatMessage> messages = [];
  List<ChatRoomVO> rooms = [];
  bool failRecalls = false;
  bool failRooms = false;

  @override
  Future<List<({int id, String messageId})>> fetchRecalls(
    String roomId,
    int afterId,
  ) async {
    if (failRecalls) throw StateError('recall service unavailable');
    return recalls.where((r) => r.id > afterId).take(100).toList();
  }

  @override
  Future<List<ChatRoomVO>?> fetchConversations({DateTime? since}) async {
    if (failRooms) throw StateError('offline');
    return rooms;
  }

  @override
  Future<List<ChatMessage>> fetchMessages(
    String convId, {
    DateTime? since,
    int? lastSeq,
    int? beforeSeq,
    int pageSize = 100,
  }) async => messages
      .where((m) => (m.seq ?? 0) > (lastSeq ?? 0))
      .take(pageSize)
      .toList();
}

ChatMessage _message(
  String id,
  int seq, {
  DeliveryStatus status = DeliveryStatus.sent,
}) => ChatMessage(
  messageId: id,
  clientMsgId: 'client-$id',
  roomId: 'room',
  senderId: 1,
  messageType: MessageType.text,
  content: id,
  seq: seq,
  timestamp: 1700000000000 + seq * 1000,
  deliveryStatus: status,
);

void main() {
  late AppDatabase db;
  late LocalDataSource local;
  late _Remote remote;
  late SyncRepository repository;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    local = LocalDataSource(db);
    remote = _Remote();
    repository = SyncRepository(
      local: local,
      remote: remote,
      connectivity: _Connected(),
    );
  });
  tearDown(() => db.close());

  test('主动同步会话失败可重试，后台同步仍容错', () async {
    remote.failRooms = true;
    await expectLater(
      repository.syncConversations(throwOnError: true),
      throwsStateError,
    );
    await repository.syncConversations();
    remote.failRooms = false;
    await repository.syncConversations(throwOnError: true);
  });

  test('离线撤回分页补偿删除缓存消息并阻止晚到消息复活', () async {
    await local.upsertMessage(_message('cached', 1));
    remote.recalls = [
      (id: 1, messageId: 'cached'),
      for (var i = 2; i <= 101; i++) (id: i, messageId: 'recalled-$i'),
    ];
    remote.messages = [_message('recalled-101', 2), _message('visible', 3)];
    await repository.syncMessages('room');
    expect(
      (await local.getMessagesForConversation('room')).map((m) => m.messageId),
      ['visible'],
    );
    await local.upsertMessages([_message('recalled-100', 4)]);
    expect(
      (await local.getMessagesForConversation('room')).map((m) => m.messageId),
      ['visible'],
    );
    expect(await local.messageSyncWatermark('room'), 3);
  });

  test('撤回接口失败时仍恢复普通消息', () async {
    remote.failRecalls = true;
    remote.messages = [_message('visible', 1)];
    await repository.syncMessages('room');
    expect(await local.getMessageById('visible'), isNotNull);
    expect(await local.messageSyncWatermark('room'), 1);
  });

  test('远端摘要时间回退仍合并房间资料和已读状态', () async {
    await local.upsertConversation(
      ChatRoomVO(
        roomId: 'room',
        roomName: '旧资料',
        lastReadSeq: 1,
        lastMessage: _message('new', 4),
      ),
    );
    remote.rooms = [
      ChatRoomVO(
        roomId: 'room',
        roomName: '新资料',
        roomDescription: '新公告',
        lastReadSeq: 3,
        unreadCount: 1,
        lastMessage: _message('old', 2),
      ),
    ];
    await repository.syncConversations();
    final room = (await local.getConversations()).single;
    expect(room.roomName, '新资料');
    expect(room.roomDescription, '新公告');
    expect(room.lastReadSeq, 3);
    expect(room.lastMessage!.messageId, 'new');
  });

  test('待服务端确认的较新已读游标不被旧响应覆盖', () async {
    await local.upsertConversation(
      ChatRoomVO(
        roomId: 'room',
        lastReadSeq: 1,
        lastMessage: _message('new', 4),
      ),
    );
    await local.queueReadCursor('room', 4);
    remote.rooms = [
      ChatRoomVO(
        roomId: 'room',
        lastReadSeq: 2,
        unreadCount: 2,
        lastMessage: _message('old', 2),
      ),
    ];
    await repository.syncConversations();
    final room = (await local.getConversations()).single;
    expect(room.lastReadSeq, 4);
    expect(room.unreadCount, 0);
    expect(await local.pendingReadCursors(), {'room': 4});
  });

  test('永久发送失败不自动重放但手动重试可重新排队', () async {
    await repository.cacheLocalMessage(
      _message('outgoing', 0, status: DeliveryStatus.sending),
    );
    await local.markOutgoingTerminal('outgoing');
    expect(await local.pendingOutgoingMessages(), isEmpty);
    await repository.cacheLocalMessage(
      _message('outgoing', 0, status: DeliveryStatus.sending),
    );
    expect(
      (await local.pendingOutgoingMessages()).single.messageId,
      'outgoing',
    );
  });

  test('晚到房间列表不能覆盖已经落库的较新消息摘要', () async {
    await local.upsertMessage(_message('local-new', 11));
    remote.rooms = [
      ChatRoomVO(
        roomId: 'room',
        roomName: '新名称',
        lastMessage: _message('remote-old', 10),
      ),
    ];
    await repository.syncConversations();
    final room = (await local.getConversations()).single;
    expect(room.lastMessage!.messageId, 'local-new');
    expect(room.lastMessage!.seq, 11);
    expect(room.roomName, '新名称');
  });

  test('房间列表同步不能恢复本地已删除消息的摘要', () async {
    await local.upsertMessage(_message('previous', 10));
    await local.upsertMessage(_message('deleted', 11));
    await local.deleteMessage('deleted');
    remote.rooms = [
      ChatRoomVO(roomId: 'room', lastMessage: _message('deleted', 11)),
    ];
    await repository.syncConversations();
    final room = (await local.getConversations()).single;
    expect(room.lastMessage!.messageId, 'previous');
    expect(room.lastMessage!.seq, 10);
    expect(
      (await local.getMessagesForConversation('room')).map((m) => m.messageId),
      ['previous'],
    );
  });
}
