import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/domain/ChatContactRequestVO.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'contact_list_controller.dart';

part 'contact_requests_controller.g.dart';

@Riverpod(keepAlive: true)
class ContactRequestsService extends _$ContactRequestsService {
  @override
  FutureOr<List<ChatContactRequestVO>> build() {
    return _fetchRequests();
  }

  Future<List<ChatContactRequestVO>> _fetchRequests() async {
    try {
      final response = await DioClient().get(API.contactRequest);
      return (response.data["data"] as List)
          .map((e) => ChatContactRequestVO.fromJson(e))
          .toList();
    } catch (e) {
      // 服务端异常时返回空列表，避免阻塞UI
      return [];
    }
  }

  /// 同意好友请求的方法
  Future<void> acceptRequest(int requestId, bool isAccepted) async {
    await DioClient().get(
      API.contactAcceptRequest,
      queryParameters: {
        'requestId': requestId,
        "status": isAccepted ? 1 : 2,
        "source": 0, //来源:0=搜索,1=扫码,2=群聊
      },
    );
    // 操作成功后，重新获取列表更新 UI
    refresh(quiet: true);

    //如果是同意 刷新好友列表
    if (isAccepted) {
      // 只要 invalidate 这个 provider，下游的 sortedContactGroupsProvider 也会自动重新计算
      ref.read(contactListServiceProvider.notifier).refresh(quiet: true);
    }
  }

  /// 手动刷新方法（例如下拉刷新时调用）
  Future<void> refresh({bool quiet = false}) async {
    if (!quiet) {
      state = const AsyncValue.loading(); // 先展示加载状态
    }
    final result = await AsyncValue.guard(() => _fetchRequests());
    if (!ref.mounted) return; // provider 已被销毁，不再更新 state
    state = result;
  }
}

/// 统计待处理的数量
@Riverpod(keepAlive: true)
Future<int> pendingRequestCount(Ref ref) async {
  // 监听整个列表的状态
  final requestsAsync = ref.watch(contactRequestsServiceProvider);

  return requestsAsync.maybeWhen(
    data: (list) => list.where((req) => req.status == 0).length,
    orElse: () => 0,
  );
}
