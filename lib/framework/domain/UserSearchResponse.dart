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
    int toInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    final dynamic rowsRaw = json['rows'];
    final List<UserVO> parsedRows = rowsRaw is List
        ? rowsRaw
              .whereType<Map>()
              .map(
                (e) => UserVO.fromJson(
                  e.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .toList()
        : <UserVO>[];

    return UserSearchResponse(
      total: toInt(json['total']),
      rows: parsedRows,
      code: toInt(json['code'], fallback: 200),
      msg: (json['msg'] ?? '').toString(),
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
