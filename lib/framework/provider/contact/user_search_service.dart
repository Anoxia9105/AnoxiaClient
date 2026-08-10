import 'package:anoxia/framework/domain/user_search_response.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/provider/core/contact_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_search_service.g.dart';

/// 用户搜索服务
///
/// 支持按用户名/昵称搜索用户，并发送好友申请。
@Riverpod(keepAlive: true)
class UserSearchService extends _$UserSearchService {
  @override
  UserSearchResponse build() {
    return UserSearchResponse(total: 0, rows: [], code: 200, msg: '');
  }

  /// 清空搜索结果
  void clearResults() {
    state = build();
  }

  /// 搜索用户
  ///
  /// [name] 搜索关键词
  /// [pageNum] 当前页码
  /// [pageSize] 每页大小
  Future<UserSearchResponse> searchUsers(
    String name, {
    int pageNum = 1,
    int pageSize = 10,
  }) async {
    try {
      final contactRepository = ref.read(contactRepositoryProvider);
      final searchResponse = await contactRepository.searchUsers(
        name,
        pageNum: pageNum,
        pageSize: pageSize,
      );
      state = searchResponse;
      return searchResponse;
    } catch (e, st) {
      debugLog('搜索用户失败: $e', e, st);
      rethrow;
    }
  }

  /// 发送好友申请
  ///
  /// [toUserId] 接收人用户ID
  /// [remark] 申请附言
  Future<bool> sendContactRequest(int toUserId, String? remark) async {
    final contactRepository = ref.read(contactRepositoryProvider);
    return contactRepository.sendContactRequest(toUserId, remark);
  }
}
