import 'UserVO.dart';

/// 用户搜索响应模型
class UserSearchResponse {
  /// 总记录数
  final int total;
  /// 数据列表
  final List<UserVO> rows;
  /// 状态码
  final int code;
  /// 消息
  final String msg;

  UserSearchResponse({
    required this.total,
    required this.rows,
    required this.code,
    required this.msg,
  });

  /// 从 JSON 构造对象
  factory UserSearchResponse.fromJson(Map<String, dynamic> json) {
    return UserSearchResponse(
      total: json['total'],
      rows: (json['rows'] as List)
          .map((e) => UserVO.fromJson(e))
          .toList(),
      code: json['code'],
      msg: json['msg'],
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'rows': rows.map((e) => e.toJson()).toList(),
      'code': code,
      'msg': msg,
    };
  }
}
