import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 列表刷新使用独立的实色表面，不能继承透明的 Scaffold 背景。
class ListRefreshIndicator extends StatelessWidget {
  const ListRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final RefreshCallback onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return RefreshIndicator(
      backgroundColor: colors.surfaceContainerHigh,
      color: colors.primary,
      strokeWidth: 2.5,
      elevation: 2,
      semanticsLabel: 'call_share_refresh'.tr(),
      onRefresh: onRefresh,
      child: child,
    );
  }
}

/// 桌面列表的刷新入口；刷新期间保持按钮尺寸并禁用重复点击。
class ListRefreshButton extends StatelessWidget {
  const ListRefreshButton({
    super.key,
    required this.onRefresh,
    required this.isRefreshing,
  });

  final RefreshCallback onRefresh;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'call_share_refresh'.tr(),
    onPressed: isRefreshing ? null : onRefresh,
    icon: isRefreshing
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          )
        : const HugeIcon(icon: HugeIcons.strokeRoundedRefresh, size: 20),
  );
}
