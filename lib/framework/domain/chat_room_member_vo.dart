import 'package:intl/intl.dart';

/// 聊天室成员视图对象
///
/// 表示聊天室中的单个成员，包含用户资料、角色权限和在线状态。
class ChatRoomMemberVO {
  /// 所属聊天室ID
  final String? roomId;

  /// 用户ID
  final int? userId;

  /// 角色ID：0=管理员，1=普通成员
  final int? roleId;

  /// 加入聊天室的时间
  final DateTime? joinTime;

  /// 用户昵称
  final String? nickName;

  /// 头像 URL
  final String? avatar;

  /// 性别：0=男，1=女，2=未知
  final String? sex;

  /// 手机号码
  final String? phoneNumber;

  /// 账号状态：0=正常，1=停用
  final String? status;

  /// 最后登录时间
  final DateTime? loginDate;

  /// 在线状态：true=在线，false=离线
  final bool? onlineStatus;

  /// 在本房间的已读水位（服务端 chat_room_member.read_seq）
  ///
  /// 单聊已读回执（P0-2）用「对端成员行」的该字段做展示判定；
  /// null 表示接口未返回（老协议/未知），展示层自动降级为「已送达」。
  final int? lastReadSeq;

  ChatRoomMemberVO({
    this.roomId,
    this.userId,
    this.roleId,
    this.joinTime,
    this.nickName,
    this.avatar,
    this.sex,
    this.phoneNumber,
    this.status,
    this.loginDate,
    this.onlineStatus,
    this.lastReadSeq,
  });

  /// 从 JSON 数据构造 [ChatRoomMemberVO] 实例
  ///
  /// 兼容后端 snake_case 字段命名和多种日期格式
  factory ChatRoomMemberVO.fromJson(Map<String, dynamic> json) {
    return ChatRoomMemberVO(
      roomId: json['roomId']?.toString(),
      userId: json['userId'] is int
          ? json['userId']
          : int.tryParse(json['userId']?.toString() ?? ''),
      roleId: json['roleId'] is int
          ? json['roleId']
          : int.tryParse(json['roleId']?.toString() ?? ''),
      // 兼容后端 yyyy-MM-dd HH:mm:ss 格式的日期字符串
      joinTime: _parseDate(json['joinTime']),
      nickName: json['nickName']?.toString(),
      avatar: json['avatar']?.toString(),
      sex: json['sex']?.toString(),
      phoneNumber: (json['phoneNumber'] ?? json['phonenumber'])?.toString(),
      status: json['status']?.toString(),
      loginDate: _parseDate(json['loginDate']),
      onlineStatus: json['onlineStatus'] ?? false,
      // 服务端映射为 crm.read_seq AS lastReadSeq，兼容整型与字符串数字
      lastReadSeq: json['lastReadSeq'] is int
          ? json['lastReadSeq']
          : int.tryParse(json['lastReadSeq']?.toString() ?? ''),
    );
  }

  /// 解析日期字符串
  ///
  /// 优先尝试标准格式，失败后尝试 ISO 格式
  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(date);
    } catch (e) {
      return DateTime.tryParse(date.toString());
    }
  }

  /// 将当前实例转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'userId': userId,
      'roleId': roleId,
      'joinTime': joinTime != null
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(joinTime!)
          : null,
      'nickName': nickName,
      'avatar': avatar,
      'onlineStatus': onlineStatus,
    };
  }

  /// 创建当前实例的变体副本
  ///
  /// 用于响应式状态管理中的局部更新（如在线状态变更）
  ChatRoomMemberVO copyWith({
    bool? onlineStatus,
    String? nickName,
    String? avatar,
    int? lastReadSeq,
  }) {
    return ChatRoomMemberVO(
      roomId: roomId,
      userId: userId,
      roleId: roleId,
      joinTime: joinTime,
      nickName: nickName ?? this.nickName,
      avatar: avatar ?? this.avatar,
      sex: sex,
      phoneNumber: phoneNumber,
      status: status,
      loginDate: loginDate,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      lastReadSeq: lastReadSeq ?? this.lastReadSeq,
    );
  }
}
