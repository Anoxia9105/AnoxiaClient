// 本地媒体时间线：按 seq 分页，并多探测一条有效内容确认 hasMore。
import 'package:anoxia/common/utils/message_url_extractor.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/local_cache/cache_providers.dart';
import 'package:anoxia/framework/logs/debug_log.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_timeline_provider.g.dart';

class MediaTimelineSection {
  const MediaTimelineSection({
    required this.items,
    required this.hasMore,
    this.sourceCursor,
  });
  final List<ChatMessage> items;
  final bool hasMore;
  final int? sourceCursor;
  bool get isEmpty => items.isEmpty;
  int? get oldestSeq {
    if (sourceCursor != null) return sourceCursor;
    final seqs = items.map((m) => m.seq).whereType<int>().where((s) => s > 0);
    return seqs.isEmpty ? null : seqs.reduce((a, b) => a < b ? a : b);
  }

  MediaTimelineSection appendUnique(List<ChatMessage> page, bool hasMore) {
    final seen = items.map((m) => m.messageId).toSet();
    return MediaTimelineSection(
      items: [...items, ...page.where((m) => seen.add(m.messageId))],
      hasMore: hasMore,
    );
  }
}

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

/// 查询有效结果而不是源文本条数：恰好满页、后续仅有普通文本均不会误报更多。
Future<MediaTimelineSection> queryTimelinePage({
  required Future<List<ChatMessage>> Function(int? beforeSeq, int limit) query,
  required bool Function(ChatMessage) accepts,
  int? beforeSeq,
  int pageSize = 60,
}) async {
  var cursor = beforeSeq;
  final matches = <ChatMessage>[];
  final seen = <Object>{};
  while (matches.length <= pageSize) {
    final source = await query(cursor, pageSize + 1);
    if (source.isEmpty) break;
    for (final message in source) {
      if (accepts(message) && seen.add(message.messageId ?? message)) {
        matches.add(message);
      }
    }
    final seqs = source.map((m) => m.seq).whereType<int>().where((s) => s > 0);
    final next = seqs.isEmpty ? null : seqs.reduce((a, b) => a < b ? a : b);
    if (source.length < pageSize + 1 ||
        next == null ||
        (cursor != null && next >= cursor)) {
      break;
    }
    cursor = next;
  }
  final items = matches.take(pageSize).toList();
  final seqs = items.map((m) => m.seq).whereType<int>().where((s) => s > 0);
  final next = seqs.isEmpty ? null : seqs.reduce((a, b) => a < b ? a : b);
  return MediaTimelineSection(
    items: items,
    hasMore: matches.length > pageSize && next != null,
    sourceCursor: next,
  );
}

@riverpod
class MediaTimelineController extends _$MediaTimelineController {
  static const int pageSize = 60;
  static final mediaTypeCodes = [
    MessageType.image.code,
    MessageType.video.code,
  ];
  static final fileTypeCodes = [MessageType.file.code];
  static final linkTypeCodes = [
    MessageType.text.code,
    MessageType.richText.code,
  ];
  final _loadingSections = <String>{};

  Future<MediaTimelineSection> _query(String section, {int? beforeSeq}) {
    final dataSource = ref.read(localDataSourceProvider);
    return queryTimelinePage(
      beforeSeq: beforeSeq,
      query: (cursor, limit) => dataSource.getMediaTimelineMessages(
        roomId,
        typeCodes: switch (section) {
          'media' => mediaTypeCodes,
          'files' => fileTypeCodes,
          _ => linkTypeCodes,
        },
        limit: limit,
        beforeSeq: cursor,
      ),
      accepts: (m) => switch (section) {
        'links' => extractChatMessageUrls(m).isNotEmpty,
        'files' => m.payload?.file?.url?.isNotEmpty == true,
        _ =>
          m.payload?.mediaAttachments.any(
                (a) => (a.isImage || a.isVideo) && a.url?.isNotEmpty == true,
              ) ==
              true,
      },
    );
  }

  @override
  Future<MediaTimelineState> build(String roomId) async {
    ref.watch(localDataSourceProvider);
    final sections = await Future.wait(['media', 'files', 'links'].map(_query));
    return MediaTimelineState(
      media: sections[0],
      files: sections[1],
      links: sections[2],
    );
  }

  Future<void> loadMore({required String section}) async {
    if (!['media', 'files', 'links'].contains(section) ||
        !_loadingSections.add(section)) {
      return;
    }
    try {
      final current = state.value;
      if (current == null) return;
      final previous = switch (section) {
        'media' => current.media,
        'files' => current.files,
        _ => current.links,
      };
      if (!previous.hasMore || previous.oldestSeq == null) return;
      final page = await _query(section, beforeSeq: previous.oldestSeq);
      if (!ref.mounted) return;
      final latest = state.value!;
      final merged = previous.appendUnique(page.items, page.hasMore);
      final next = MediaTimelineSection(
        items: merged.items,
        hasMore: page.hasMore,
        sourceCursor: page.sourceCursor,
      );
      state = AsyncData(
        MediaTimelineState(
          media: section == 'media' ? next : latest.media,
          files: section == 'files' ? next : latest.files,
          links: section == 'links' ? next : latest.links,
        ),
      );
    } catch (e, st) {
      debugLog('[MediaTimeline] 分页失败，保留内容以便重试: $e', e, st);
    } finally {
      _loadingSections.remove(section);
    }
  }
}
