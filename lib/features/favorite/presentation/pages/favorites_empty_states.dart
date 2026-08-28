import 'package:anoxia/common/utils/device_util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// 空收藏状态
class EmptyFavorites extends StatelessWidget {
  final VoidCallback onRefresh;

  const EmptyFavorites({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mobile = DeviceUtil.isMobile(context);
    final iconContainerSize = mobile ? 72.0 : 96.0;
    final iconSize = mobile ? 20.0 : 28.0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary.withValues(alpha: .18),
                  cs.primary.withValues(alpha: .05),
                ],
              ),
              border: Border.all(color: cs.primary.withValues(alpha: .15)),
            ),
            child: Center(
              child: SizedBox.square(
                dimension: iconSize,
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedBookmark03,
                  size: iconSize,
                  color: cs.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'favorite_empty_title'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'favorite_empty_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onRefresh,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh01,
              size: 18,
            ),
            label: Text('call_window_retry'.tr()),
          ),
        ],
      ),
    );
  }
}

/// 无匹配结果状态（筛选 / 搜索后为空）
class NoMatchFavorites extends StatelessWidget {
  final VoidCallback onClearFilters;

  const NoMatchFavorites({super.key, required this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedSearchRemove,
            size: 34,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            'favorite_no_result'.tr(),
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onClearFilters,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedFilterRemove,
              size: 18,
            ),
            label: Text('favorite_clear_filter'.tr()),
          ),
        ],
      ),
    );
  }
}
