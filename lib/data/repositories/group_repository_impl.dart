import 'package:anoxia/common/constants/api.dart';
import 'package:anoxia/domain/repositories/group_repository.dart';
import 'package:anoxia/framework/domain/chat_room_member_vo.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/domain/group_preview.dart';
import 'package:anoxia/framework/logs/talker.dart';
import 'package:anoxia/framework/network/dio_client.dart';
import 'package:dio/dio.dart';

/// 群组仓库实现
///
/// 通过远程数据源（HTTP API）提供群组相关操作。
/// 实现 [GroupRepository] 抽象接口，供 UI 层 Provider 使用。
class GroupRepositoryImpl implements GroupRepository {
  @override
  Future<ChatRoomVO> createGroup({
    required String name,
    required List<int> userIds,
    required int joinPolicy,
  }) async {
    final res = await DioClient().post(
      API.chatCreateGroup,
      data: {'name': name, 'ids': userIds, 'joinPolicy': joinPolicy},
    );

    // 根据后端 AjaxResult 的结构解析
    if (res.data['code'] == 200) {
      return ChatRoomVO.fromJson(res.data['data']);
    }
    throw res.data['msg'] ?? '创建失败';
  }

  @override
  Future<GroupPreview> previewGroup(String roomId) async {
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

  @override
  Future<String> joinGroup(
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

  @override
  Future<List<Map<String, dynamic>>> fetchJoinRequests(String roomId) async {
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

  @override
  Future<void> handleJoinRequest(int requestId, bool approved) async {
    final response = await DioClient().post(
      API.chatGroupJoinRequestHandle,
      data: {'requestId': requestId, 'approved': approved},
    );
    if (response.data is! Map || response.data['code'] != 200) {
      throw Exception('operation failed');
    }
  }

  @override
  Future<List<ChatRoomMemberVO>> fetchRoomMembers(
    String roomId, {
    CancelToken? cancelToken,
  }) async {
    final res = await DioClient().get(
      API.chatMembers,
      queryParameters: {'roomId': roomId},
      cancelToken: cancelToken,
    );

    final data = res.data['data'];
    if (data is! List) return [];

    final List<ChatRoomMemberVO> members = [];
    for (final e in data) {
      if (e is! Map) continue;
      final member = ChatRoomMemberVO.fromJson(Map<String, dynamic>.from(e));
      if (member.userId != null) members.add(member);
    }
    return members;
  }

  @override
  Future<String?> addRoomMembers(String roomId, List<int> userIds) async {
    try {
      final res = await DioClient().post(
        API.chatRoomAddMembers,
        data: {'roomId': roomId, 'userIds': userIds},
      );
      if (res.data['code'] != 200) return null;
      return res.data['data']?.toString();
    } catch (e, st) {
      log.error('[Group] 添加成员失败', e, st);
      return null;
    }
  }

  @override
  Future<bool> kickRoomMember(String roomId, int targetUserId) async {
    try {
      final res = await DioClient().get(
        API.chatRoomKickMember,
        queryParameters: {'roomId': roomId, 'targetUserId': targetUserId},
      );
      return res.data['code'] == 200;
    } catch (e, st) {
      log.error('[Group] 踢人失败', e, st);
      return false;
    }
  }
}
