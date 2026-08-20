import 'package:anoxia/common/utils/device_util.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anoxia/common/widgets/avatar_widget.dart';
import 'package:anoxia/common/widgets/skeleton_box.dart';
import 'package:anoxia/common/widgets/toast.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/base/message_render_factory.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/base/message_render_strategy.dart';
import 'package:anoxia/features/note/presentation/widgets/note_card_content.dart';
import 'package:anoxia/framework/domain/chat_favorite.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/chat/favorite/chat_favorite_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return Scaffold(
      appBar: AppBar(
        centerTitle: DeviceUtil.isMobile(context),
        title: Text('sidebar_favorites'.tr()),
      ),
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
      return const _FavoriteListSkeleton();
    }

    return const Row(
      children: [
        SizedBox(width: 340, child: _FavoriteListSkeleton()),
        SizedBox(width: 12),
        Expanded(child: _FavoriteDetailSkeleton()),
      ],
    );
  }

  /// 构建错误状态界面
  Widget _buildError(BuildContext context, String message) {
    return Center(
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
            ? _EmptyFavorites(
                onRefresh: () => ref.invalidate(chatFavoriteListProvider),
              )
            : _NoMatchFavorites(onClearFilters: _clearFilters);
      }
      return _FavoriteListPanel(
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
              builder: (_) => _FavoriteDetailMobilePage(item: selectedItem),
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
          child: _FavoriteListPanel(
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
        return _EmptyFavorites(
          onRefresh: () => ref.invalidate(chatFavoriteListProvider),
        );
      }
      if (filtered.isEmpty) {
        return _NoMatchFavorites(onClearFilters: _clearFilters);
      }
      // 选中态尚未同步完成，短暂留白避免空指针
      return const SizedBox.shrink();
    }
    return _FavoriteDetailPanel(
      item: selected,
      onDelete: () => _confirmRemove(selected),
    );
  }
}

/// 收藏详情移动端页面
class _FavoriteDetailMobilePage extends ConsumerWidget {
  /// 收藏项对象
  final ChatFavorite item;

  const _FavoriteDetailMobilePage({required this.item});

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
        ? _displaySummary(item, item.detailText)
        : _displaySummary(item, item.summary);

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
      body: _FavoriteDetailPanel(
        item: item,
        onDelete: () => _remove(context, ref),
      ),
    );
  }
}

/// 收藏列表面板组件
class _FavoriteListPanel extends StatelessWidget {
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

  const _FavoriteListPanel({
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

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
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
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            'sidebar_favorites'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
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
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'favorite_count'.tr(args: [totalCount.toString()]),
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
              if (totalCount > 0) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: searchController,
                  onChanged: onQueryChanged,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'favorite_search_hint'.tr(),
                    hintStyle: TextStyle(
                      fontSize: 12.5,
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 30,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: availableTypes.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _TypeFilterChip(
                          label: 'favorite_all_types'.tr(),
                          icon: HugeIcons.strokeRoundedGrid,
                          selected: typeFilter == null,
                          onTap: () => onTypeChanged(null),
                        );
                      }
                      final type = availableTypes[index - 1];
                      return _TypeFilterChip(
                        label: _typeLabel(type),
                        icon: _typeStyle(type).icon,
                        selected: typeFilter == type,
                        onTap: () => onTypeChanged(type),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _FavoriteListItem(
              item: items[index],
              selected: items[index].id == selectedId,
              onTap: () => onSelect(items[index].id),
            ),
          ),
        ),
      ],
    );
  }
}

/// 收藏列表单项
class _FavoriteListItem extends StatelessWidget {
  final ChatFavorite item;
  final bool selected;
  final VoidCallback onTap;

  const _FavoriteListItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = _typeStyle(item.messageType);
    final color = _typeColor(context, item.messageType);

