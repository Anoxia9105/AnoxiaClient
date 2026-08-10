/// 扫码登录模型
///
/// 桌面/Web 端通过 [ScanLoginTicket] 展示二维码，轮询 [ScanLoginStatus]；
/// 手机 App 扫码后调用确认接口完成登录。
library;

/// 扫码登录会话信息。
///
/// 由服务端 /login/scan/create 下发：ticket 为会话唯一标识，
/// qrContent 为二维码编码内容，expiresIn 为有效秒数。
class ScanLoginTicket {
  const ScanLoginTicket({
    required this.ticket,
    required this.qrContent,
    required this.expiresIn,
  });

  /// 会话唯一标识（32 位十六进制）
  final String ticket;

  /// 二维码编码内容（https 链接）
  final String qrContent;

  /// 会话有效时长（秒）
  final int expiresIn;
}

/// 扫码登录会话状态。
///
/// [status] 取值见 [waiting]/[confirmed]/[expired]；
/// 状态为 confirmed 时 [token] 携带为新设备签发的登录令牌。
class ScanLoginStatus {
  const ScanLoginStatus({required this.status, this.token});

  /// 等待手机确认
  static const String waiting = 'waiting';

  /// 已确认，携带登录令牌
  static const String confirmed = 'confirmed';

  /// 已过期（TTL 耗尽或从未创建）
  static const String expired = 'expired';

  /// 会话状态
  final String status;

  /// 登录令牌（仅 confirmed 时非空）
  final String? token;

  bool get isWaiting => status == waiting;
  bool get isConfirmed => status == confirmed;
  bool get isExpired => status == expired;
}
