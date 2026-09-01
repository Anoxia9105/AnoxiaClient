import 'package:anoxia/common/utils/device_util.dart';
import 'package:anoxia/framework/provider/chat/message/search_message_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'search_context_message_item.dart';
import 'search_context_skeleton.dart';
import 'package:anoxia/framework/theme/radius_token.dart';

/// 聊天上下文深度搜索页面
/// 功能：显示搜索结果列表，自动定位到匹配消息，高亮显示匹配范围
class SearchContextPage extends ConsumerStatefulWidget {
  /// 房间ID
  final String roomId;

  /// 房间名称
  final String roomName;

  const SearchContextPage({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  ConsumerState<SearchContextPage> createState() => _SearchContextPageState();
}

class _SearchContextPageState extends ConsumerState<SearchContextPage> {
  /// 列表控制器，用于定位到指定索引
  final ItemScrollController _itemScrollController = ItemScrollController();

  /// 列表监听，用于检测滚动位置
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  /// 搜索输入框控制器
  final TextEditingController _searchController = TextEditingController();

  /// 边界触发锁，避免停留在顶部/底部时重复触发 loadMore
  bool _topLoadLatched = false;
  bool _bottomLoadLatched = false;

  @override
  void initState() {
    super.initState();
    // ScrollablePositionedList 不使用 ScrollController，改为监听 item positions
    _itemPositionsListener.itemPositions.addListener(_onScroll);
    // 页面加载时清空上次的搜索结果
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchMessageServiceProvider.notifier).reset();
      _searchController.clear();
    });
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onScroll);
    _searchController.dispose();
    super.dispose();
  }

  /// 滚动到指定索引
  void _scrollToIndex(int index) {
    final searchState = ref.read(searchMessageServiceProvider);
    if (index >= 0 && index < searchState.messages.length) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 滚动事件处理函数
  void _onScroll() {
    // 检测滚动位置，实现触顶/触底加载
    final searchState = ref.read(searchMessageServiceProvider);
    final position = _itemPositionsListener.itemPositions.value;
    if (position.isEmpty || searchState.messages.isEmpty) return;

    final firstIndex = position
        .reduce((a, b) => a.index < b.index ? a : b)
        .index;
    final lastIndex = position
        .reduce((a, b) => a.index > b.index ? a : b)
        .index;

    final atTop = firstIndex == 0;
    final atBottom = lastIndex == searchState.messages.length - 1;

    if (!atTop) {
      _topLoadLatched = false;
    }
    if (!atBottom) {
      _bottomLoadLatched = false;
    }

    // 触顶加载更多历史消息（单次触发，离开边界后才可再次触发）
    if (atTop &&
        !_topLoadLatched &&
        !searchState.isLoading &&
        searchState.hasMoreBefore) {
      _topLoadLatched = true;
      _loadMoreBefore();
    }

    // 触底加载更多新消息（单次触发，离开边界后才可再次触发）
    if (atBottom &&
        !_bottomLoadLatched &&
        !searchState.isLoading &&
        searchState.hasMoreAfter) {
      _bottomLoadLatched = true;
      _loadMoreAfter();
    }
  }

  /// 加载更多历史消息
  Future<void> _loadMoreBefore() async {
    final searchState = ref.read(searchMessageServiceProvider);
    if (searchState.isLoading || !searchState.hasMoreBefore) return;

    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    await ref
        .read(searchMessageServiceProvider.notifier)
        .loadMoreBefore(widget.roomId, keyword);
  }

  /// 加载更多新消息
  Future<void> _loadMoreAfter() async {
    final searchState = ref.read(searchMessageServiceProvider);
    if (searchState.isLoading || !searchState.hasMoreAfter) return;

    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    await ref
        .read(searchMessageServiceProvider.notifier)
        .loadMoreAfter(widget.roomId, keyword);
  }

  /// 执行搜索
  Future<void> _performSearch() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    _topLoadLatched = false;
    _bottomLoadLatched = false;

    await ref
        .read(searchMessageServiceProvider.notifier)
        .searchMessages(widget.roomId, keyword);

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchState = ref.read(searchMessageServiceProvider);
      if (searchState.firstMatchIndex >= 0) {
        _scrollToIndex(searchState.firstMatchIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchMessageServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bool isDesktop = DeviceUtil.isRealDesktop();

    final content = Column(
      children: [
        // 搜索输入栏
        Padding(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 16 : 8,
            8,
            isDesktop ? 16 : 8,
            8,
          ),
          child: Material(
            color: colorScheme.surface,
            elevation: isDesktop ? 1 : 0,
            borderRadius: BorderRadius.circular(RadiusToken.xl),
            child: TextField(
              controller: _searchController,
              style: textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'appbar_search_hint'.tr(),
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                ),
                prefixIcon: SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch02,
                      color: colorScheme.outline,
                      size: 16,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty && !searchState.isLoading
                    ? IconButton(
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          color: colorScheme.outline,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _topLoadLatched = false;
                          _bottomLoadLatched = false;
                          ref
                              .read(searchMessageServiceProvider.notifier)
                              .reset();
                          setState(() {});
                        },
                        splashRadius: 20,
                      )
                    : IconButton(
                        onPressed: searchState.isLoading
                            ? null
                            : _performSearch,
                        icon: searchState.isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : const HugeIcon(
                                icon: HugeIcons.strokeRoundedSearch01,
                                size: 20,
                              ),
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _performSearch(),
              onChanged: (value) => setState(() {}),
            ),
          ),
        ),
        // 搜索结果信息栏
        if (searchState.messages.isNotEmpty)
          Container(
            margin: EdgeInsets.fromLTRB(
              isDesktop ? 16 : 0,
              0,
              isDesktop ? 16 : 0,
              0,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: isDesktop
                  ? const BorderRadius.vertical(top: Radius.circular(12))
                  : BorderRadius.zero,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${'search_context_matches'.tr()}: ${searchState.totalMatches} / ${searchState.messages.length}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // 消息列表
        Expanded(
          child: Stack(
            children: [
              if (searchState.isLoading && searchState.messages.isEmpty)
                const SearchContextSkeleton(),
              if (searchState.messages.isNotEmpty)
                ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  itemCount: searchState.messages.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final message = searchState.messages[index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 220),
                      child: SlideAnimation(
                        verticalOffset: 18,
                        child: FadeInAnimation(
                          child: SearchContextMessageItem(
                            message: message,
                            index: index,
                            roomId: widget.roomId,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              if (searchState.messages.isEmpty && !searchState.isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(RadiusToken.xl),
                          ),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedSearch02,
                            size: 64,
                            color: colorScheme.outline.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'search_context_empty'.tr(),
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'appbar_enter_search'.tr(),
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.outline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              // 有结果时的增量加载提示：不再遮挡列表
              if (searchState.isLoading && searchState.messages.isNotEmpty)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: colorScheme.primary,
                    backgroundColor: colorScheme.primary.withValues(
                      alpha: 0.15,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'search_context_title'.tr(),
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: DeviceUtil.isRealMobile(),
      ),
      body: SafeArea(
        child: isDesktop
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: content,
                ),
              )
            : content,
      ),
    );
  }
}
