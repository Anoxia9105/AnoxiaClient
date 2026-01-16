import 'package:anoxia/framework/domain/ChatContactRequestVO.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'contact_requests_service.g.dart';

@riverpod
class ContactRequestsService extends _$ContactRequestsService {
  @override
  FutureOr<List<ChatContactRequestVO>> build() {
    return _fetchRequests();
  }

  Future<List<ChatContactRequestVO>> _fetchRequests() async {
    final response = await DioClient().get('contact/request');
    return (response.data["data"] as List)
        .map((e) => ChatContactRequestVO.fromJson(e))
        .toList();
  }

  /// 同意好友请求的方法
  Future<void> acceptRequest(int requestId, bool isAccepted) async {
    await DioClient().get(
      'contact/acceptRequest',
      queryParameters: {
        'requestId': requestId,
        "status": isAccepted ? 1 : 2,
        "source": "app",
      },
    );
    // 操作成功后，重新获取列表更新 UI
    ref.invalidateSelf();
  }
}
