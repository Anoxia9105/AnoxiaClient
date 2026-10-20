import 'package:anoxia/framework/domain/call_log_entry.dart';
import 'package:anoxia/framework/domain/room_call_status.dart';

/// 通话仓库抽象接口
///
/// 定义通话相关的远程数据操作契约。
/// 数据层通过实现此接口提供具体实现，UI 层 Provider 仅依赖此接口。
abstract interface class CallRepository {
  /// 获取通话记录（跨房间会话级聚合）
  ///
  /// [pageNum] 从 1 开始；[pageSize] 每页条数（服务端 1-100）；[orderBy]
  /// 按开始时间 `asc`/`desc`，默认 desc（新→旧）。
  ///
  /// 请求失败或响应结构非法时抛出异常。
  Future<CallHistoryPageData> fetchCallHistory({
    required int pageNum,
    required int pageSize,
    required String orderBy,
  });
  /// 获取房间通话状态
  ///
  /// [roomId] 房间 ID；为空时直接返回空闲状态。
  Future<RoomCallStatus> fetchCallStatus(String roomId);

  /// 获取通话房间 JWT Token
  ///
  /// [roomId] 房间 ID
  ///
  /// 请求失败时抛出异常。
  Future<String> fetchCallToken(String roomId);

  /// 从通话房间移除参与者
  ///
  /// [roomId] 房间 ID
  /// [identity] LiveKit 参与者 identity
  ///
  /// 返回是否操作成功。
  Future<bool> removeParticipant(String roomId, String identity);
}
