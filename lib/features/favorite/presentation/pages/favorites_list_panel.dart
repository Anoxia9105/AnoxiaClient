import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:anoxia/framework/domain/chat_favorite.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'favorites_common.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 收藏列表面板组件
class FavoritesListPanel extends StatelessWidget {
  /// 当前筛选后的收藏项列表
  final List<ChatFavorite> items;

  /// 当前选中的收藏项 ID
  final int? selectedId;

  /// 收藏总数（筛选前）
  final int totalCount;

  /// 数据中实际存在的消息类型
  final List<MessageType> availableTypes;

  /// 搜索关键词
  final String query;

  /// 搜索输入控制器
  final TextEditingController searchController;

  /// 当前类型筛选
  final MessageType? typeFilter;

  /// 选择回调
  final ValueChanged<int> onSelect;

  /// 刷新回调
  final VoidCallback onRefresh;

  /// 搜索关键词变化回调
  final ValueChanged<String> onQueryChanged;

  /// 类型筛选变化回调
  final ValueChanged<MessageType?> onTypeChanged;

  const FavoritesListPanel({
    super.key,
    required this.items,
    required this.selectedId,
    required this.totalCount,
    required this.availableTypes,
    required this.query,
    required this.searchController,
    required this.typeFilter,
    required this.onSelect,
    required this.onRefresh,
    required this.onQueryChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        centerTitle: DeviceUtil.isMobile(context),
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                'sidebar_favorites'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(RadiusToken.pill),
              ),
              child: Text(
                'favorite_count'.tr(args: [totalCount.toString()]),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'call_window_retry'.tr(),
            onPressed: onRefresh,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh01,
              size: 20,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 类型筛选（标签）统一放在标题下面，搜索框随后
          if (totalCount > 0)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: .6),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 30,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: availableTypes.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return FavoriteTypeFilterChip(
                            label: 'favorite_all_types'.tr(),
                            icon: HugeIcons.strokeRoundedGrid,
                            selected: typeFilter == null,
                            onTap: () => onTypeChanged(null),
                          );
                        }
                        final type = availableTypes[index - 1];
                        return FavoriteTypeFilterChip(
                          label: favoriteTypeLabel(type),
                          icon: favoriteTypeStyle(type).icon,
                          selected: typeFilter == type,
                          onTap: () => onTypeChanged(type),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: searchController,
                    onChanged: onQueryChanged,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'favorite_search_hint'.tr(),
                      hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: .7),
                      ),
                      prefixIconConstraints: const BoxConstraints.tightFor(
                        width: 34,
                        height: 34,
                      ),
                      prefixIcon: Center(
                        child: SizedBox.square(
                          dimension: 15,
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedSearch02,
                            size: 14,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              tooltip: 'cancel'.tr(),
                              iconSize: 16,
                              onPressed: () {
                                searchController.clear();
                                onQueryChanged('');
                              },
                              icon: HugeIcon(
                                icon: HugeIcons.strokeRoundedCancel01,
                                color: cs.onSurfaceVariant,
                              ),
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => FavoritesListItem(
                item: items[index],
                selected: items[index].id == selectedId,
                onTap: () => onSelect(items[index].id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 收藏列表单项
class FavoritesListItem extends StatelessWidget {
  final ChatFavorite item;
  final bool selected;
  final VoidCallback onTap;

  const FavoritesListItem({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = favoriteTypeStyle(item.messageType);
    final color = favoriteTypeColor(context, item.messageType);

    return Material(
      color: selected ? color.withValues(alpha: .10) : Colors.transparent,
      borderRadius: BorderRadius.circular(RadiusToken.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(RadiusToken.xl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarWidget(
                size: 40,
                url: item.senderAvatar,
                name: item.senderDisplayName.isNotEmpty
                    ? item.senderDisplayName
                    : item.typeLabel,
                borderRadius: 12,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayFavoriteSummary(item, item.summary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FavoriteTypeChip(type: item.messageType),
                    if (item.senderDisplayName.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.senderDisplayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatFavoriteDate(item.createdAt),
                            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ] else
                      const SizedBox(height: 6),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              HugeIcon(
                icon: HugeIcons.strokeRoundedBookmark01,
                size: 14,
                color: selected
                    ? style.color
                    : cs.onSurfaceVariant.withValues(alpha: .35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 类型筛选 Chip
class FavoriteTypeFilterChip extends StatelessWidget {
  final String label;
  final List<List<dynamic>> icon;
  final bool selected;
  final VoidCallback onTap;

  const FavoriteTypeFilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: selected ? cs.primary : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(RadiusToken.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(RadiusToken.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: icon,
                size: 14,
                color: selected ? cs.onPrimary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 消息类型标签（图标 + 名称）
class FavoriteTypeChip extends StatelessWidget {
  final MessageType type;

  const FavoriteTypeChip({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final color = favoriteTypeColor(context, type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(RadiusToken.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: favoriteTypeStyle(type).icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            favoriteTypeLabel(type),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 收藏列表骨架屏
class FavoriteListSkeleton extends StatelessWidget {
  const FavoriteListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(width: 34, height: 34, radius: 10),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLine(width: 120, height: 14),
                        SizedBox(height: 8),
                        SkeletonLine(width: 170, height: 10),
                      ],
                    ),
                  ),
                  SkeletonBox(width: 28, height: 28, radius: 8),
                ],
              ),
              SizedBox(height: 12),
              SkeletonBox(width: double.infinity, height: 36, radius: 8),
              SizedBox(height: 10),
              Row(
                children: [
                  SkeletonBox(width: 64, height: 28, radius: 999),
                  SizedBox(width: 6),
                  SkeletonBox(width: 56, height: 28, radius: 999),
                  SizedBox(width: 6),
                  SkeletonBox(width: 72, height: 28, radius: 999),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
            itemCount: 8,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, _) {
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(RadiusToken.xl),
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 40, height: 40, radius: 12),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLine(width: 180, height: 12),
                          SizedBox(height: 8),
                          SkeletonLine(width: 96, height: 12),
                          SizedBox(height: 8),
                          SkeletonLine(width: 130, height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
