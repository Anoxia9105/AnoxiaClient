import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/framework/domain/group_preview.dart';
import 'package:anoxia/framework/network/dio_client.dart';

class GroupJoinService {
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
