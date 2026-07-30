import 'package:easy_localization/easy_localization.dart';

/// 表单验证工具类
///
/// 提供常用的表单验证方法，包括邮箱、手机号、密码等。
class Validators {
  Validators._();

  /// 验证是否为空
  static String? required(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'validator_required'.tr();
    }
    return null;
  }

  /// 验证邮箱格式
  static String? email(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'validator_email_required'.tr();
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return message ?? 'validator_email_invalid'.tr();
    }
    return null;
  }

  /// 验证手机号格式
  static String? phone(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'validator_phone_required'.tr();
    }
    final phoneRegex = RegExp(r'^1[3-9]\d{9}$');
    if (!phoneRegex.hasMatch(value)) {
      return message ?? 'validator_phone_invalid'.tr();
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
      return message ?? 'validator_password_required'.tr();
    }

    if (value.length < minLength) {
      return message ?? 'validator_password_min_length'.tr(args: [minLength.toString()]);
    }

    if (requireDigit && !RegExp(r'\d').hasMatch(value)) {
      return message ?? 'validator_password_digit'.tr();
    }

    if (requireLetter && !RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return message ?? 'validator_password_letter'.tr();
    }

    return null;
  }

  /// 验证两次密码是否一致
  static String? confirmPassword(String? value, String? password, {String? message}) {
    if (value == null || value.isEmpty) {
      return message ?? 'validator_confirm_password_required'.tr();
    }
    if (value != password) {
      return message ?? 'validator_confirm_password_mismatch'.tr();
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
      return message ?? 'validator_username_required'.tr();
    }

    if (value.length < minLength) {
      return message ?? 'validator_username_min_length'.tr(args: [minLength.toString()]);
    }

    if (value.length > maxLength) {
      return message ?? 'validator_username_max_length'.tr(args: [maxLength.toString()]);
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return message ?? 'validator_username_format'.tr();
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
