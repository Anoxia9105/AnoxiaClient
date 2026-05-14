import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/domain/ChatContactRequestVO.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'contact_list_controller.dart';

part 'contact_requests_controller.g.dart';

/// 好友申请列表服务
///
/// 管理所有收到的好友请求，支持请求处理和列表刷新。
///
/// 采用 keepAlive 模式，确保请求列表在全局共享。
@Riverpod(keepAlive: true)
class ContactRequestsService extends _$ContactRequestsService {
  @override
  FutureOr<List<ChatContactRequestVO>> build() {
    return _fetchRequests();
  }

  /// 从后端获取好友申请列表
  ///
  /// 服务端异常时返回空列表，避免阻塞 UI
  Future<List<ChatContactRequestVO>> _fetchRequests() async {
    try {
      final response = await DioClient().get(API.contactRequest);
      return (response.data["data"] as List)
          .map((e) => ChatContactRequestVO.fromJson(e))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 处理好友请求
  ///
  /// [requestId] 请求记录ID
  /// [isAccepted] true=同意，false=拒绝
  Future<void> acceptRequest(int requestId, bool isAccepted) async {
    await DioClient().get(
      API.contactAcceptRequest,
      queryParameters: {
        'requestId': requestId,
        "status": isAccepted ? 1 : 2,
        "source": 0,
      },
    );

    // 操作成功后刷新列表
    refresh(quiet: true);

    // 同意时同时刷新好友列表
    if (isAccepted) {
      ref.read(contactListServiceProvider.notifier).refresh(quiet: true);
    }
  }

  /// 手动刷新列表
  ///
  /// [quiet] 为 true 时静默刷新，不触发 loading 状态
  Future<void> refresh({bool quiet = false}) async {
    if (!quiet) {
      state = const AsyncValue.loading();
    }
    final result = await AsyncValue.guard(() => _fetchRequests());
    if (!ref.mounted) return;
    state = result;
  }
}

/// 待处理好友申请数量
///
/// 仅统计状态为 0（待处理）的请求数
@Riverpod(keepAlive: true)
Future<int> pendingRequestCount(Ref ref) async {
  final requestsAsync = ref.watch(contactRequestsServiceProvider);

  return requestsAsync.maybeWhen(
    data: (list) => list.where((req) => req.status == 0).length,
    orElse: () => 0,
  );
}
