/// 好友请求 视图对象
class ChatContactRequestVO {
  /// 主键ID
  final int? id;
  /// 请求用户ID
  final int? fromUserId;
  /// 请求备注
  final String? requestRemark;
  /// 请求状态 0-待处理 1-已接受 2-已拒绝
  final int? status;
  /// 申请时间
  final String? createdAt;
  /// 用户昵称
  final String? nickName;
  /// 用户头像
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