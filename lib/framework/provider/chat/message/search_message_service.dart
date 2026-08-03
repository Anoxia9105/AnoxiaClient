import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/provider/core/message_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../logs/talker.dart';

part 'search_message_service.g.dart';

/// 搜索消息服务
/// 功能：提供消息搜索、加载更多搜索结果等功能
@Riverpod(keepAlive: true)
class SearchMessageService extends _$SearchMessageService {
  final int _pageSize = 50;
  final int _pageStep = 30;
  final int _maxContextSize = 200;

  @override
  SearchState build() {
    return SearchState(
      isLoading: false,
      keyword: '',
      messages: [],
      hasMoreBefore: false,
      hasMoreAfter: false,
      contextSize: _pageSize,
      minSeq: 0,
      maxSeq: 0,
      firstMatchIndex: -1,
      lastMatchIndex: -1,
      totalMatches: 0,
    );
  }

  /// 搜索消息
  /// [roomId] 房间ID
  /// [keyword] 搜索关键词
  Future<void> searchMessages(String roomId, String keyword) async {
    await _searchMessagesInternal(roomId, keyword, _pageSize);
  }

  Future<void> _searchMessagesInternal(
    String roomId,
    String keyword,
    int contextSize,
  ) async {
    if (state.isLoading) return;

    final normalizedKeyword = keyword.trim();
    if (normalizedKeyword.isEmpty) {
      reset();
      return;
    }

    final effectiveContextSize = contextSize.clamp(5, _maxContextSize);

    state = state.copyWith(isLoading: true, keyword: normalizedKeyword);

    try {
      final result = await ref.read(messageRepositoryProvider).searchMessages(
            roomId,
            normalizedKeyword,
            contextSize: effectiveContextSize,
          );

      state = state.copyWith(
        isLoading: false,
        keyword: normalizedKeyword,
        messages: result.messages,
        firstMatchIndex: result.firstMatchIndex,
        lastMatchIndex: result.lastMatchIndex,
        hasMoreBefore: result.hasMoreBefore,
        hasMoreAfter: result.hasMoreAfter,
        contextSize: effectiveContextSize,
        minSeq: result.minSeq,
        maxSeq: result.maxSeq,
        totalMatches: result.totalMatches,
      );
    } catch (e) {
      log.error('搜索消息失败: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// 加载更多历史搜索结果
  Future<void> loadMoreBefore(String roomId, String keyword) async {
    if (state.isLoading || !state.hasMoreBefore) return;

    if (state.contextSize >= _maxContextSize) {
      state = state.copyWith(hasMoreBefore: false);
      return;
    }

    final nextContextSize = state.contextSize + _pageStep;
    await _searchMessagesInternal(roomId, keyword, nextContextSize);
  }

  /// 加载更多新搜索结果
  Future<void> loadMoreAfter(String roomId, String keyword) async {
    if (state.isLoading || !state.hasMoreAfter) return;

    if (state.contextSize >= _maxContextSize) {
      state = state.copyWith(hasMoreAfter: false);
      return;
    }

    final nextContextSize = state.contextSize + _pageStep;
    await _searchMessagesInternal(roomId, keyword, nextContextSize);
  }

  /// 重置搜索状态
  void reset() {
    state = SearchState(
      isLoading: false,
      keyword: '',
      messages: [],
      hasMoreBefore: false,
      hasMoreAfter: false,
      contextSize: _pageSize,
      minSeq: 0,
      maxSeq: 0,
      firstMatchIndex: -1,
      lastMatchIndex: -1,
      totalMatches: 0,
    );
  }
}

/// 搜索状态
class SearchState {
  final bool isLoading;
  final String keyword;
  final List<ChatMessage> messages;
  final bool hasMoreBefore;
  final bool hasMoreAfter;
  final int contextSize;
  final int minSeq;
  final int maxSeq;
  final int firstMatchIndex;
  final int lastMatchIndex;
  final int totalMatches;

  SearchState({
    required this.isLoading,
    required this.keyword,
    required this.messages,
    required this.hasMoreBefore,
    required this.hasMoreAfter,
    required this.contextSize,
    required this.minSeq,
    required this.maxSeq,
    required this.firstMatchIndex,
    required this.lastMatchIndex,
    required this.totalMatches,
  });

  SearchState copyWith({
    bool? isLoading,
    String? keyword,
    List<ChatMessage>? messages,
    bool? hasMoreBefore,
    bool? hasMoreAfter,
    int? contextSize,
    int? minSeq,
    int? maxSeq,
    int? firstMatchIndex,
    int? lastMatchIndex,
    int? totalMatches,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      keyword: keyword ?? this.keyword,
      messages: messages ?? this.messages,
      hasMoreBefore: hasMoreBefore ?? this.hasMoreBefore,
      hasMoreAfter: hasMoreAfter ?? this.hasMoreAfter,
      contextSize: contextSize ?? this.contextSize,
      minSeq: minSeq ?? this.minSeq,
      maxSeq: maxSeq ?? this.maxSeq,
      firstMatchIndex: firstMatchIndex ?? this.firstMatchIndex,
      lastMatchIndex: lastMatchIndex ?? this.lastMatchIndex,
      totalMatches: totalMatches ?? this.totalMatches,
    );
  }
}
