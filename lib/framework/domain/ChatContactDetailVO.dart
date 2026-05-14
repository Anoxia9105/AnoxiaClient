import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

/// 联系人详情视图对象
///
/// 聚合了用户基础信息（来自 sys_user 表）和好友关系信息（来自 chat_contact 表）。
/// 提供性别文本国际化、好友添加时间格式化等便捷访问。
class ChatContactDetailVO {
  /// 用户ID
  final int? userId;

  /// 用户账号（登录名）
  final String? userName;

  /// 用户昵称
  final String? nickName;

  /// 头像 URL
  final String? avatar;

  /// 性别：0=男，1=女，其他=未知
  final String? sex;

  /// 电子邮箱
  final String? email;

  /// 手机号码
  final String? phoneNumber;

  /// 好友备注名
  final String? remark;

  /// 关系状态：0=正常，1=黑名单
  final int? status;

  /// 添加来源：0=搜索，1=扫码
  final int? source;

  /// 成为好友的时间
  final DateTime? createdAt;

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

  /// 从 JSON 数据构造 [ChatContactDetailVO] 实例
  ///
  /// 兼容后端 snake_case 命名（phoneNumber）和 Dart 驼峰命名（phoneNumber）
  factory ChatContactDetailVO.fromJson(Map<String, dynamic> json) {
    return ChatContactDetailVO(
      userId: json['userId'],
      userName: json['userName'] ?? '',
      nickName: json['nickName'] ?? '',
      avatar: json['avatar'] ?? '',
      sex: json['sex']?.toString() ?? '2',
      email: json['email'] ?? '',
      // 兼容 Java 后端的 phonenumber 字段名
      phoneNumber: json['phoneNumber'] ?? '',
      remark: json['remark'],
      status: json['status'] is int
          ? json['status']
          : int.tryParse(json['status']?.toString() ?? ''),
      source: json['source'] as int?,
      // 兼容后端 LocalDateTime 的 ISO 字符串格式
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  /// 获取性别国际化文本
  ///
  /// 根据 [sex] 字段返回对应的翻译文本
  String get genderText {
    switch (sex) {
      case '0':
        return 'gender_male'.tr();
      case '1':
        return 'gender_female'.tr();
      default:
        return 'gender_unknown'.tr();
    }
  }

  /// 获取格式化后的好友添加时间
  ///
  /// 格式：yyyy-MM-dd HH:mm，无时间时返回翻译后的未知时间文本
  String get formattedDate {
    if (createdAt == null) return 'unknown_time'.tr();
    return DateFormat('yyyy-MM-dd HH:mm').format(createdAt!);
  }
}
