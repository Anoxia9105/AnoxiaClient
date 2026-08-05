/// 群组加入服务
///
/// 提供群组预览、加入群组、查看入群申请和处理入群审批等接口。
import 'package:anoxia/framework/domain/group_preview.dart';
import 'package:anoxia/framework/provider/core/group_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'group_join_service.g.dart';

/// 群组加入服务
///
/// 封装群组加入相关的 API 调用，包括预览群组信息、申请加入、查看申请列表和处理审批。
class GroupJoinService {
  final Ref _ref;

  GroupJoinService(this._ref);

  /// 预览群组信息
  ///
  /// [roomId] 群组 ID
  ///
  /// 返回 [GroupPreview] 对象，包含群组名称、头像、成员数等信息。
  /// 请求失败时抛出异常。
  Future<GroupPreview> preview(String roomId) {
    return _ref.read(groupRepositoryProvider).previewGroup(roomId);
  }

  /// 申请加入群组
  ///
  /// [roomId] 群组 ID
  /// [verificationMessage] 验证消息，默认为空字符串
  ///
  /// 返回加入结果字符串，如 'SUCCESS' 或 'FAILED'。
  /// 请求失败时抛出异常。
  Future<String> join(
    String roomId, {
    String verificationMessage = '',
  }) {
    return _ref
        .read(groupRepositoryProvider)
        .joinGroup(roomId, verificationMessage: verificationMessage);
  }

  /// 获取群组入群申请列表
  ///
  /// [roomId] 群组 ID
  ///
  /// 返回包含申请记录的列表，每条记录为 [Map] 格式。
  /// 请求失败时抛出异常。
  Future<List<Map<String, dynamic>>> requests(String roomId) {
    return _ref.read(groupRepositoryProvider).fetchJoinRequests(roomId);
  }

  /// 处理入群申请
  ///
  /// [requestId] 申请 ID
  /// [approved] 是否同意申请
  ///
  /// 操作失败时抛出异常。
  Future<void> handleRequest(int requestId, bool approved) {
    return _ref
        .read(groupRepositoryProvider)
        .handleJoinRequest(requestId, approved);
  }
}

/// 群组加入服务 Provider
final groupJoinServiceProvider = Provider<GroupJoinService>((ref) {
  return GroupJoinService(ref);
});

/// 入群申请列表服务（按房间缓存）
///
/// 供「入群申请」入口的红点徽标实时展示待处理申请数，
/// 由 WebSocket 事件与审批操作触发刷新。
@Riverpod(keepAlive: true)
class GroupJoinRequestsService extends _$GroupJoinRequestsService {
  Future<List<Map<String, dynamic>>>? _inflight;

  @override
  Future<List<Map<String, dynamic>>> build(String roomId) => _fetch(roomId);

  /// 拉取入群申请列表（并发请求去重）
  Future<List<Map<String, dynamic>>> _fetch(String roomId) {
    return _inflight ??=
        ref.read(groupJoinServiceProvider).requests(roomId).whenComplete(() {
      _inflight = null;
    });
  }

  /// 静默刷新（保留旧值，避免徽标闪烁）
  Future<void> refresh(String roomId) async {
    final result = await AsyncValue.guard(() => _fetch(roomId));
    if (!ref.mounted) return;
    state = result;
  }
}

/// 待处理入群申请数量（红点提示用）
///
/// 仅统计状态为 0（待处理）的申请数
@Riverpod(keepAlive: true)
Future<int> pendingGroupJoinRequestCount(Ref ref, String roomId) async {
  final requestsAsync = ref.watch(groupJoinRequestsServiceProvider(roomId));

  return requestsAsync.maybeWhen(
    data: (list) => list.where((req) => req['status'] == 0).length,
    orElse: () => 0,
  );
}
