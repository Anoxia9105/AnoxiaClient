import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/framework/domain/chat_favorite.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/chat/favorite/chat_favorite_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'favorites_common.dart';
import 'favorites_detail_panel.dart';
import 'favorites_detail_widgets.dart';
import 'favorites_empty_states.dart';
import 'favorites_list_panel.dart';

/// 收藏页面
///
/// 显示用户收藏的消息列表，支持查看详情、复制、取消收藏、类型筛选与搜索等功能
/// 移动端和桌面端采用不同的布局方式
class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  /// 当前选中的收藏项 ID
  int? _selectedId;

  /// 搜索关键词
  String _query = '';

  /// 类型筛选（null 表示全部）
  MessageType? _typeFilter;

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(chatFavoriteListProvider);

    final body = favoritesAsync.when(
      loading: () => _buildLoading(context),
      error: (e, _) => _buildError(context, e.toString()),
      data: (items) {
        final filtered = _applyFilters(items);
        _syncSelection(filtered);
        return _buildLoaded(context, items, filtered);
      },
    );
    // 标题由左栏列表面板的 AppBar 提供（与聊天/人员页一致）：
    // 桌面端靠左显示在面板栏内，移动端整页居中显示。
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: body,
    );
  }

  /// 本地筛选：类型过滤 + 关键词搜索
  List<ChatFavorite> _applyFilters(List<ChatFavorite> items) {
    var list = items;
    final type = _typeFilter;
    if (type != null) {
      list = list.where((e) => e.messageType == type).toList();
    }

    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (e) =>
                e.summary.toLowerCase().contains(q) ||
                e.senderDisplayName.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  /// 同步选中状态
  ///
  /// 桌面端确保选中项始终存在于当前筛选结果中；移动端不使用选中态
  void _syncSelection(List<ChatFavorite> filtered) {
    if (DeviceUtil.isMobile(context)) return;

    if (filtered.isEmpty) {
      if (_selectedId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _selectedId = null);
        });
      }
      return;
    }

    final stillExists =
        _selectedId != null &&
        filtered.any((element) => element.id == _selectedId);
    if (stillExists) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _selectedId = filtered.first.id);
    });
  }

  /// 数据中实际存在的消息类型（保持出现顺序）
  List<MessageType> _availableTypes(List<ChatFavorite> items) {
    final result = <MessageType>[];
    for (final item in items) {
      if (!result.contains(item.messageType)) result.add(item.messageType);
    }
    return result;
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _typeFilter = null;
    });
  }

  /// 确认并取消收藏
  Future<void> _confirmRemove(ChatFavorite item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('favorite_remove_confirm_title'.tr()),
        content: Text('favorite_remove_confirm_content'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('favorite_remove_btn'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final success = await ChatFavoriteService().removeFavorite(item.id);
    if (!mounted) return;
    Toast.showToast(
      success ? 'favorite_remove_success'.tr() : 'favorite_remove_failed'.tr(),
      type: success ? ToastType.success : ToastType.error,
    );
    if (success) ref.invalidate(chatFavoriteListProvider);
  }

  /// 构建加载状态界面
  Widget _buildLoading(BuildContext context) {
    final mobile = DeviceUtil.isMobile(context);
    if (mobile) {
      return favoritesTitleScaffold(
        context,
        child: const FavoriteListSkeleton(),
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 340,
          child: favoritesTitleScaffold(
            context,
            child: const FavoriteListSkeleton(),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: FavoriteDetailSkeleton()),
      ],
    );
  }

  /// 构建错误状态界面
  Widget _buildError(BuildContext context, String message) {
    return favoritesTitleScaffold(
      context,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlertCircle,
              color: Theme.of(context).colorScheme.error,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text('chat_load_failed'.tr()),
            const SizedBox(height: 6),
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: () => ref.invalidate(chatFavoriteListProvider),
              child: Text('call_window_retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建已加载状态界面
  Widget _buildLoaded(
    BuildContext context,
    List<ChatFavorite> items,
    List<ChatFavorite> filtered,
  ) {
    final mobile = DeviceUtil.isMobile(context);

    if (mobile) {
      if (filtered.isEmpty) {
        return items.isEmpty
            ? favoritesTitleScaffold(
                context,
                child: EmptyFavorites(
                  onRefresh: () => ref.invalidate(chatFavoriteListProvider),
                ),
              )
            : favoritesTitleScaffold(
                context,
                child: NoMatchFavorites(onClearFilters: _clearFilters),
              );
      }
      return FavoritesListPanel(
        items: filtered,
        selectedId: null,
        totalCount: items.length,
        availableTypes: _availableTypes(items),
        query: _query,
        searchController: _searchController,
        typeFilter: _typeFilter,
        onQueryChanged: (value) => setState(() => _query = value),
        onTypeChanged: (type) => setState(() => _typeFilter = type),
        onSelect: (id) {
          final selectedItem = filtered.where((e) => e.id == id).firstOrNull;
          if (selectedItem == null) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FavoriteDetailMobilePage(item: selectedItem),
            ),
          );
        },
        onRefresh: () => ref.invalidate(chatFavoriteListProvider),
      );
    }

    final selected = filtered.where((e) => e.id == _selectedId).firstOrNull;

    return Row(
      children: [
        SizedBox(
          width: 340,
          child: FavoritesListPanel(
            items: filtered,
            selectedId: _selectedId,
            totalCount: items.length,
            availableTypes: _availableTypes(items),
            query: _query,
            searchController: _searchController,
            typeFilter: _typeFilter,
            onQueryChanged: (value) => setState(() => _query = value),
            onTypeChanged: (type) => setState(() => _typeFilter = type),
            onSelect: (id) => setState(() => _selectedId = id),
            onRefresh: () => ref.invalidate(chatFavoriteListProvider),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildDetailArea(context, items, filtered, selected)),
      ],
    );
  }

  /// 构建桌面端详情区域（空态 / 无匹配 / 详情面板）
  Widget _buildDetailArea(
    BuildContext context,
    List<ChatFavorite> allItems,
    List<ChatFavorite> filtered,
    ChatFavorite? selected,
  ) {
    if (selected == null) {
      if (allItems.isEmpty) {
        return EmptyFavorites(
          onRefresh: () => ref.invalidate(chatFavoriteListProvider),
        );
      }
      if (filtered.isEmpty) {
        return NoMatchFavorites(onClearFilters: _clearFilters);
      }
      // 选中态尚未同步完成，短暂留白避免空指针
      return const SizedBox.shrink();
    }
    return FavoriteDetailPanel(
      item: selected,
      onDelete: () => _confirmRemove(selected),
    );
  }
}

/// 收藏页标题 Scaffold（列表面板 AppBar 之外的加载 / 空态 / 错误态共用）
///
/// 与聊天 / 人员页保持一致：桌面端标题靠左，移动端居中。
Widget favoritesTitleScaffold(BuildContext context, {required Widget child}) {
  return Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(
      centerTitle: DeviceUtil.isMobile(context),
      titleSpacing: 16,
      title: Text('sidebar_favorites'.tr()),
    ),
    body: child,
  );
}

/// 收藏详情移动端页面
class FavoriteDetailMobilePage extends ConsumerWidget {
  /// 收藏项对象
  final ChatFavorite item;

  const FavoriteDetailMobilePage({super.key, required this.item});

  /// 确认并取消收藏，成功后返回上一页
  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('favorite_remove_confirm_title'.tr()),
        content: Text('favorite_remove_confirm_content'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('favorite_remove_btn'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final success = await ChatFavoriteService().removeFavorite(item.id);
    if (!context.mounted) return;
    Toast.showToast(
      success ? 'favorite_remove_success'.tr() : 'favorite_remove_failed'.tr(),
      type: success ? ToastType.success : ToastType.error,
    );
    if (success) {
      ref.invalidate(chatFavoriteListProvider);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copyText = item.detailText.trim().isNotEmpty
        ? displayFavoriteSummary(item, item.detailText)
        : displayFavoriteSummary(item, item.summary);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('chat_favorite'.tr()),
        actions: [
          IconButton(
            tooltip: 'chat_copy'.tr(),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: copyText));
              if (!context.mounted) return;
              Toast.showToast(
                'chat_copy_success'.tr(),
                type: ToastType.success,
              );
            },
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedCopy01),
          ),
          IconButton(
            tooltip: 'favorite_remove'.tr(),
            onPressed: () => _remove(context, ref),
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02),
          ),
        ],
      ),
      body: FavoriteDetailPanel(
        item: item,
        onDelete: () => _remove(context, ref),
      ),
    );
  }
}
