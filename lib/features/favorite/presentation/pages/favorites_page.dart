import 'package:anoxia/common/utils/DeviceUtil.dart';
import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/SkeletonBox.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/base/message_render_factory.dart';
import 'package:anoxia/framework/domain/ChatFavorite.dart';
import 'package:anoxia/framework/domain/ChatMessage.dart';
import 'package:anoxia/framework/protocol/message/MessageEunm.dart';
import 'package:anoxia/framework/provider/chat/favorite/chat_favorite_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 收藏页面
///
/// 显示用户收藏的消息列表，支持查看详情、复制等功能
/// 移动端和桌面端采用不同的布局方式
class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  /// 当前选中的收藏项 ID
  int? _selectedId;

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(chatFavoriteListProvider);

    final body = favoritesAsync.when(
      loading: () => _buildLoading(context),
      error: (e, _) => _buildError(context, e.toString()),
      data: (items) {
        _syncSelection(items);
        return _buildLoaded(context, items);
      },
    );

    return body;
  }

  /// 同步选中状态
  ///
  /// 确保当前选中的收藏项仍然存在于列表中，否则更新选中状态
  ///
  /// [items] 收藏项列表
  void _syncSelection(List<ChatFavorite> items) {
    if (items.isEmpty) return;

    final isMobile = DeviceUtil.isRealMobile();

    if (isMobile) {
      final stillExists =
          _selectedId != null &&
          items.any((element) => element.id == _selectedId);
      if (stillExists || _selectedId == null) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedId = null);
      });
      return;
    }

    final stillExists =
        _selectedId != null &&
        items.any((element) => element.id == _selectedId);
    if (stillExists) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _selectedId = items.first.id);
    });
  }

  /// 构建加载状态界面
  ///
  /// [context] 上下文
  /// 返回 加载状态 Widget
  Widget _buildLoading(BuildContext context) {
    final mobile = DeviceUtil.isRealMobile();
    if (mobile) {
      return const _FavoriteListSkeleton();
    }

    return const Row(
      children: [
        SizedBox(width: 340, child: _FavoriteListSkeleton()),
        VerticalDivider(width: 1),
        Expanded(child: _FavoriteDetailSkeleton()),
      ],
    );
  }

  /// 构建错误状态界面
  ///
  /// [context] 上下文
  /// [message] 错误消息
  /// 返回 错误状态 Widget
  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
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
  ///
  /// [context] 上下文
  /// [items] 收藏项列表
  /// 返回 已加载状态 Widget
  Widget _buildLoaded(BuildContext context, List<ChatFavorite> items) {
    final mobile = DeviceUtil.isRealMobile();

    if (items.isEmpty) {
      return _EmptyFavorites(
        onRefresh: () => ref.invalidate(chatFavoriteListProvider),
      );
    }

    final selected = items.where((e) => e.id == _selectedId).firstOrNull;

    if (mobile) {
      return _FavoriteListPanel(
        items: items,
        selectedId: null,
        onSelect: (id) {
          final selectedItem = items.where((e) => e.id == id).firstOrNull;
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

    return Row(
      children: [
        SizedBox(
          width: 340,
          child: _FavoriteListPanel(
            items: items,
            selectedId: _selectedId,
            onSelect: (id) => setState(() => _selectedId = id),
            onRefresh: () => ref.invalidate(chatFavoriteListProvider),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: selected == null
              ? _EmptyFavorites(
                  onRefresh: () => ref.invalidate(chatFavoriteListProvider),
                )
              : _FavoriteDetailPanel(item: selected),
        ),
      ],
    );
  }
}

/// 收藏详情移动端页面
class _FavoriteDetailMobilePage extends StatelessWidget {
  /// 收藏项对象
  final ChatFavorite item;

  const _FavoriteDetailMobilePage({required this.item});

  @override
  Widget build(BuildContext context) {
    final copyText = item.detailText.trim().isNotEmpty
        ? item.detailText
        : item.summary;

    return Scaffold(
      backgroundColor: DeviceUtil.isRealDesktop()
          ? Colors.transparent
          : Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('chat_favorite'.tr()),
        actions: [
          IconButton(
            tooltip: 'chat_copy'.tr(),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: copyText));
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('chat_copy_success'.tr())));
            },
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: _FavoriteDetailPanel(item: item),
    );
  }
}

