/// 群组加入服务
///
/// 提供群组预览、加入群组、查看入群申请和处理入群审批等接口。
import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/framework/domain/group_preview.dart';
import 'package:anoxia/framework/network/dio_client.dart';

/// 群组加入服务
///
/// 封装群组加入相关的 API 调用，包括预览群组信息、申请加入、查看申请列表和处理审批。
class GroupJoinService {
  /// 预览群组信息
  ///
  /// [roomId] 群组 ID
  ///
  /// 返回 [GroupPreview] 对象，包含群组名称、头像、成员数等信息。
  /// 请求失败时抛出异常。
  static Future<GroupPreview> preview(String roomId) async {
    final response = await DioClient().get(
      API.chatGroupPreview,
      queryParameters: {'roomId': roomId},
    );
    if (response.data is! Map || response.data['code'] != 200) {
      throw Exception(response.data?['msg'] ?? 'group unavailable');
    }
    return GroupPreview.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  }

  /// 申请加入群组
  ///
  /// [roomId] 群组 ID
  /// [verificationMessage] 验证消息，默认为空字符串
  ///
  /// 返回加入结果字符串，如 'SUCCESS' 或 'FAILED'。
  /// 请求失败时抛出异常。
  static Future<String> join(
    String roomId, {
    String verificationMessage = '',
  }) async {
    final response = await DioClient().post(
      API.chatGroupJoin,
      data: {'roomId': roomId, 'verificationMessage': verificationMessage},
    );
    if (response.data is! Map || response.data['code'] != 200) {
      throw Exception(response.data?['msg'] ?? 'join failed');
    }
    return response.data['data']?.toString() ?? 'FAILED';
  }

  /// 获取群组入群申请列表
  ///
  /// [roomId] 群组 ID
  ///
  /// 返回包含申请记录的列表，每条记录为 [Map] 格式。
  /// 请求失败时抛出异常。
  static Future<List<Map<String, dynamic>>> requests(String roomId) async {
    final response = await DioClient().get(
      API.chatGroupJoinRequests,
      queryParameters: {'roomId': roomId},
    );
    if (response.data is! Map || response.data['code'] != 200) {
      throw Exception('load failed');
    }
    return (response.data['data'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// 处理入群申请
  ///
  /// [requestId] 申请 ID
  /// [approved] 是否同意申请
  ///
  /// 操作失败时抛出异常。
  static Future<void> handleRequest(int requestId, bool approved) async {
    final response = await DioClient().post(
      API.chatGroupJoinRequestHandle,
      data: {'requestId': requestId, 'approved': approved},
    );
    if (response.data is! Map || response.data['code'] != 200) {
      throw Exception('operation failed');
    }
  }
}
