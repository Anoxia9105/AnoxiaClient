import 'package:anoxia/framework/domain/chat_room_member_vo.dart';
import 'package:anoxia/framework/domain/chat_room_vo.dart';
import 'package:anoxia/framework/domain/group_preview.dart';
import 'package:dio/dio.dart';

/// 群组仓库抽象接口
///
/// 定义群组相关的数据操作契约：创建群聊、群组预览、加入群组、
/// 入群申请审批以及群成员管理。
/// 数据层通过实现此接口提供具体实现，UI 层 Provider 仅依赖此接口。
abstract interface class GroupRepository {
  /// 创建群聊
  ///
  /// [name] 群名称
  /// [userIds] 初始成员用户 ID 列表
  /// [joinPolicy] 入群策略
  /// 失败时抛出异常（携带后端错误消息）。
  Future<ChatRoomVO> createGroup({
    required String name,
    required List<int> userIds,
    required int joinPolicy,
  });

  /// 预览群组信息
  Future<GroupPreview> previewGroup(String roomId);

  /// 申请加入群组
  ///
  /// [roomId] 群组 ID
  /// [verificationMessage] 验证消息，默认为空字符串
  ///
  /// 返回加入结果字符串，如 'SUCCESS' 或 'FAILED'。
  Future<String> joinGroup(
    String roomId, {
    String verificationMessage = '',
  });

  /// 获取群组入群申请列表
  Future<List<Map<String, dynamic>>> fetchJoinRequests(String roomId);

  /// 处理入群申请
  ///
  /// [requestId] 申请 ID
  /// [approved] 是否同意申请
  Future<void> handleJoinRequest(int requestId, bool approved);

  /// 获取指定房间的成员列表
  ///
  /// [roomId] 目标房间 ID
  /// [cancelToken] 可选的取消令牌（用于超时取消）
  Future<List<ChatRoomMemberVO>> fetchRoomMembers(
    String roomId, {
    CancelToken? cancelToken,
  });

  /// 添加成员到房间
  ///
  /// 返回 'ADDED'（已直接加入）或 'PENDING'（已邀请，等待管理员审核）；
  /// 失败返回 null。
  Future<String?> addRoomMembers(String roomId, List<int> userIds);

  /// 从房间踢出成员
  ///
  /// 返回是否操作成功。
  Future<bool> kickRoomMember(String roomId, int targetUserId);
}
