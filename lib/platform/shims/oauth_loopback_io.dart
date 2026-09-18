// 桌面端回环接码实现（Windows/macOS/Linux 共用，纯 Dart）。
//
// 在 127.0.0.1:8080 起一次性 HttpServer，拉起系统浏览器跳 Google 授权页；
// Google 按注册的桌面重定向 URI 回调本地回环，取 code 后回一页成功提示并关服务。
// 端口与 Google 控制台注册的桌面重定向 URI 严格一致，换端口需同步改注册。
import 'dart:async';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

class OAuthLoopbackResult {
  final String code;
  final String state;

  const OAuthLoopbackResult({required this.code, required this.state});
}

/// 用户主动取消/关闭浏览器等待。
class OAuthCancelledException implements Exception {
  final String message;
  const OAuthCancelledException([this.message = '已取消 Google 登录']);

  @override
  String toString() => message;
}

/// 回环层失败（端口被占/打不开浏览器/state 校验失败等）。
///
/// 携带 i18n key（[messageKey]），调用方直接 `.tr()` 展示；与后端换 token
/// 失败区分开——后者已由 AuthController 统一 Toast，调用方不再重复提示。
class OAuthLoopbackException implements Exception {
  final String messageKey;
  const OAuthLoopbackException(this.messageKey);

  @override
  String toString() => messageKey;
}

abstract final class OAuthLoopback {
  /// 拉起系统浏览器完成授权，并在本地回环等待 Google 回调。
  ///
  /// 120 秒超时抛 [TimeoutException]；端口被占、打不开浏览器、state 校验
  /// 失败抛 [OAuthLoopbackException]；回调带 error（如用户在 Google 页点
  /// 拒绝）抛 [OAuthCancelledException]。
  static Future<OAuthLoopbackResult> waitForCallback({
    required Uri authorizeUri,
    required String expectedState,
    int port = 8080,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    late final HttpServer server;
    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    } on SocketException {
      throw const OAuthLoopbackException('login_oauth_port_busy');
    }

    final completer = Completer<OAuthLoopbackResult>();
    late final StreamSubscription<HttpRequest> sub;
    sub = server.listen((HttpRequest request) {
      unawaited(_handleRequest(request, expectedState, completer));
    });

    try {
      if (!await launchUrl(authorizeUri, mode: LaunchMode.externalApplication)) {
        throw const OAuthLoopbackException(
          'login_oauth_open_browser_failed',
        );
      }
      return await completer.future.timeout(timeout);
    } finally {
      await sub.cancel();
      await server.close(force: true);
    }
  }

  static Future<void> _handleRequest(
    HttpRequest request,
    String expectedState,
    Completer<OAuthLoopbackResult> completer,
  ) async {
    // 只处理回调路径，其余（favicon 等）直接 404，避免误判。
    if (request.uri.path != '/oauth-callback') {
      request.response
        ..statusCode = HttpStatus.notFound
        ..close();
      return;
    }
    final params = request.uri.queryParameters;
    final repo = request.response..headers.contentType = ContentType.html;

    if (params.containsKey('error') || !params.containsKey('code')) {
      repo.writeln(_resultPage('登录已取消', '已取消 Google 登录，可关闭本页返回应用。'));
      await repo.close();
      if (!completer.isCompleted) {
        completer.completeError(const OAuthCancelledException());
      }
      return;
    }
    if (params['state'] != expectedState) {
      repo.writeln(_resultPage('安全校验失败', '请求已过期，请返回应用重新发起登录。'));
      await repo.close();
      if (!completer.isCompleted) {
        completer.completeError(
          const OAuthLoopbackException('login_oauth_state_mismatch'),
        );
      }
      return;
    }
    repo.writeln(_resultPage('登录成功', 'Google 验证通过，可关闭本页返回应用继续。'));
    await repo.close();
    if (!completer.isCompleted) {
      completer.complete(
        OAuthLoopbackResult(code: params['code']!, state: params['state']!),
      );
    }
  }

  static String _resultPage(String title, String hint) => '''
<!DOCTYPE html><html lang="zh"><head><meta charset="utf-8">
<title>$title</title>
<style>body{font-family:system-ui,sans-serif;display:flex;height:100vh;margin:0;
align-items:center;justify-content:center;background:#f5f7fb;color:#202334}
.card{text-align:center}h1{font-size:20px}p{opacity:.7}</style>
</head><body><div class="card"><h1>$title</h1><p>$hint</p></div></body></html>''';
}
