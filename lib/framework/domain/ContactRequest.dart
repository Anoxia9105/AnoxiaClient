/// 好友申请请求模型
class ContactRequest {
  /// 申请人ID
  final int? fromUserId;
  /// 接收人ID
  final int toUserId;
  /// 申请备注
  final String? remark;

  ContactRequest({
    this.fromUserId,
    required this.toUserId,
    this.remark,
  });

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'remark': remark,
    };
  }
}
