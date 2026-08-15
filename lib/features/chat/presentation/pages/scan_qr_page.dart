// 扫码页面，用于扫描二维码添加好友或识别其他内容。
//
// 支持识别用户名片二维码（直接跳转添加好友页面）和普通二维码/链接（展示解析结果）。
import 'dart:convert';

import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/app/presentation/pages/scan_login_confirm_page.dart';
import 'package:anoxia/features/contact/presentation/pages/add_friend_page.dart';
import 'package:anoxia/features/contact/presentation/widgets/add_friend/add_friend_dialog.dart';
import 'package:anoxia/framework/domain/user_vo.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:anoxia/framework/provider/core/contact_repository_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anoxia/features/chat/presentation/pages/qr_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

/// 扫码页面。
///
/// 使用摄像头实时扫描二维码，识别后根据内容类型执行相应操作。
class ScanQrPage extends ConsumerStatefulWidget {
  const ScanQrPage({super.key});

  @override
  ConsumerState<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends ConsumerState<ScanQrPage> {
  late final QrScannerController _controller;

  /// 是否正在处理扫码结果，防止重复处理。
  bool _handling = false;

  @override
  void initState() {
    super.initState();
    _controller = QrScannerController(onDetect: _onDetect);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 扫码检测回调。
  ///
  /// 识别到二维码后，如果是用户名片则跳转添加好友页面，
  /// 否则跳转到结果展示页面。
  Future<void> _onDetect(String raw) async {
    raw = raw.trim();
    if (raw.isEmpty || _handling) return;

    _handling = true;
    await _controller.stop();
    if (!mounted) return;

    final card = _tryParseUserCard(raw);
    if (card != null) {
      final me = ref.read(authControllerProvider).value;
      final isSelf =
          me != null &&
          (card.userName == me.userName ||
              (card.userId != null && card.userId == me.userId));

      if (isSelf) {
        Toast.showToast(
          'chat_scan_cannot_add_self'.tr(),
          type: ToastType.warning,
        );
        _handling = false;
        await _controller.start();
        return;
      }

      // 新版 URL 名片（https://<host>/u/{userId}）：拉取用户详情后直接弹好友申请
      // 对话框；未登录或拉取失败时降级为展示原始内容。
      if (card.userId != null && card.userName.isEmpty) {
        final handled = await _handleUrlUserCard(card.userId!);
        if (handled) {
          if (!mounted) return;
          _handling = false;
          await _controller.start();
          return;
        }
      } else {
        // 旧版 JSON 名片：跳转添加好友页按用户名搜索。
        Toast.showToast(
          'chat_scan_user_card_detected'.tr(args: [card.userName]),
          type: ToastType.success,
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AddFriendPage(initialKeyword: card.userName),
          ),
        );
        return;
      }
    }

    if (!mounted) return;

    // 扫码登录二维码：跳转手机确认页
    final ticket = _tryParseScanLoginTicket(raw);
    if (ticket != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScanLoginConfirmPage(ticket: ticket),
        ),
      );
      if (!mounted) return;
      _handling = false;
      await _controller.start();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScanQrResultPage(rawContent: raw)),
    );

    if (!mounted) return;
    _handling = false;
    await _controller.start();
  }

  /// 尝试将扫码结果解析为扫码登录 ticket。
  ///
  /// 桌面端二维码内容为 `https://<host>/qrlogin?ticket=xxx`，
  /// 匹配路径即可（兼容生产域名与本地开发环境）。
  String? _tryParseScanLoginTicket(String raw) {
    try {
      final uri = Uri.parse(raw.trim());
      if (!uri.hasScheme || uri.pathSegments.isEmpty) return null;
      if (uri.pathSegments.first != 'qrlogin') return null;
      final ticket = uri.queryParameters['ticket'];
      if (ticket == null || ticket.isEmpty) return null;
      return ticket;
    } catch (_) {
      return null;
    }
  }

  /// 处理新版 URL 格式的用户名片（`https://<host>/u/{userId}`）。
  ///
  /// 拉取用户详情成功后弹好友申请对话框并返回 true（用户取消对话框也视为
  /// 已处理）；未登录或拉取失败时返回 false，由调用方降级为展示原始内容。
  Future<bool> _handleUrlUserCard(int userId) async {
    try {
      final detail = await ref
          .read(contactRepositoryProvider)
          .getContactDetail(userId);
      if (!mounted) return false;
      if (detail.userId == null &&
          (detail.nickName ?? '').isEmpty &&
          (detail.userName ?? '').isEmpty) {
        return false;
      }

      final user = UserVO(
        userId: detail.userId ?? userId,
        userName: detail.userName ?? '',
        nickName: detail.nickName ?? '',
        avatar: detail.avatar,
        phonenumber: detail.phoneNumber,
        sex: detail.sex,
      );
      Toast.showToast(
        'chat_scan_user_card_detected'.tr(args: [user.nickName]),
        type: ToastType.success,
      );
      final result = await AddFriendDialog.show(context, user);
      if (result == null || !mounted) return true;
      Toast.showToast(
        result
            ? 'add_friend_request_sent'.tr()
            : 'add_friend_request_failed'.tr(),
        type: result ? ToastType.success : ToastType.error,
      );
      return true;
    } catch (e, st) {
      debugLog('[Scan] 拉取二维码用户详情失败: $e', e, st);
      return false;
    }
  }

  /// 尝试将扫码结果解析为用户名片。
  ///
  /// 优先解析新版 URL 格式（`https://<host>/u/{userId}`），
  /// 其次兼容旧版 `user_card` JSON（历史已分享的二维码）。
  /// 返回 [_UserCardPayload] 如果内容为有效的用户名片，否则返回 null。
  _UserCardPayload? _tryParseUserCard(String raw) {
    final urlCard = _tryParseUserUrl(raw);
    if (urlCard != null) return urlCard;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = decoded.cast<dynamic, dynamic>();
      final type = map['type']?.toString();
      if (type != 'user_card') return null;

      final userName = map['userName']?.toString().trim() ?? '';
      if (userName.isEmpty) return null;

      int? userId;
      final rawUserId = map['userId'];
      if (rawUserId is int) {
        userId = rawUserId;
      } else if (rawUserId != null) {
        userId = int.tryParse(rawUserId.toString());
      }

      return _UserCardPayload(userName: userName, userId: userId);
    } catch (_) {
      return null;
    }
  }

  /// 尝试将扫码结果解析为 URL 格式的用户名片（`https://<host>/u/{userId}`）。
  _UserCardPayload? _tryParseUserUrl(String raw) {
    try {
      final uri = Uri.parse(raw.trim());
      if (!uri.hasScheme) return null;
      final scheme = uri.scheme.toLowerCase();
      if (scheme != 'http' && scheme != 'https') return null;
      final segments = uri.pathSegments;
      if (segments.length != 2 || segments.first != 'u') return null;
      final userId = int.tryParse(segments[1]);
      if (userId == null) return null;
      return _UserCardPayload(userName: '', userId: userId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('chat_scan_qr_code'.tr()),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          QrScannerWidget(controller: _controller),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  'chat_scan_qr_code_hint'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 扫码结果展示页面。
///
/// 展示扫码得到的原始内容，支持复制到剪贴板和在浏览器中打开链接。
class ScanQrResultPage extends StatelessWidget {
  const ScanQrResultPage({super.key, required this.rawContent});

  /// 扫码得到的原始内容字符串。
  final String rawContent;

  /// 格式化 JSON 内容为可读的缩进格式。
  String _prettyContent(String raw) {
    try {
      final decoded = jsonDecode(raw);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (_) {
      return raw;
    }
  }

  /// 尝试将内容解析为可打开的 URI（http/https）。
  Uri? _tryParseOpenableUri(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme) return null;
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'http' || scheme == 'https') {
      return uri;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final content = _prettyContent(rawContent);
    final openableUri = _tryParseOpenableUri(rawContent);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text('chat_scan_result'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'chat_scan_content_title'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(content),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: rawContent));
                      Toast.showToast(
                        'chat_scan_content_copied'.tr(),
                        type: ToastType.success,
                      );
                    },
                    child: Text('chat_scan_copy'.tr()),
                  ),
                ),
                if (openableUri != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final launched = await launchUrl(
                          openableUri,
                          mode: LaunchMode.externalApplication,
                        );
                        if (!launched) {
                          Toast.showToast(
                            'chat_scan_open_failed'.tr(),
                            type: ToastType.error,
                          );
                        }
                      },
                      child: Text('chat_scan_open_link'.tr()),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 用户名片扫码结果数据模型。
class _UserCardPayload {
  const _UserCardPayload({required this.userName, this.userId});

  /// 用户名（旧版 JSON 名片内嵌；URL 名片为 `https://<host>/u/{userId}` 时为空串，
  /// 此时须依赖 [userId] 拉取用户详情）。
  final String userName;

  /// 用户 ID（可选）。
  final int? userId;
}