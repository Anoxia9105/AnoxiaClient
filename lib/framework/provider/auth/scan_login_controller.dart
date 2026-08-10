import 'dart:async';

import 'package:anoxia/framework/domain/scan_login_model.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/core/auth_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scan_login_controller.g.dart';

/// 扫码登录状态快照
class ScanLoginSession {
  const ScanLoginSession({required this.ticket, this.status});

  /// 当前会话信息
  final ScanLoginTicket ticket;

  /// 最近一次轮询到的状态（创建后未轮询时为 null）
  final ScanLoginStatus? status;

  bool get isWaiting => status == null || status!.isWaiting;
}

/// 扫码登录控制器（桌面/Web 展示端）
///
/// 负责创建扫码登录会话并以 2s 间隔轮询状态：
/// - 手机确认后拿到 token 直接完成登录（复用 [AuthController.loginByScanToken]）
/// - 会话过期时自动重新创建二维码
/// - 页面销毁时自动取消轮询
@riverpod
class ScanLoginController extends _$ScanLoginController {
  /// 轮询间隔
  static const Duration _pollInterval = Duration(seconds: 2);

  Timer? _timer;

  /// 当前会话（供轮询回调读取）
  ScanLoginTicket? _ticket;

  @override
  Future<ScanLoginSession?> build() async {
    ref.onDispose(_cancelTimer);
    return null;
  }

  /// 创建新的扫码登录会话并启动轮询
  ///
  /// 二维码过期或用户手动点击刷新时复用此方法。
  Future<void> start() async {
    _cancelTimer();
    try {
      final ticket = await ref.read(authRepositoryProvider).createScanLogin();
      _ticket = ticket;
      state = AsyncData(ScanLoginSession(ticket: ticket));
      debugLog('[ScanLogin] 会话已创建: ${ticket.ticket}');
      _timer = Timer.periodic(_pollInterval, (_) => _poll());
    } catch (e, st) {
      debugLog('[ScanLogin] 创建会话失败', e, st);
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// 轮询一次当前会话状态
  Future<void> _poll() async {
    final ticket = _ticket;
    if (ticket == null) return;
    try {
      final status =
          await ref.read(authRepositoryProvider).getScanLoginStatus(ticket.ticket);
      if (status.isConfirmed) {
        _cancelTimer();
        state = AsyncData(ScanLoginSession(ticket: ticket, status: status));
        final token = status.token;
        if (token != null && token.isNotEmpty) {
          debugLog('[ScanLogin] 手机已确认，开始登录...');
          try {
            await ref
                .read(authControllerProvider.notifier)
                .loginByScanToken(token);
          } catch (e, st) {
            debugLog('[ScanLogin] 登录失败', e, st);
            state = AsyncError(e, st);
          }
        }
      } else if (status.isExpired) {
        debugLog('[ScanLogin] 会话已过期，自动刷新二维码');
        await start();
      } else {
        state = AsyncData(ScanLoginSession(ticket: ticket, status: status));
      }
    } catch (e) {
      // 轮询偶发失败忽略，等待下一个周期重试
      debugLog('[ScanLogin] 轮询失败（忽略）: $e');
    }
  }

  /// 停止轮询
  void stop() => _cancelTimer();

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}