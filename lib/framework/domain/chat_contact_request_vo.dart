/// 好友请求视图对象
///
/// 展示好友申请/请求的完整信息，包括申请者资料、请求状态和时间。
class ChatContactRequestVO {
  /// 请求记录主键ID
  final int? id;

  /// 发起请求的用户ID
  final int? fromUserId;

  /// 申请时的附言/备注
  final String? requestRemark;

  /// 请求状态：0=待处理，1=已接受，2=已拒绝
  final int? status;

  /// 申请提交时间
  final String? createdAt;

  /// 申请者昵称
  final String? nickName;

  /// 申请者头像
  final String? avatar;

  ChatContactRequestVO({
    this.id,
    this.fromUserId,
    this.requestRemark,
    this.status,
    this.createdAt,
    this.nickName,
    this.avatar,
  });

  /// 从 JSON 数据构造 [ChatContactRequestVO] 实例
  factory ChatContactRequestVO.fromJson(Map<String, dynamic> json) {
    return ChatContactRequestVO(
      id: json['id'],
      fromUserId: json['fromUserId'],
      requestRemark: json['requestRemark'],
      status: json['status'],
      createdAt: json['createdAt'],
      nickName: json['nickName'],
      avatar: json['avatar'],
    );
  }

  /// 将当前实例转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'requestRemark': requestRemark,
      'status': status,
      'createdAt': createdAt,
      'nickName': nickName,
      'avatar': avatar,
    };
  }
}
