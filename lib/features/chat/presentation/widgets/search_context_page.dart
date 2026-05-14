import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/common/widgets/SkeletonBox.dart';
import 'package:anoxia/framework/domain/ChatMessage.dart';
import 'package:anoxia/framework/protocol/message/MessageEunm.dart';
import 'package:anoxia/framework/provider/chat/message/search_message_service.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hugeicons/hugeicons.dart';

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

  /// 滚动控制器，用于监听滚动事件
  final ScrollController _scrollController = ScrollController();

  /// 搜索输入框控制器
  final TextEditingController _searchController = TextEditingController();

  /// 是否正在搜索
  bool _isSearching = false;

  /// 已保存的搜索关键词（用于高亮）
  String _savedKeyword = '';

  @override
  void initState() {
    super.initState();
    // 添加滚动监听器
    _scrollController.addListener(_onScroll);
    // 页面加载时清空上次的搜索结果
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchMessageServiceProvider.notifier).reset();
      _savedKeyword = '';
      _searchController.clear();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    if (position.isNotEmpty) {
      final firstIndex = position
          .reduce((a, b) => a.index < b.index ? a : b)
          .index;
      final lastIndex = position
          .reduce((a, b) => a.index > b.index ? a : b)
          .index;

      // 触顶加载更多历史消息
      if (firstIndex == 0 && searchState.hasMoreBefore) {
        _loadMoreBefore();
      }

      // 触底加载更多新消息
      if (lastIndex == searchState.messages.length - 1 &&
          searchState.hasMoreAfter) {
        _loadMoreAfter();
      }
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

  /// 构建消息项
  Widget _buildMessageItem(ChatMessage chatMessage, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 判断是否在高亮范围内
    final searchState = ref.read(searchMessageServiceProvider);
    bool isHighlighted =
        index >= searchState.firstMatchIndex &&
        index <= searchState.lastMatchIndex;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlighted
            ? colorScheme.primary.withValues(alpha: 0.08)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: isHighlighted ? 1.5 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户头像
            AvatarWidget(
              size: 40,
              url: '',
              name: chatMessage.senderId?.toString() ?? 'search_unknown'.tr(),
              borderRadius: 20,
            ),
            const SizedBox(width: 12),
            // 消息内容区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 消息发送者和时间
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'search_user_prefix'.tr(
                            args: [
                              chatMessage.senderId?.toString() ??
                                  'search_unknown'.tr(),
                            ],
                          ),
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.outline,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(chatMessage.timestamp),
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.outline.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 消息内容（根据消息类型显示）
                  _buildMessageContent(chatMessage, colorScheme, textTheme),
                ],
              ),
            ),
            // 高亮指示器
            if (isHighlighted) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建消息内容（根据消息类型显示）
  Widget _buildMessageContent(
    ChatMessage chatMessage,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // 使用保存的搜索关键词，而不是从搜索框获取
    final keyword = _savedKeyword;

    // 检查消息类型（image: 1）
    if (chatMessage.messageType == MessageType.image ||
        (chatMessage.attachments.isNotEmpty &&
            chatMessage.attachments.first.type?.startsWith('image') == true)) {
      // 图片消息：显示附件缩略图
      if (chatMessage.attachments.isNotEmpty) {
        final attachment = chatMessage.attachments.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 显示图片缩略图
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                attachment.url ?? '',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: colorScheme.outline,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (chatMessage.content.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              _buildHighlightedText(
                chatMessage.content,
                keyword,
                colorScheme,
                textTheme,
                maxLines: 2,
              ),
            ],
          ],
        );
      } else {
        return Text(
          'search_image_placeholder'.tr(),
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontStyle: FontStyle.italic,
          ),
        );
      }
    }

    // 其他消息类型：显示文本内容（带高亮）
    return _buildHighlightedText(
      chatMessage.content,
      keyword,
      colorScheme,
      textTheme,
      maxLines: 3,
    );
  }

  /// 构建高亮文本
  Widget _buildHighlightedText(
    String text,
    String keyword,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    int maxLines = 3,
  }) {
    if (keyword.isEmpty || !text.contains(keyword)) {
      return Text(
        text,
        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    // 使用手动查找替换而不是 RegExp.split
    final spans = <TextSpan>[];
    int lastIndex = 0;

    // 查找所有匹配的关键词位置
    while (true) {
      // 不区分大小写的查找（对于中文实际上没区别）
      int index = text.indexOf(keyword, lastIndex);

      if (index == -1) {
        // 没有找到，添加剩余的文本
        if (lastIndex < text.length) {
          spans.add(
            TextSpan(
              text: text.substring(lastIndex),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          );
        }
        break;
      }

      // 添加关键词之前的文本
      if (index > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, index),
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
        );
      }

      // 添加高亮的关键词
      spans.add(
        TextSpan(
          text: keyword,
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            backgroundColor: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

      // 更新位置
      lastIndex = index + keyword.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 格式化时间
  String _formatTime(int? timestamp) {
    if (timestamp == null) return '';
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('HH:mm').format(dateTime);
  }

  /// 执行搜索
  void _performSearch() {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    // 保存关键词用于高亮显示
    _savedKeyword = keyword;

    setState(() => _isSearching = true);

    // 使用 Future.delayed 来避免在 widget 构建过程中修改 provider
    Future.delayed(Duration.zero, () {
      ref
          .read(searchMessageServiceProvider.notifier)
          .searchMessages(widget.roomId, keyword)
          .then((_) {
            setState(() => _isSearching = false);
            // 搜索完成后，自动跳转到第一个匹配消息的位置
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final searchState = ref.read(searchMessageServiceProvider);
              if (searchState.firstMatchIndex >= 0) {
                _scrollToIndex(searchState.firstMatchIndex);
              }
            });
          })
          .catchError((_) {
            setState(() => _isSearching = false);
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchMessageServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'search_context_title'.tr(),
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // 搜索输入栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'appbar_search_hint'.tr(),
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.outline,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty && _isSearching
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: colorScheme.outline,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _savedKeyword = '';
                          setState(() {});
                        },
                        splashRadius: 20,
                      )
                    : IconButton(
                        onPressed: _isSearching ? null : _performSearch,
                        icon: _isSearching
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
              onSubmitted: (value) => _performSearch(),
              onChanged: (value) => setState(() {}),
            ),
          ),
          // 搜索结果信息栏
          if (searchState.messages.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
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
                  const _SearchContextSkeleton(),
                if (searchState.messages.isNotEmpty)
                  ScrollablePositionedList.builder(
                    itemScrollController: _itemScrollController,
                    itemPositionsListener: _itemPositionsListener,
                    itemCount: searchState.messages.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final message = searchState.messages[index];
                      return _buildMessageItem(message, index);
                    },
                  ),
                if (searchState.messages.isEmpty && !searchState.isLoading)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(32),
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
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'appbar_enter_search'.tr(),
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
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
      ),
    );
  }
}

class _SearchContextSkeleton extends StatelessWidget {
  const _SearchContextSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 8,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.25),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 40, height: 40, circle: true),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 120, height: 10),
                    SizedBox(height: 8),
                    SkeletonBox(height: 12),
                    SizedBox(height: 6),
                    SkeletonBox(width: 180, height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
