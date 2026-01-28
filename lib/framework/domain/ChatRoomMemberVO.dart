import 'package:intl/intl.dart';

class ChatRoomMemberVO {
  final String? roomId;
  final int? userId;
  final int? roleId; // 0=普通成员 1=管理员 2=群主
  final DateTime? joinTime;
  final DateTime? lastActiveTime;
  final int? lastReadSeq;

  // 用户个人信息
  final String? nickName;
  final String? avatar;
  final String? sex; // 0男 1女 2未知
  final String? phoneNumber;
  final String? status; // 0正常 1停用
  final DateTime? loginDate;

  // IM 扩展字段
  final bool? onlineStatus;

  ChatRoomMemberVO({
    this.roomId,
    this.userId,
    this.roleId,
    this.joinTime,
    this.lastActiveTime,
    this.lastReadSeq,
    this.nickName,
    this.avatar,
    this.sex,
    this.phoneNumber,
    this.status,
    this.loginDate,
    this.onlineStatus,
  });

  /// 从 JSON 映射
  factory ChatRoomMemberVO.fromJson(Map<String, dynamic> json) {
    return ChatRoomMemberVO(
      roomId: json['roomId']?.toString(),
      userId: json['userId'] is int
          ? json['userId']
          : int.tryParse(json['userId']?.toString() ?? ''),
      roleId: json['roleId'] is int
          ? json['roleId']
          : int.tryParse(json['roleId']?.toString() ?? ''),
      // 处理后端 pattern = "yyyy-MM-dd HH:mm:ss" 的字符串
      joinTime: _parseDate(json['joinTime']),
      lastActiveTime: _parseDate(json['lastActiveTime']),
      lastReadSeq: json['lastReadSeq'] is int
          ? json['lastReadSeq']
          : int.tryParse(json['lastReadSeq']?.toString() ?? ''),
      nickName: json['nickName'],
      avatar: json['avatar'],
      sex: json['sex']?.toString(),
      phoneNumber: json['phoneNumber'],
      status: json['status']?.toString(),
      loginDate: _parseDate(json['loginDate']),
      onlineStatus: json['onlineStatus'] ?? false,
    );
  }

  /// 辅助日期解析
  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    try {
      // 如果后端传的是标准的 ISO 字符串或自定义格式
      return DateFormat("yyyy-MM-dd HH:mm:ss").parse(date);
    } catch (e) {
      return DateTime.tryParse(date.toString());
    }
  }

  /// 转换回 JSON (如果需要发送给后端)
  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'userId': userId,
      'roleId': roleId,
      'joinTime': joinTime != null
          ? DateFormat("yyyy-MM-dd HH:mm:ss").format(joinTime!)
          : null,
      'nickName': nickName,
      'avatar': avatar,
      'onlineStatus': onlineStatus,
    };
  }

  /// 拷贝方法，用于 Riverpod 局部更新状态
  ChatRoomMemberVO copyWith({
    bool? onlineStatus,
    String? nickName,
    int? lastReadSeq,
    DateTime? lastActiveTime,
  }) {
    return ChatRoomMemberVO(
      roomId: roomId,
      userId: userId,
      roleId: roleId,
      joinTime: joinTime,
      lastActiveTime: lastActiveTime ?? this.lastActiveTime,
      lastReadSeq: lastReadSeq ?? this.lastReadSeq,
      nickName: nickName,
      avatar: avatar,
      sex: sex,
      phoneNumber: phoneNumber,
      status: status,
      loginDate: loginDate,
      onlineStatus: onlineStatus ?? this.onlineStatus,
    );
  }
}
