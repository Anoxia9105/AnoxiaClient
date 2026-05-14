/// 好友申请请求模型
///
/// 用于发起或处理好友申请请求，包含申请人和接收人信息。
class ContactRequest {
  /// 申请人用户ID（发起请求方）
  final int? fromUserId;

  /// 接收人用户ID（被请求方）
  final int toUserId;

  /// 申请时的附言/备注
  final String? remark;

  ContactRequest({
    this.fromUserId,
    required this.toUserId,
    this.remark,
  });

  /// 将当前实例转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'remark': remark,
    };
  }
}
