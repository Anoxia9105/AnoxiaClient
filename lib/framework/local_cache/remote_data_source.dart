// 远程数据源
//
// 通过 HTTP API 与后端交互，获取会话列表和消息历史，供本地缓存同步使用。
import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/network/dio_client.dart';

/// 远程数据源
///
/// 封装 IM 的只读 HTTP 同步 API；消息命令统一通过 V6 WebSocket 发送。
class RemoteDataSource {
  RemoteDataSource({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

  /// 每次补偿从头扫描，仅在一次扫描内使用 afterId 分页。
  /// 不把 AUTO_INCREMENT 当提交顺序，避免并发较小 ID 晚提交被永久跳过。
  Future<List<({int id, String messageId})>> fetchRecalls(
    String roomId,
    int afterId,
  ) async {
    final res = await _client.get(
      '/chat/recalls',
      queryParameters: {'roomId': roomId, 'afterId': afterId, 'pageSize': 100},
    );
    final data = res.data['data'];
    if (data is! List) throw const FormatException('invalid recall response');
    return data.map((item) {
      final id = int.tryParse(item['id'].toString());
      final messageId = item['messageId']?.toString();
      if (id == null ||
          id <= afterId ||
          messageId == null ||
          messageId.isEmpty) {
        throw const FormatException('invalid recall record');
      }
      return (id: id, messageId: messageId);
    }).toList();
  }

  /// 编辑同步补拉：与撤回同款游标分页，附带最终 payload JSON 快照。
  Future<List<({int id, String messageId, String payload})>> fetchEdits(
    String roomId,
    int afterId,
  ) async {
    final res = await _client.get(
      '/chat/edits',
      queryParameters: {'roomId': roomId, 'afterId': afterId, 'pageSize': 100},
    );
    final data = res.data['data'];
    if (data is! List) throw const FormatException('invalid edit response');
    return data.map((item) {
      final id = int.tryParse(item['id'].toString());
      final messageId = item['messageId']?.toString();
      final payload = item['payload']?.toString();
      if (id == null ||
          id <= afterId ||
          messageId == null ||
          messageId.isEmpty ||
          payload == null ||
          payload.isEmpty) {
        throw const FormatException('invalid edit record');
      }
      return (id: id, messageId: messageId, payload: payload);
    }).toList();
  }

  /// 获取会话列表
  ///
  /// 服务端返回完整会话列表，供本地对账。
  ///
  /// 返回 null 表示服务端响应异常（data 字段缺失/类型不符），
  /// 调用方不应把 null 当作「用户没有房间」，避免据此清空本地缓存。
  Future<List<ChatRoomVO>?> fetchConversations() async {
    final res = await _client.get(API.chatRooms);
    final data = res.data['data'];
    if (data is! List) return null;
    return data
        .map((e) => ChatRoomVO.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// 获取消息历史
  ///
  /// [convId] 会话 ID；[lastSeq] 获取该序号之后的消息；
  /// [beforeSeq] 获取该序号之前的消息（分页向前加载）；[pageSize] 每页数量。
  /// [since] 仅保留调用兼容；消息同步以序号为准，后端不支持时间游标。
  Future<List<ChatMessage>> fetchMessages(
    String convId, {
    DateTime? since,
    int? lastSeq,
    int? beforeSeq,
    int pageSize = 100,
  }) async {
    final res = await _client.get(
      API.chatHistory,
      queryParameters: {
        'roomId': convId,
        if ((beforeSeq ?? lastSeq ?? 0) > 0) 'lastSeq': beforeSeq ?? lastSeq,
        'pageSize': pageSize,
        'direction': beforeSeq == null ? 1 : 0,
      },
    );
    final data = res.data['data'];
    if (data is! List) throw const FormatException('invalid message response');
    return data
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