/// 收藏列表面板组件
class _FavoriteListPanel extends StatelessWidget {
  /// 收藏项列表
  final List<ChatFavorite> items;
  
  /// 当前选中的收藏项 ID
  final int? selectedId;
  
  /// 选择回调
  final ValueChanged<int> onSelect;
  
  /// 刷新回调
  final VoidCallback onRefresh;

  const _FavoriteListPanel({
    required this.items,
    required this.selectedId,
    required this.onSelect,
    required this.onRefresh,
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
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.bookmark_rounded,
                  color: cs.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'sidebar_favorites'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'sidebar_favorites_subtitle'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'call_window_retry'.tr(),
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 20),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final selected = item.id == selectedId;
              return Material(
                color: selected
                    ? cs.primaryContainer.withValues(alpha: .5)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSelect(item.id),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AvatarWidget(
                          size: 40,
                          url: item.senderAvatar,
                          name: item.senderDisplayName.isNotEmpty
                              ? item.senderDisplayName
                              : item.typeLabel,
                          borderRadius: 10,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.summary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.typeLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (item.senderDisplayName.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.senderDisplayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(item.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 收藏详情面板组件
class _FavoriteDetailPanel extends StatelessWidget {
  /// 收藏项对象
  final ChatFavorite item;

  const _FavoriteDetailPanel({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final message = item.toChatMessage();
    final strategy = MessageRenderFactory.getStrategy(message.messageType);
    final detailFallback = item.detailText;
    final hasRenderableBody =
        (message.payload?.content?.trim().isNotEmpty ?? false) ||
        (message.payload?.quillDelta?.trim().isNotEmpty ?? false) ||
        message.attachments.isNotEmpty;
    final isRefinedTextDetail = _isRefinedTextDetail(message, detailFallback);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: cs.outlineVariant.withValues(alpha: .6),
              ),
            ),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'chat_favorite'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.typeLabel,
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (item.senderDisplayName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.senderDisplayName,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Text(
                _formatDate(item.createdAt),
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: isRefinedTextDetail
                ? _FavoriteTextDetailCard(
                    text: detailFallback,
                    senderName: item.senderDisplayName,
                    dateLabel: _formatDate(item.createdAt),
                  )
                : hasRenderableBody
                ? strategy.buildContent(context, message, cs.onSurface)
                : SelectableText(
                    detailFallback.isEmpty
                        ? 'favorite_empty_placeholder'.tr()
                        : detailFallback,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: cs.onSurface,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  bool _isRefinedTextDetail(ChatMessage message, String detailText) {
    if (message.messageType != MessageType.text) return false;

    final text = detailText.trim();
    if (text.isEmpty) return false;
    if (text.contains('\n')) return false;

    return text.length <= 120;
  }
}

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
              Icon(Icons.format_quote_rounded, size: 18, color: cs.primary),
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

class _EmptyFavorites extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyFavorites({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmarks_outlined, size: 34, color: cs.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            'chat_no_messages'.tr(),
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          FilledButton.tonal(
            onPressed: onRefresh,
            child: Text('call_window_retry'.tr()),
          ),
        ],
      ),
    );
  }
}

class _FavoriteListSkeleton extends StatelessWidget {
  const _FavoriteListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: const Row(
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
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                ),
                child: const Row(
                  children: [
                    SkeletonBox(width: 40, height: 40, radius: 10),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLine(width: 180, height: 12),
                          SizedBox(height: 8),
                          SkeletonLine(width: 64, height: 10),
                          SizedBox(height: 8),
                          SkeletonLine(width: 110, height: 10),
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

class _FavoriteDetailSkeleton extends StatelessWidget {
  const _FavoriteDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLine(width: 110, height: 18),
          SizedBox(height: 12),
          SkeletonLine(width: 80, height: 12),
          SizedBox(height: 22),
          SkeletonLine(width: 260, height: 12),
          SizedBox(height: 10),
          SkeletonLine(width: 220, height: 12),
          SizedBox(height: 10),
          SkeletonLine(width: 300, height: 12),
          SizedBox(height: 20),
          SkeletonBox(width: double.infinity, height: 220, radius: 12),
        ],
      ),
    );
  }
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
