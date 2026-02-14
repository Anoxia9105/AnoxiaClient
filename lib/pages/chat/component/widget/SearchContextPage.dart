import 'package:anoxia/common/widgets/AvatarWidget.dart';
import 'package:anoxia/framework/domain/ChatMessage.dart';
import 'package:anoxia/framework/provider/chat/message/search_message_service.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';


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
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  /// 滚动控制器，用于监听滚动事件
  final ScrollController _scrollController = ScrollController();
  /// 搜索输入框控制器
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 添加滚动监听器
    _scrollController.addListener(_onScroll);
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
      final firstIndex = position.reduce((a, b) => a.index < b.index ? a : b).index;
      final lastIndex = position.reduce((a, b) => a.index > b.index ? a : b).index;

      // 触顶加载更多历史消息
      if (firstIndex == 0 && searchState.hasMoreBefore) {
        _loadMoreBefore();
      }

      // 触底加载更多新消息
      if (lastIndex == searchState.messages.length - 1 && searchState.hasMoreAfter) {
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

    await ref.read(searchMessageServiceProvider.notifier).loadMoreBefore(
          widget.roomId,
          keyword,
        );
  }

  /// 加载更多新消息
  Future<void> _loadMoreAfter() async {
    final searchState = ref.read(searchMessageServiceProvider);
    if (searchState.isLoading || !searchState.hasMoreAfter) return;

    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    await ref.read(searchMessageServiceProvider.notifier).loadMoreAfter(
          widget.roomId,
          keyword,
        );
  }

  /// 构建消息项
  Widget _buildMessageItem(dynamic message, int index) {
    // 判断是否在高亮范围内
    final searchState = ref.read(searchMessageServiceProvider);
    bool isHighlighted = index >= searchState.firstMatchIndex && index <= searchState.lastMatchIndex;

    // 确保消息是 ChatMessage 类型
    final chatMessage = message is Map ? null : message as ChatMessage?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlighted 
            ? Colors.yellow.withOpacity(0.3) 
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户头像
          AvatarWidget(
            size: 36,
            name: '用户 ${chatMessage?.senderId ?? '未知'}',
            borderRadius: 18,
          ),
          const SizedBox(width: 12),
          // 消息内容区域
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 消息发送者
                Text(
                  '用户 ${chatMessage?.senderId ?? '未知'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                // 消息内容
                Text(
                  chatMessage?.content ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                // 消息时间
                Text(
                  _formatTime(chatMessage?.timestamp),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化时间
  String _formatTime(int? timestamp) {
    if (timestamp == null) return '';
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  /// 执行搜索
  void _performSearch() {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    // 使用 Future.delayed 来避免在 widget 构建过程中修改 provider
    Future.delayed(Duration.zero, () {
      ref.read(searchMessageServiceProvider.notifier).searchMessages(
            widget.roomId,
            keyword,
          ).then((_) {
        // 搜索完成后，自动跳转到第一个匹配消息的位置
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final searchState = ref.read(searchMessageServiceProvider);
          if (searchState.firstMatchIndex >= 0) {
            _scrollToIndex(searchState.firstMatchIndex);
          }
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchMessageServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${'search_context_title'.tr()} - ${widget.roomName}',
          style: const TextStyle(fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 搜索输入栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'appbar_search_hint'.tr(),
                      border: OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (value) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _performSearch,
                  child: Text('search'.tr()),
                ),
              ],
            ),
          ),
          // 搜索结果信息栏
          if (searchState.messages.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${'search_context_matches'.tr()}: ${searchState.lastMatchIndex - searchState.firstMatchIndex + 1}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
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
                if (searchState.messages.isNotEmpty)
                  ScrollablePositionedList.builder(
                    itemScrollController: _itemScrollController,
                    itemPositionsListener: _itemPositionsListener,
                    itemCount: searchState.messages.length,
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
                        Icon(
                          Icons.search,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'search_context_empty'.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                // 加载指示器
                if (searchState.isLoading) 
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
