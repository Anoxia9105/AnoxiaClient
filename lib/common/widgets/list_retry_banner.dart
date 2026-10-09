import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 刷新失败时保留列表，并提供恢复入口。
class ListRetryBanner extends StatelessWidget {
  const ListRetryBanner({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text('chat_load_failed'.tr())),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text('call_window_retry'.tr()),
          ),
        ],
      ),
    );
  }
}
