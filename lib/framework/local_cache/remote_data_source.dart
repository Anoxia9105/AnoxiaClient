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

  /// 获取会话列表
  ///
  /// [since] 可选，获取该时间之后更新的会话，用于增量同步。
  ///
  /// 返回 null 表示服务端响应异常（data 字段缺失/类型不符），
  /// 调用方不应把 null 当作「用户没有房间」，避免据此清空本地缓存。
  Future<List<ChatRoomVO>?> fetchConversations({DateTime? since}) async {
    final res = await _client.get(
      API.chatRooms,
      queryParameters: {
        if (since != null) 'updatedAfter': since.toIso8601String(),
      },
    );
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
    if (data is! List) return const [];
    return data
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
