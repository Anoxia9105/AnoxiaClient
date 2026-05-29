import 'package:anoxia/framework/provider/core/network_provider.dart';
import 'package:anoxia/framework/provider/ws/ws_controller.dart';
import 'package:anoxia/framework/provider/ws/ws_state.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';

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

    // 1. 默认状态（未初始化或连接中）
    Color statusColor = Colors.orange;
    dynamic networkIcon = HugeIcons.strokeRoundedNoInternet; 
    String tooltipText = 'status_connecting'.tr();

    // 2. 解析当前具体的网络物理介质，匹配对应图标
    networkAsync.whenData((results) {
      if (results.contains(ConnectivityResult.none)) {
        statusColor = Colors.red;
        networkIcon = HugeIcons.strokeRoundedNoInternet; // 无网络图标
        tooltipText = 'status_network_unavailable'.tr();
        return;
      }

      // 根据当前最高优先级的连接方式匹配图标
      if (results.contains(ConnectivityResult.ethernet)) {
        networkIcon = HugeIcons.strokeRoundedInternet; // 有线网线/以太网
        tooltipText = 'Ethernet';
      } else if (results.contains(ConnectivityResult.mobile)) {
        networkIcon = HugeIcons.strokeRoundedCellularNetwork; // 移动网络
        tooltipText = 'Mobile Network';
      } else if (results.contains(ConnectivityResult.wifi)) {
        networkIcon = HugeIcons.strokeRoundedWifi02; // WiFi
        tooltipText = 'WiFi';
      }

      // 3. 叠加业务层 WebSocket 的连接状态来决定颜色
      switch (wsState.status) {
        case WsStatus.connected:
          statusColor = Colors.green;
          tooltipText = '$tooltipText - ${'status_online'.tr()}';
          break;
        case WsStatus.connecting:
          statusColor = Colors.orange;
          tooltipText = '$tooltipText - ${'status_connecting'.tr()}';
          break;
        case WsStatus.disconnected:
        case WsStatus.error:
          statusColor = Colors.grey;
          tooltipText = '$tooltipText - ${'status_offline'.tr()}';
          break;
      }
    });

    // 4. 渲染圆角包裹的精简状态标签
    return Tooltip(
      message: tooltipText, // 鼠标悬停时依然能看到文字提示，保证体验
      waitDuration: const Duration(milliseconds: 500),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300), // 颜色切换时有过渡动画
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.12), // 轻微的背景色浸润
          borderRadius: BorderRadius.circular(12),   // 完美的圆角胶囊
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