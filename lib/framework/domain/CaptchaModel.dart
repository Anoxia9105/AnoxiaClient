/// 图形验证码模型
///
/// 用于登录等场景的身份验证，包含唯一标识和 Base64 编码的图片数据。
class CaptchaModel {
  /// 验证码唯一标识，用于后端校验
  final String uuid;

  /// 验证码图片的 Base64 编码字符串
  final String imgBase64;

  CaptchaModel({required this.uuid, required this.imgBase64});
}
