/// 表单验证工具类
///
/// 提供常用的表单验证方法，包括邮箱、手机号、密码等。
class Validators {
  Validators._();

  /// 验证是否为空
  static String? required(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? '此字段不能为空';
    }
    return null;
  }

  /// 验证邮箱格式
  static String? email(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? '请输入邮箱';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return message ?? '请输入有效的邮箱地址';
    }
    return null;
  }

  /// 验证手机号格式
  static String? phone(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? '请输入手机号';
    }
    final phoneRegex = RegExp(r'^1[3-9]\d{9}$');
    if (!phoneRegex.hasMatch(value)) {
      return message ?? '请输入有效的手机号';
    }
    return null;
  }

  /// 验证密码强度
  ///
  /// [value] 密码
  /// [minLength] 最小长度，默认为 6
  /// [requireDigit] 是否必须包含数字
  /// [requireLetter] 是否必须包含字母
  static String? password(
      String? value, {
        int minLength = 6,
        bool requireDigit = false,
        bool requireLetter = true,
        String? message,
      }) {
    if (value == null || value.isEmpty) {
      return message ?? '请输入密码';
    }

    if (value.length < minLength) {
      return message ?? '密码长度不能少于 $minLength 位';
    }

    if (requireDigit && !RegExp(r'\d').hasMatch(value)) {
      return message ?? '密码必须包含数字';
    }

    if (requireLetter && !RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return message ?? '密码必须包含字母';
    }

    return null;
  }

  /// 验证两次密码是否一致
  static String? confirmPassword(String? value, String? password, {String? message}) {
    if (value == null || value.isEmpty) {
      return message ?? '请确认密码';
    }
    if (value != password) {
      return message ?? '两次输入的密码不一致';
    }
    return null;
  }

  /// 验证用户名
  ///
  /// [value] 用户名
  /// [minLength] 最小长度
  /// [maxLength] 最大长度
  static String? username(
      String? value, {
        int minLength = 3,
        int maxLength = 20,
        String? message,
      }) {
    if (value == null || value.trim().isEmpty) {
      return message ?? '请输入用户名';
    }

    if (value.length < minLength) {
      return message ?? '用户名长度不能少于 $minLength 位';
    }

    if (value.length > maxLength) {
      return message ?? '用户名长度不能超过 $maxLength 位';
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return message ?? '用户名只能包含字母、数字和下划线';
    }

    return null;
  }

  /// 组合多个验证器
  ///
  /// [value] 待验证的值
  /// [validators] 验证器列表，按顺序执行
  static String? compose(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }
}
