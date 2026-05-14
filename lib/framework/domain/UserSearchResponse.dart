import 'UserVO.dart';

/// 用户搜索响应模型
///
/// 封装分页搜索结果，包含总数、数据列表、状态码和消息。
class UserSearchResponse {
  /// 符合条件的总记录数
  final int total;

  /// 当前页的数据列表
  final List<UserVO> rows;

  /// 响应状态码
  final int code;

  /// 响应消息
  final String msg;

  UserSearchResponse({
    required this.total,
    required this.rows,
    required this.code,
    required this.msg,
  });

  /// 从 JSON 数据构造 [UserSearchResponse] 实例
  ///
  /// 自动处理数字字段可能为 String 或 num 的兼容场景
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

  /// 将当前实例转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'rows': rows.map((e) => e.toJson()).toList(),
      'code': code,
      'msg': msg,
    };
  }
}
