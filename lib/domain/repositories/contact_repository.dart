import 'package:anoxia/framework/domain/chat_contact_detail_vo.dart';
import 'package:anoxia/framework/domain/chat_contact_request_vo.dart';
import 'package:anoxia/framework/domain/user_search_response.dart';
import 'package:anoxia/framework/domain/chat_contact_vo.dart';

/// 联系人仓库抽象接口
///
/// 定义联系人相关的数据操作契约。
/// 数据层通过实现此接口提供具体实现，领域层（用例）和 UI 层（Provider）
/// 仅依赖此接口，实现与数据源的解耦。
abstract interface class ContactRepository {
  /// 观察联系人列表流
  Stream<List<ChatContactVO>> watchContacts();

  /// 获取本地缓存的联系人列表
  Future<List<ChatContactVO>> getLocalContacts();

  /// 从远程获取联系人列表
  Future<List<ChatContactVO>> fetchRemoteContacts();

  /// 用成功的远端全量列表对账本地缓存，包含删除列表外的联系人。
  Future<void> upsertContacts(List<ChatContactVO> contacts);

  /// 更新联系人在线状态
  Future<void> updateContactOnlineStatus(int userId, bool isOnline);

  /// 删除联系人
  Future<void> deleteContact(int contactId);

  /// 获取联系人详情
  ///
  /// 根据用户ID获取联系人的详细信息（来自 sys_user 和 chat_contact 表的聚合数据）
  Future<ChatContactDetailVO> getContactDetail(int userId);

  /// 搜索用户
  ///
  /// [name] 搜索关键词
  /// [pageNum] 当前页码
  /// [pageSize] 每页大小
  Future<UserSearchResponse> searchUsers(
    String name, {
    int pageNum,
    int pageSize,
  });

  /// 获取好友请求列表
  Future<List<ChatContactRequestVO>> fetchContactRequests();

  /// 处理好友请求
  ///
  /// [requestId] 请求记录ID
  /// [isAccepted] true=同意，false=拒绝
  Future<void> handleContactRequest(int requestId, bool isAccepted);

  /// 发送好友申请
  ///
  /// [toUserId] 接收人用户ID
  /// [remark] 申请附言
  Future<bool> sendContactRequest(int toUserId, String? remark);
}
