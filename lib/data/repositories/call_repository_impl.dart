import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/domain/repositories/call_repository.dart';
import 'package:anoxia/framework/domain/room_call_status.dart';
import 'package:anoxia/framework/network/dio_client.dart';

/// 通话仓库实现
///
/// 通过远程数据源（HTTP API）提供通话相关操作。
/// 实现 [CallRepository] 抽象接口，供 UI 层 Provider 使用。
class CallRepositoryImpl implements CallRepository {
  @override
  Future<RoomCallStatus> fetchCallStatus(String roomId) async {
    if (roomId.isEmpty) return const RoomCallStatus.idle();

    final res = await DioClient().get(
      API.callStatus,
      queryParameters: {'roomId': roomId},
    );

    final data = res.data?['data'];
    if (data is Map<String, dynamic>) {
      return RoomCallStatus.fromJson(data);
    }
    return const RoomCallStatus.idle();
  }

  @override
  Future<String> fetchCallToken(String roomId) async {
    final res = await DioClient().get(
      API.callToken,
      queryParameters: {'roomId': roomId},
    );
    if (res.data == null) throw Exception('Token 获取失败，响应数据异常');
    if (res.data['code'] == 200) {
      return res.data['data'].toString();
    }
    throw Exception("Token 获取失败: ${res.data["message"] ?? "未知错误"}");
  }

  @override
  Future<String> fetchLiveToken(String roomId) async {
    final res = await DioClient().get(
      '/live/token',
      queryParameters: {'roomId': roomId},
    );
    if (res.data?['code'] == 200) {
      return res.data!['data'].toString();
    }
    throw Exception(res.data?['message'] ?? '获取直播 token 失败');
  }

  @override
  Future<bool> removeParticipant(String roomId, String identity) async {
    final res = await DioClient().get(
      API.callRemoveParticipant,
      queryParameters: {'roomId': roomId, 'identity': identity},
    );
    return res.data?['code'] == 200;
  }
}
