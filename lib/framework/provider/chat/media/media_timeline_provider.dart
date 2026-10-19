// 媒体/文件/链接时间线数据源（P0-4，按房间 family）。
//
// 数据全部来自本地 drift 缓存（`LocalDataSource.getMediaTimelineMessages`）：
// - 媒体 = image/video（type 3/5）；文件 = file（6）；链接 = text（1）里抽 URL；
// - 分页口径与消息列表一致：`seq < oldestSeq` 向前翻页，不用 offset；
// - 防御性契约：首拉任何一段失败都降级为空段，不抛错；
// - autoDispose：页面退出即销毁，进入时重新首拉（登出无残留）。
// - `hasMore` = 最近一次源查询条数达到 pageSize（链接 Tab 对「过滤后为空」
//   仍保持 true，因为后页可能才有链接；由 UI 提供加载入口）。
import 'dart:async';

import 'package:anoxia/common/utils/message_url_extractor.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_timeline_provider.g.dart';

/// 单个分节的数据（媒体/文件/链接）
class MediaTimelineSection {
  const MediaTimelineSection({required this.items, required this.hasMore});

  /// 已加载条目（新 → 旧，即 seq 倒序）
  final List<ChatMessage> items;

  /// 最近一次源查询是否满页（满页说明后面可能还有）
  final bool hasMore;

  bool get isEmpty => items.isEmpty;

  /// 下一次分页游标：最小的已加载 seq（缺 seq 的乐观消息按 0 处理，
  /// 再翻一页拿不到更旧数据自然会收口）
  int? get oldestSeq {
    for (final item in items) {
      final seq = item.seq;
      if (seq != null && seq > 0) return seq;
    }
    return null;
  }

  MediaTimelineSection appendUnique(List<ChatMessage> page, bool hasMore) {
    final seen = items.map((m) => m.messageId).toSet();
    final merged = [
      ...items,
      ...page.where((m) => !seen.contains(m.messageId)),
    ];
    return MediaTimelineSection(items: merged, hasMore: hasMore);
  }
}

/// 三个分节的合成状态
class MediaTimelineState {
  const MediaTimelineState({
    this.media = const MediaTimelineSection(items: [], hasMore: false),
    this.files = const MediaTimelineSection(items: [], hasMore: false),
    this.links = const MediaTimelineSection(items: [], hasMore: false),
  });

  final MediaTimelineSection media;
  final MediaTimelineSection files;
  final MediaTimelineSection links;
}

/// 媒体时间线控制器（按房间 family；autoDispose）
@riverpod
class MediaTimelineController extends _$MediaTimelineController {
  /// 每次拉取的源消息条数（每段独立）
  static const int pageSize = 60;

  /// 媒体类消息协议编码：image=3 / video=5
  static final List<int> mediaTypeCodes = [
    MessageType.image.code,
    MessageType.video.code,
  ];

  /// 文件类：file=6
  static final List<int> fileTypeCodes = [MessageType.file.code];

  /// 链接类：只扫纯文本（richText 是 Quill Delta JSON，不做 URL 提取）
  static final List<int> linkTypeCodes = [MessageType.text.code];

  final Set<String> _loadingSections = {};

  @override
  Future<MediaTimelineState> build(String roomId) async {
    final dataSource = ref.watch(localDataSourceProvider);
    final results = await Future.wait([
      _safeQuery(
        () => dataSource.getMediaTimelineMessages(
          roomId,
          typeCodes: mediaTypeCodes,
          limit: pageSize,
        ),
      ),
      _safeQuery(
        () => dataSource.getMediaTimelineMessages(
          roomId,
          typeCodes: fileTypeCodes,
          limit: pageSize,
        ),
      ),
      _safeQuery(
        () => dataSource.getMediaTimelineMessages(
          roomId,
          typeCodes: linkTypeCodes,
          limit: pageSize,
        ),
      ),
    ]);

    return MediaTimelineState(
      media: _section(results[0], isLinkSection: false),
      files: _section(results[1], isLinkSection: false),
      links: _section(results[2], isLinkSection: true),
    );
  }

  /// 加载更多（上拉）。[section] 取值：'media' / 'files' / 'links'。
  /// 重复触发时忽略后续调用；失败静默记日志保持原状态。
  Future<void> loadMore({required String section}) async {
    if (!_loadingSections.add(section)) return;
    try {
      final current = state.value;
      if (current == null) return;

      final MediaTimelineSection previous;
      final List<int> typeCodes;
      switch (section) {
        case 'media':
          previous = current.media;
          typeCodes = mediaTypeCodes;
          break;
        case 'files':
          previous = current.files;
          typeCodes = fileTypeCodes;
          break;
        case 'links':
          previous = current.links;
          typeCodes = linkTypeCodes;
          break;
        default:
          return;
      }
      if (!previous.hasMore) return;
      final cursor = previous.oldestSeq;
      // 所有已加载消息都缺 seq（乐观未确认）时无翻页游标，直接收口，
      // 否则 beforeSeq=null 会重复拉取同页内容。
      if (cursor == null) return;

      final page = await _safeQuery(
        () => ref.read(localDataSourceProvider).getMediaTimelineMessages(
          roomId,
          typeCodes: typeCodes,
          limit: pageSize,
          beforeSeq: cursor,
        ),
      );
      final hasMore = page.length >= pageSize;

      state = AsyncValue.data(
        switch (section) {
          'media' =>
            MediaTimelineState(
              media: previous.appendUnique(page, hasMore),
              files: current.files,
              links: current.links,
            ),
          'files' =>
            MediaTimelineState(
              media: current.media,
              files: previous.appendUnique(page, hasMore),
              links: current.links,
            ),
          _ =>
            MediaTimelineState(
              media: current.media,
              files: current.files,
              links: previous.appendUnique(page, hasMore),
            ),
        },
      );
    } finally {
      _loadingSections.remove(section);
    }
  }

  /// 查询失败降级空列表（防御性契约：查询路径不抛错）
  Future<List<ChatMessage>> _safeQuery(
    Future<List<ChatMessage>> Function() query,
  ) async {
    try {
      return await query();
    } catch (e, st) {
      debugLog('[MediaTimeline] 查询失败，降级为空: $e', e, st);
      return const [];
    }
  }

  /// 把源消息页转成分节数据；链接节只保留含 URL 的文本消息
  /// （保留原消息对象——ChatMessage 不支持 copyWith 改 content，
  /// 展示时由 UI 自行提取首条 URL）
  MediaTimelineSection _section(
    List<ChatMessage> page, {
    required bool isLinkSection,
  }) {
    final items = isLinkSection
        ? page.where((m) => extractMessageUrls(m.content).isNotEmpty).toList()
        : page;
    // 过滤后为空不代表源结束：满页仍显示「加载更多」
    return MediaTimelineSection(items: items, hasMore: page.length >= pageSize);
  }
}