    return Material(
      color: selected ? color.withValues(alpha: .10) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
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
                      _displaySummary(item, item.summary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _TypeChip(type: item.messageType),
                    if (item.senderDisplayName.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.senderDisplayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(item.createdAt),
                            style: TextStyle(
                              fontSize: 11,
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
class _TypeFilterChip extends StatelessWidget {
  final String label;
  final List<List<dynamic>> icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeFilterChip({
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
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
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
                style: TextStyle(
                  fontSize: 12,
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
class _TypeChip extends StatelessWidget {
  final MessageType type;

  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(context, type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: _typeStyle(type).icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            _typeLabel(type),
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 收藏详情面板组件
class _FavoriteDetailPanel extends StatelessWidget {
  /// 收藏项对象
  final ChatFavorite item;

  /// 取消收藏回调
  final VoidCallback onDelete;

  const _FavoriteDetailPanel({required this.item, required this.onDelete});

  /// 是否为适合引文卡展示的短文本（单行且不超过 120 字符）
  bool _isRefinedTextDetail(ChatMessage message, String detailText) {
    if (message.messageType != MessageType.text) return false;

    final text = detailText.trim();
    if (text.isEmpty) return false;
    if (text.contains('\n')) return false;

    return text.length <= 120;
  }

  /// 媒体消息的说明文字（图片/视频/文件附带的 caption）
  String? _captionOf(ChatMessage message) {
    final type = message.messageType;
    if (type != MessageType.image &&
        type != MessageType.video &&
        type != MessageType.file) {
      return null;
    }
    final caption = message.payload?.content?.trim() ?? '';
    if (caption.isEmpty || _isPlaceholderSummary(caption)) return null;
    return caption;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final message = item.toChatMessage();
    final type = message.messageType ?? MessageType.text;
    final strategy = MessageRenderFactory.getStrategy(message.messageType);
    final detailFallback = item.detailText;
    final hasRenderableBody =
        (message.payload?.content?.trim().isNotEmpty ?? false) ||
        (message.payload?.quillDelta?.trim().isNotEmpty ?? false) ||
        (message.payload?.mediaAttachments.isNotEmpty ?? false);
    final isRefinedTextDetail = _isRefinedTextDetail(message, detailFallback);
    final style = _typeStyle(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: cs.outlineVariant.withValues(alpha: .6),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: SizedBox.square(
                    dimension: 14,
                    child: HugeIcon(
                      icon: style.icon,
                      size: 13,
                      color: _typeColor(context, type),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'chat_favorite'.tr(),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        _TypeChip(type: type),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (item.senderAvatar.isNotEmpty ||
                            item.senderDisplayName.isNotEmpty) ...[
                          AvatarWidget(
                            size: 18,
                            url: item.senderAvatar,
                            name: item.senderDisplayName,
                            borderRadius: 9,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            item.senderDisplayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (item.senderDisplayName.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: cs.outlineVariant,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            _formatDate(item.createdAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'chat_copy'.tr(),
                onPressed: () async {
                  final copyText = detailFallback.trim().isNotEmpty
                      ? _displaySummary(item, detailFallback)
                      : _displaySummary(item, item.summary);
                  await Clipboard.setData(ClipboardData(text: copyText));
                  if (!context.mounted) return;
                  Toast.showToast(
                    'chat_copy_success'.tr(),
                    type: ToastType.success,
                  );
                },
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCopy01,
                  size: 17,
                ),
              ),
              IconButton(
                tooltip: 'favorite_remove'.tr(),
                onPressed: onDelete,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  size: 17,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: _buildDetailBody(
              context,
              message,
              strategy,
              detailFallback,
              hasRenderableBody,
              isRefinedTextDetail,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailBody(
    BuildContext context,
    ChatMessage message,
    MessageRenderStrategy strategy,
    String detailFallback,
    bool hasRenderableBody,
    bool isRefinedTextDetail,
  ) {
    final cs = Theme.of(context).colorScheme;

    // 短文本：引文卡片
    if (isRefinedTextDetail) {
      return _FavoriteTextDetailCard(
        text: detailFallback,
        senderName: item.senderDisplayName,
        dateLabel: _formatDate(item.createdAt),
      );
    }

    // 记事本卡片：展示完整快照内容（标题 + 更新时间 + 多行正文）
    final card = message.payload?.card;
    if (card?.cardType == 'note') {
      return _FavoriteNoteDetailCard(
        title: card!.displayTitle.isEmpty
            ? 'note_untitled'.tr()
            : card.displayTitle,
        updatedMs: int.tryParse(card.properties['updatedAt'] ?? ''),
        content: resolveNoteCardContent(card),
      );
    }

    // 纯文本：可选中文本卡片
    if (message.messageType == MessageType.text) {
      return _TextDetailCard(
        text: detailFallback.isEmpty
            ? 'favorite_empty_placeholder'.tr()
            : detailFallback,
      );
    }

    // 媒体 / 富文本：策略渲染 + 可选说明文字
    if (hasRenderableBody) {
      final caption = _captionOf(message);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FavoriteContentCard(
            child: strategy.buildContent(context, message, cs.onSurface),
          ),
          if (caption != null) ...[
            const SizedBox(height: 12),
            _TextDetailCard(text: caption),
          ],
        ],
      );
    }

    return _TextDetailCard(
      text: _displaySummary(item, detailFallback).isEmpty
          ? 'favorite_empty_placeholder'.tr()
          : _displaySummary(item, detailFallback),
    );
  }
}

/// 通用内容卡片容器（媒体 / 富文本）
class _FavoriteContentCard extends StatelessWidget {
  final Widget child;

  const _FavoriteContentCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceContainerHighest.withValues(alpha: .5),
            cs.surfaceContainerLow.withValues(alpha: .6),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .5)),
      ),
      child: child,
    );
  }
}

/// 记事本卡片收藏详情：标题 + 更新时间 + 完整快照内容（多行）
class _FavoriteNoteDetailCard extends StatelessWidget {
  final String title;
  final int? updatedMs;
  final String content;

  const _FavoriteNoteDetailCard({
    required this.title,
    required this.updatedMs,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceContainerHighest.withValues(alpha: .55),
            cs.surfaceContainerLow.withValues(alpha: .75),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedNote01,
                  size: 14,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'note_card_label'.tr(),
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (updatedMs != null && updatedMs! > 0)
                Text(
                  _formatDate(DateTime.fromMillisecondsSinceEpoch(updatedMs!)),
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, thickness: 0.5, color: cs.outlineVariant),
          const SizedBox(height: 12),
          SelectableText(
            content.isEmpty ? 'note_card_no_content'.tr() : content,
            style: TextStyle(fontSize: 15, height: 1.7, color: cs.onSurface),
          ),
        ],
      ),
    );
  }
}

/// 文本内容卡片（可选中复制）
class _TextDetailCard extends StatelessWidget {
  final String text;

  const _TextDetailCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .5)),
      ),
      child: SelectableText(
        text,
        style: TextStyle(fontSize: 15, height: 1.7, color: cs.onSurface),
      ),
    );
  }
}

/// 短文本引文卡片
class _FavoriteTextDetailCard extends StatelessWidget {
  final String text;
  final String senderName;
  final String dateLabel;

  const _FavoriteTextDetailCard({
    required this.text,
    required this.senderName,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceContainerHighest.withValues(alpha: .55),
            cs.surfaceContainerLow.withValues(alpha: .75),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedQuoteDown,
                size: 18,
                color: cs.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'favorite_text_type'.tr(),
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                dateLabel,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            text,
            style: TextStyle(
              fontSize: 16,
              height: 1.7,
              color: cs.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (senderName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '— $senderName',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 空收藏状态
class _EmptyFavorites extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyFavorites({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mobile = DeviceUtil.isMobile(context);
    final iconContainerSize = mobile ? 72.0 : 96.0;
    final iconSize = mobile ? 30.0 : 40.0;

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
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedBookmark03,
              size: iconSize,
              color: cs.primary,
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
class _NoMatchFavorites extends StatelessWidget {
  final VoidCallback onClearFilters;

  const _NoMatchFavorites({required this.onClearFilters});

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

/// 收藏列表骨架屏
class _FavoriteListSkeleton extends StatelessWidget {
  const _FavoriteListSkeleton();

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
                  borderRadius: BorderRadius.circular(14),
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

/// 收藏详情骨架屏
class _FavoriteDetailSkeleton extends StatelessWidget {
  const _FavoriteDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 42, height: 42, radius: 12),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(width: 120, height: 16),
                  SizedBox(height: 8),
                  SkeletonLine(width: 90, height: 11),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          SkeletonBox(width: double.infinity, height: 220, radius: 14),
        ],
      ),
    );
  }
}

/// 消息类型展示样式（图标 + 主题色）
class _TypeStyle {
  final List<List<dynamic>> icon;
  final MaterialColor color;

  const _TypeStyle(this.icon, this.color);
}

const Map<MessageType, _TypeStyle> _typeStyles = {
  MessageType.text: _TypeStyle(HugeIcons.strokeRoundedQuoteDown, Colors.blue),
  MessageType.richText: _TypeStyle(HugeIcons.strokeRoundedFile02, Colors.teal),
  MessageType.image: _TypeStyle(HugeIcons.strokeRoundedImage01, Colors.purple),
  MessageType.audio: _TypeStyle(HugeIcons.strokeRoundedMic01, Colors.orange),
  MessageType.video: _TypeStyle(HugeIcons.strokeRoundedVideo01, Colors.red),
  MessageType.file: _TypeStyle(HugeIcons.strokeRoundedFile02, Colors.indigo),
  MessageType.emoji: _TypeStyle(HugeIcons.strokeRoundedHappy01, Colors.amber),
  MessageType.location: _TypeStyle(
    HugeIcons.strokeRoundedLocation01,
    Colors.green,
  ),
  MessageType.card: _TypeStyle(HugeIcons.strokeRoundedBadge, Colors.cyan),
  MessageType.system: _TypeStyle(
    HugeIcons.strokeRoundedInformationCircle,
    Colors.blueGrey,
  ),
};

/// 获取消息类型的展示样式
_TypeStyle _typeStyle(MessageType type) {
  return _typeStyles[type] ??
      const _TypeStyle(HugeIcons.strokeRoundedFile01, Colors.blueGrey);
}

/// 获取消息类型在明暗主题下适配的展示颜色
Color _typeColor(BuildContext context, MessageType type) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final material = _typeStyle(type).color;
  return isDark ? material.shade300 : material.shade600;
}

/// 获取消息类型的本地化名称
String _typeLabel(MessageType type) {
  return switch (type) {
    MessageType.text => 'favorite_type_text'.tr(),
    MessageType.richText => 'favorite_type_rich_text'.tr(),
    MessageType.image => 'favorite_type_image'.tr(),
    MessageType.audio => 'favorite_type_audio'.tr(),
    MessageType.video => 'favorite_type_video'.tr(),
    MessageType.file => 'favorite_type_file'.tr(),
    MessageType.emoji => 'favorite_type_emoji'.tr(),
    MessageType.location => 'favorite_type_location'.tr(),
    MessageType.card => 'favorite_type_card'.tr(),
    MessageType.codeSnippet => 'favorite_type_code'.tr(),
    MessageType.system => 'favorite_type_system'.tr(),
  };
}

/// 是否为协议媒体占位标记（如 `[image]`、`[IMAGE]`、`[empty]`）
bool _isPlaceholderSummary(String text) {
  const markers = {
    '[image]',
    '[audio]',
    '[video]',
    '[file]',
    '[emoji]',
    '[location]',
    '[card]',
    '[system]',
    '[empty]',
  };
  return markers.contains(text.trim().toLowerCase());
}

/// 获取收藏项的展示文本
///
/// 协议占位标记（如 `[image]`）对用户无意义，映射为本地化类型标签。
String _displaySummary(ChatFavorite item, String text) {
  final trimmed = text.trim();
  if (_isPlaceholderSummary(trimmed)) {
    return _typeLabel(item.messageType);
  }
  return trimmed;
}

String _formatDate(DateTime? dt) {
  if (dt == null) return '--';

  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}
