import 'package:anoxia/framework/provider/ws/ws_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// WebSocket 连接状态横幅组件
///
/// 显示当前 WebSocket 连接状态，包括：
/// - 连接中：显示加载提示
/// - 连接失败：显示错误提示
/// - 已断开：显示断开提示
/// - 已连接：不显示任何内容
class WsConnectionBanner extends StatelessWidget {
  /// WebSocket 状态对象
  final WsState state;

  const WsConnectionBanner({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    // 已连接状态不显示横幅
    if (state.status == WsStatus.connected) {
      return const SizedBox.shrink();
    }
    final cs = Theme.of(context).colorScheme;
    final (icon, text, bg, fg) = switch (state.status) {
      WsStatus.connecting => (
        Icons.wifi_protected_setup_rounded,
        'appbar_connecting'.tr(),
        cs.primaryContainer.withValues(alpha: .7),
        cs.primary,
      ),
      WsStatus.error => (
        Icons.error_outline_rounded,
        state.error?.trim().isNotEmpty == true
            ? 'appbar_connection_lost'.tr()
            : 'appbar_connection_lost'.tr(),
        cs.errorContainer.withValues(alpha: .85),
        cs.error,
      ),
      WsStatus.disconnected => (
        Icons.portable_wifi_off_rounded,
        'appbar_connection_lost'.tr(),
        cs.errorContainer.withValues(alpha: .85),
        cs.error,
      ),
      WsStatus.connected => (
        Icons.check,
        '',
        Colors.transparent,
        Colors.transparent,
      ),
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
