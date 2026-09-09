import 'package:anoxia/framework/provider/core/network_provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:anoxia/framework/provider/ws/ws_state.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 连接状态标签组件
///
/// 显示当前网络连接状态和 WebSocket 连接状态的组合状态：
/// - 网络类型：无网络 / 以太网 / 移动网络 / WiFi
/// - WebSocket 状态：在线 / 连接中 / 离线
/// 
/// 通过颜色和图标直观展示状态，悬停显示详细提示
class ConnectionStatusTag extends ConsumerWidget {
  const ConnectionStatusTag({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkAsync = ref.watch(networkStatusProvider);
    final wsState = ref.watch(wsControllerProvider);

    // 1. 先按业务层 WebSocket 状态决定颜色与文案。网络介质数据在部分
    // 平台（如 Web/WASM）可能长期无数据，不能仅依赖它，否则标签会
    // 一直卡在默认的「连接中」。
    late Color statusColor;
    late String statusText;
    switch (wsState.status) {
      case WsStatus.connected:
        statusColor = Colors.green;
        statusText = 'status_online'.tr();
        break;
      case WsStatus.connecting:
        statusColor = Colors.orange;
        statusText = 'status_connecting'.tr();
        break;
      case WsStatus.disconnected:
      case WsStatus.error:
        statusColor = Colors.grey;
        statusText = 'status_offline'.tr();
        break;
    }

    // 2. 有网络介质数据时再叠加图标与提示；明确无网络时标红。
    dynamic networkIcon = HugeIcons.strokeRoundedInternet;
    String tooltipText = statusText;
    final statuses = switch (networkAsync) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (statuses != null && statuses.isNotEmpty) {
      if (statuses.contains(ConnectivityResult.none)) {
        statusColor = Colors.red;
        networkIcon = HugeIcons.strokeRoundedNoInternet; // 无网络图标
        tooltipText = 'status_network_unavailable'.tr();
      } else {
        // 根据当前最高优先级的连接方式匹配图标
        String? mediumText;
        if (statuses.contains(ConnectivityResult.ethernet)) {
          networkIcon = HugeIcons.strokeRoundedInternet; // 有线网线/以太网
          mediumText = 'Ethernet';
        } else if (statuses.contains(ConnectivityResult.mobile)) {
          networkIcon = HugeIcons.strokeRoundedCellularNetwork; // 移动网络
          mediumText = 'Mobile Network';
        } else if (statuses.contains(ConnectivityResult.wifi)) {
          networkIcon = HugeIcons.strokeRoundedWifi02; // WiFi
          mediumText = 'WiFi';
        }
        tooltipText = mediumText == null ? statusText : '$mediumText - $statusText';
      }
    }

    // 4. 渲染圆角包裹的精简状态标签
    return Tooltip(
      message: tooltipText, // 鼠标悬停时依然能看到文字提示，保证体验
      waitDuration: const Duration(milliseconds: 500),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300), // 颜色切换时有过渡动画
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.12), // 轻微的背景色浸润
          borderRadius: BorderRadius.circular(RadiusToken.lg),   // 完美的圆角胶囊
          border: Border.all(
            color: statusColor.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 状态指示灯小圆点
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  if (wsState.status == WsStatus.connecting)
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // 代替文字的网络类型高精图标
            HugeIcon(
              icon: networkIcon,
              color: statusColor,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}