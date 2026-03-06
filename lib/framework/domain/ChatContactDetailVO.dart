import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

class ChatContactDetailVO {
  // 来自 sys_user
  final int? userId;
  final String? userName;
  final String? nickName;
  final String? avatar;
  final String? sex;
  final String? email;
  final String? phoneNumber;

  // 来自 chat_contact (关系特有)
  final String? remark;    // 好友备注
  final int? status;       // 关系状态:0=正常,1=黑名单...
  final int? source;       // 来源:0=搜索,1=扫码...
  final DateTime? createdAt; // 成为好友的时间

  ChatContactDetailVO({
    this.userId,
    this.userName,
    this.nickName,
    this.avatar,
    this.sex,
    this.email,
    this.phoneNumber,
    this.remark,
    this.status,
    this.source,
    this.createdAt,
  });

  /// JSON 反序列化
  factory ChatContactDetailVO.fromJson(Map<String, dynamic> json) {
    return ChatContactDetailVO(
      userId: json['userId'],
      userName: json['userName'] ?? '',
      nickName: json['nickName'] ?? '',
      avatar: json['avatar'] ?? '',
      sex: json['sex']?.toString() ?? '2',
      email: json['email'] ?? '',
      // 注意：Java 里是 phonenumber，Dart 建议用驼峰但解析要对应 Key
      phoneNumber: json['phoneNumber'] ?? '',
      remark: json['remark'],
      status: json['status'] is int ? json['status'] : int.tryParse(json['status']?.toString() ?? ''),
      source: json['source'] as int?,
      // 处理 LocalDateTime 转出的字符串
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  /// 辅助方法：获取性别文本
  String get genderText {
    switch (sex) {
      case '0': return 'gender_male'.tr();
      case '1': return 'gender_female'.tr();
      default: return 'gender_unknown'.tr();
    }
  }

  /// 辅助方法：格式化好友时间
  String get formattedDate {
    if (createdAt == null) return 'unknown_time'.tr();
    return DateFormat('yyyy-MM-dd HH:mm').format(createdAt!);
  }
}