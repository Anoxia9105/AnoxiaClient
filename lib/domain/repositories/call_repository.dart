import 'package:anoxia/framework/domain/room_call_status.dart';

/// 通话仓库抽象接口
///
/// 定义通话相关的远程数据操作契约。
/// 数据层通过实现此接口提供具体实现，UI 层 Provider 仅依赖此接口。
abstract interface class CallRepository {
  /// 获取房间通话状态
  ///
  /// [roomId] 房间 ID；为空时直接返回空闲状态。
  Future<RoomCallStatus> fetchCallStatus(String roomId);

  /// 记录私聊通话拒接系统消息
  ///
  /// [roomId] 通话房间 ID
  Future<void> rejectCall(String roomId);

  /// 获取通话房间 JWT Token
  ///
  /// [roomId] 房间 ID
  ///
  /// 请求失败时抛出异常。
  Future<String> fetchCallToken(String roomId);

  /// 获取直播房间 token
  ///
  /// [roomId] 房间 ID
  ///
  /// 请求失败时抛出异常。
  Future<String> fetchLiveToken(String roomId);

  /// 从通话房间移除参与者
  ///
  /// [roomId] 房间 ID
  /// [identity] LiveKit 参与者 identity
  ///
  /// 返回是否操作成功。
  Future<bool> removeParticipant(String roomId, String identity);
}
