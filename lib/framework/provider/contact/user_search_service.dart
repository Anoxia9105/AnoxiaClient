import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/domain/ContactRequest.dart';
import 'package:anoxia/framework/domain/UserSearchResponse.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_search_service.g.dart';

/// 用户搜索服务
///
/// 支持按用户名/昵称搜索用户，并发送好友申请。
@Riverpod(keepAlive: true)
class UserSearchService extends _$UserSearchService {
  @override
  UserSearchResponse build() {
    return UserSearchResponse(total: 0, rows: [], code: 200, msg: "");
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
      final response = await DioClient().get(
        API.contactSearch,
        queryParameters: {
          'name': name,
          'pageNum': pageNum,
          'pageSize': pageSize,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final code = data['code'];
        if (code is int && code != 200) {
          final msg = (data['msg'] ?? 'search failed').toString();
          throw Exception(msg);
        }
      }

      final searchResponse = UserSearchResponse.fromJson(response.data);
      state = searchResponse;
      return searchResponse;
    } catch (e, st) {
      log.error('搜索用户失败: $e', e, st);
      rethrow;
    }
  }

  /// 发送好友申请
  ///
  /// [toUserId] 接收人用户ID
  /// [remark] 申请附言
  Future<bool> sendContactRequest(int toUserId, String? remark) async {
    try {
      final request = ContactRequest(toUserId: toUserId, remark: remark);

      final response = await DioClient().post(
        API.contactRequestCreate,
        data: request.toJson(),
      );

      if (response.data['code'] == 200) {
        log.info('发送好友申请成功: $toUserId');
        return true;
      } else {
        log.warning('发送好友申请失败: ${response.data['msg']}');
        return false;
      }
    } catch (e, st) {
      log.error('发送好友申请失败: $e', e, st);
      return false;
    }
  }
}
