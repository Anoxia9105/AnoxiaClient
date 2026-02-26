import 'package:anoxia/common/constants/API.dart';
import 'package:anoxia/framework/network/DioClient.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/ChatMessage.dart';
import '../../../logs/talker.dart';

part 'search_message_service.g.dart';

/// 搜索消息服务
/// 功能：提供消息搜索、加载更多搜索结果等功能
@Riverpod(keepAlive: true)
class SearchMessageService extends _$SearchMessageService {
  final int _pageSize = 50;

  @override
  SearchState build() {
    return SearchState(
      isLoading: false,
      messages: [],
      hasMoreBefore: false,
      hasMoreAfter: false,
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
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      final res = await DioClient().get(
        API.chatSearch,
        queryParameters: {
          "roomId": roomId,
          "keyword": keyword,
          "contextSize": _pageSize,
        },
      );

      final data = res.data["data"];
      if (data is! Map) return;

      final messagesData = data["messages"] ?? [];
      final firstMatchIndex = data["firstMatchIndex"] ?? -1;
      final lastMatchIndex = data["lastMatchIndex"] ?? -1;
      final hasMoreBefore = data["hasMoreBefore"] ?? false;
      final hasMoreAfter = data["hasMoreAfter"] ?? false;
      final minSeq = data["minSeq"] ?? 0;
      final maxSeq = data["maxSeq"] ?? 0;
      final totalMatches = data["totalMatches"] ?? 0;

      final List<ChatMessage> messages = [];
      if (messagesData is List) {
        for (var item in messagesData) {
          if (item is Map) {
            // 将 Map<dynamic, dynamic> 转换为 Map<String, dynamic>
            final Map<String, dynamic> stringKeyMap = item.map(
              (key, value) => MapEntry(key.toString(), value),
            );
            messages.add(ChatMessage.fromJson(stringKeyMap));
          }
        }
      }

      state = state.copyWith(
        isLoading: false,
        messages: messages,
        firstMatchIndex: firstMatchIndex,
        lastMatchIndex: lastMatchIndex,
        hasMoreBefore: hasMoreBefore,
        hasMoreAfter: hasMoreAfter,
        minSeq: minSeq,
        maxSeq: maxSeq,
        totalMatches: totalMatches,
      );
    } catch (e) {
      log.error("搜索消息失败: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  /// 加载更多历史搜索结果
  /// 注意：根据后端接口，暂时不支持分页加载更多历史搜索结果
  Future<void> loadMoreBefore(String roomId, String keyword) async {
    // 后端接口暂时不支持分页加载更多历史搜索结果
    log.info("后端接口暂时不支持分页加载更多历史搜索结果");
  }

  /// 加载更多新搜索结果
  /// 注意：根据后端接口，暂时不支持分页加载更多新搜索结果
  Future<void> loadMoreAfter(String roomId, String keyword) async {
    // 后端接口暂时不支持分页加载更多新搜索结果
    log.info("后端接口暂时不支持分页加载更多新搜索结果");
  }

  /// 重置搜索状态
  void reset() {
    state = SearchState(
      isLoading: false,
      messages: [],
      hasMoreBefore: false,
      hasMoreAfter: false,
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
  final List<ChatMessage> messages;
  final bool hasMoreBefore;
  final bool hasMoreAfter;
  final int minSeq;
  final int maxSeq;
  final int firstMatchIndex;
  final int lastMatchIndex;
  final int totalMatches;

  SearchState({
    required this.isLoading,
    required this.messages,
    required this.hasMoreBefore,
    required this.hasMoreAfter,
    required this.minSeq,
    required this.maxSeq,
    required this.firstMatchIndex,
    required this.lastMatchIndex,
    required this.totalMatches,
  });

  SearchState copyWith({
    bool? isLoading,
    List<ChatMessage>? messages,
    bool? hasMoreBefore,
    bool? hasMoreAfter,
    int? minSeq,
    int? maxSeq,
    int? firstMatchIndex,
    int? lastMatchIndex,
    int? totalMatches,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      hasMoreBefore: hasMoreBefore ?? this.hasMoreBefore,
      hasMoreAfter: hasMoreAfter ?? this.hasMoreAfter,
      minSeq: minSeq ?? this.minSeq,
      maxSeq: maxSeq ?? this.maxSeq,
      firstMatchIndex: firstMatchIndex ?? this.firstMatchIndex,
      lastMatchIndex: lastMatchIndex ?? this.lastMatchIndex,
      totalMatches: totalMatches ?? this.totalMatches,
    );
  }
}
