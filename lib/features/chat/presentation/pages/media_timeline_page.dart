// 聊天媒体/文件/链接时间线页面（P0-4）。
//
// 数据口径与结构：
// - 来源全部是本地 drift 缓存，`MediaTimelineController`（房间 family）
//   首拉三段并行，上拉分页 `seq < oldestSeq` 向前翻页；
// - 媒体格：payload 的 image/video 附件展开成一格一附件（九宫格），
//   点开复用聊天内的 `ImageViewer`（不落地新查看器）；
// - 文件：附件原始名/大小/时间，点击用系统方式打开（浏览器/外部程序）；
// - 链接：文本消息中提取的 URL（`message_url_extractor` 公共口径），
//   点击系统浏览器打开；
// - 加载更多仅在探测到下一条有效内容时出现，位于滚动内容底部。
import 'package:anoxia/common/utils/file_util.dart';
import 'package:anoxia/framework/theme/radius_token.dart';
import 'package:anoxia/framework/theme/spacing_token.dart';
import 'package:anoxia/common/utils/message_url_extractor.dart';
import 'package:anoxia/common/widgets/attachment_image_view.dart';
import 'package:anoxia/features/chat/presentation/widgets/message_render/detail/image_viewer.dart';
import 'package:anoxia/framework/domain/chat_message.dart';
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';
import 'package:anoxia/framework/provider/chat/media/media_timeline_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hugeicons/hugeicons.dart';

/// 媒体时间线行的展示时间文案（timestamp 缺失时回退占位）
String _formatTime(ChatMessage message) {
  final ts = message.timestamp;
  if (ts == null || ts <= 0) return '';
  return DateFormat(
    'yyyy-MM-dd HH:mm',
  ).format(DateTime.fromMillisecondsSinceEpoch(ts));
}

/// 媒体与链接时间线
class MediaTimelinePage extends ConsumerWidget {
  final String roomId;

  const MediaTimelinePage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        // 显式背景：桌面端以弹窗呈现时与主题 surface 一致，不透底
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        appBar: AppBar(
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01),
          ),
          title: Text('chat_media_timeline_title'.tr()),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                SpacingToken.lg,
                SpacingToken.xs,
                SpacingToken.lg,
                SpacingToken.md,
              ),
              child: Container(
                padding: const EdgeInsets.all(SpacingToken.xs),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(RadiusToken.lg),
                ),
                child: TabBar(
                  dividerHeight: 0,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(RadiusToken.md),
                  ),
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant,
                  labelPadding: EdgeInsets.zero,
                  tabs: [
                    _timelineTab(
                      context,
                      HugeIcons.strokeRoundedImage01,
                      'chat_media_timeline_media',
                    ),
                    _timelineTab(
                      context,
                      HugeIcons.strokeRoundedFile02,
                      'chat_media_timeline_files',
                    ),
                    _timelineTab(
                      context,
                      HugeIcons.strokeRoundedLink01,
                      'chat_media_timeline_links',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _MediaGridTab(roomId: roomId),
            _FilesTab(roomId: roomId),
            _LinksTab(roomId: roomId),
          ],
        ),
      ),
    );
  }
}

Widget _timelineTab(
  BuildContext context,
  List<List<dynamic>> icon,
  String label,
) => Tab(
  height: 40,
  child: Builder(
    builder: (context) => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        HugeIcon(
          icon: icon,
          size: 18,
          color: DefaultTextStyle.of(context).style.color,
        ),
        const SizedBox(width: SpacingToken.sm),
        Text(label.tr()),
      ],
    ),
  ),
);

/// 媒体九宫格（image/video 附件展开）
class _MediaGridTab extends ConsumerWidget {
  final String roomId;

  const _MediaGridTab({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mediaTimelineControllerProvider(roomId));
    return async.when(
      loading: () => const _MediaSkeleton(),
      error: (e, st) => _ErrorRetry(
        retry: () => ref.invalidate(mediaTimelineControllerProvider(roomId)),
      ),
      data: (state) {
        final cells = _expandMediaAttachments(state.media.items);
        if (cells.isEmpty) return const _EmptyHint();
        return CustomScrollView(
          key: PageStorageKey('media_$roomId'),
          slivers: [
            SliverPadding(
              // 上下内填充：九宫格不贴 TabBar 与底部边缘
              padding: const EdgeInsets.all(SpacingToken.md),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: SpacingToken.sm,
                  crossAxisSpacing: SpacingToken.sm,
                ),
                itemCount: cells.length,
                itemBuilder: (context, index) {
                  final (message, attachment) = cells[index];
                  return _MediaCell(
                    message: message,
                    attachment: attachment,
                    roomId: roomId,
                  );
                },
              ),
            ),
            if (state.media.hasMore)
              SliverToBoxAdapter(
                child: _LoadMoreTile(
                  onTap: () => ref
                      .read(mediaTimelineControllerProvider(roomId).notifier)
                      .loadMore(section: 'media'),
                ),
              ),
          ],
        );
      },
    );
  }

  /// 一格一媒体：image 消息取 payload.image，video 消息取 payload.video
  /// （不走 mediaAttachments —— 它会把视频封面 cover 也收进来，导致
  /// 视频在九宫格里重复出「封面图」格）
  static List<(ChatMessage, Attachment)> _expandMediaAttachments(
    List<ChatMessage> messages,
  ) {
    final result = <(ChatMessage, Attachment)>[];
    for (final message in messages) {
      final payload = message.payload;
      if (payload == null) continue;
      switch (message.messageType) {
        case MessageType.image when payload.image?.url?.isNotEmpty == true:
          result.add((message, payload.image!));
        case MessageType.video when payload.video?.url?.isNotEmpty == true:
          result.add((message, payload.video!));
        default:
          for (final attachment in payload.mediaAttachments) {
            if (attachment.isImage || attachment.isVideo) {
              result.add((message, attachment));
            }
          }
      }
    }
    return result;
  }
}

/// 单个媒体格：图片直接缩略；视频显示封面/占位 + 播放标识
class _MediaCell extends StatelessWidget {
  final ChatMessage message;
  final Attachment attachment;
  final String roomId;

  const _MediaCell({
    required this.message,
    required this.attachment,
    required this.roomId,
  });

  String? get _thumbUrl => (attachment.isVideo
      ? (attachment.thumbnailUrl ?? message.payload?.cover?.url)
      : attachment.url);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openViewer(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AttachmentImageView(
              url: _thumbUrl,
              memCacheWidth: 480,
              errorWidget: (context, url, error) => ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            if (attachment.isVideo)
              const Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedPlay,
                  size: 40,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 复用聊天内图片查看器（与大图查看/已读回执同一套 hero 口径）
  void _openViewer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageViewer(
          attachment: attachment,
          heroTag:
              'media_timeline_${message.messageId}_${attachment.id ?? attachment.url}',
          roomId: roomId,
          currentUrl: attachment.url,
        ),
      ),
    );
  }
}

/// 文件列表（附件原始名 / 大小 / 发送时间）
class _FilesTab extends ConsumerWidget {
  final String roomId;

  const _FilesTab({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mediaTimelineControllerProvider(roomId));
    return async.when(
      loading: () => const _ListSkeleton(),
      error: (e, st) => _ErrorRetry(
        retry: () => ref.invalidate(mediaTimelineControllerProvider(roomId)),
      ),
      data: (state) {
        if (state.files.isEmpty) {
          return const _EmptyHint(icon: HugeIcons.strokeRoundedFile02);
        }
        return ListView.separated(
          key: PageStorageKey('files_$roomId'),
          padding: const EdgeInsets.all(SpacingToken.md),
          itemCount: state.files.items.length + (state.files.hasMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: SpacingToken.sm),
          itemBuilder: (context, index) {
            if (index >= state.files.items.length) {
              return _LoadMoreTile(
                onTap: () => ref
                    .read(mediaTimelineControllerProvider(roomId).notifier)
                    .loadMore(section: 'files'),
              );
            }
            return _FileRow(message: state.files.items[index]);
          },
        );
      },
    );
  }
}

class _FileRow extends StatelessWidget {
  final ChatMessage message;

  const _FileRow({required this.message});

  @override
  Widget build(BuildContext context) {
    final file = message.payload?.file;
    final name =
        file?.name ?? (message.content.isEmpty ? 'file' : message.content);
    final size = file?.size;
    final time = _formatTime(message);

    final extension = name.split('.').last.toLowerCase();
    return _TimelineCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpacingToken.md,
          vertical: SpacingToken.xs,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(RadiusToken.md),
          ),
          child: Center(
            child: FileUtil.buildFileIcon(extension, fileName: name),
          ),
        ),
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          time.isEmpty
              ? (size == null ? '' : FileUtil.formatFileSize(size))
              : (size == null
                    ? time
                    : '$time · ${FileUtil.formatFileSize(size)}'),
        ),
        onTap: () => _open(file?.url),
      ),
    );
  }

  /// 时间线 v1 直接系统方式打开附件 URL（下载/预览沿用聊天页内逻辑）
  Future<void> _open(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// 链接列表（文本消息中提取的 URL）
class _LinksTab extends ConsumerWidget {
  final String roomId;

  const _LinksTab({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mediaTimelineControllerProvider(roomId));
    return async.when(
      loading: () => const _ListSkeleton(),
      error: (e, st) => _ErrorRetry(
        retry: () => ref.invalidate(mediaTimelineControllerProvider(roomId)),
      ),
      data: (state) {
        if (state.links.isEmpty) {
          return const _EmptyHint(icon: HugeIcons.strokeRoundedLink01);
        }
        return ListView.separated(
          key: PageStorageKey('links_$roomId'),
          padding: const EdgeInsets.all(SpacingToken.md),
          itemCount: state.links.items.length + (state.links.hasMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: SpacingToken.sm),
          itemBuilder: (context, index) {
            if (index >= state.links.items.length) {
              return _LoadMoreTile(
                onTap: () => ref
                    .read(mediaTimelineControllerProvider(roomId).notifier)
                    .loadMore(section: 'links'),
              );
            }
            return _LinkRow(message: state.links.items[index]);
          },
        );
      },
    );
  }
}

class _LinkRow extends StatelessWidget {
  final ChatMessage message;

  const _LinkRow({required this.message});

  @override
  Widget build(BuildContext context) {
    final time = _formatTime(message);
    final urls = extractChatMessageUrls(message);
    final url = urls.isEmpty ? message.content : urls.first;
    final scheme = Theme.of(context).colorScheme;
    return _TimelineCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpacingToken.md,
          vertical: SpacingToken.sm,
        ),
        leading: Container(
          padding: const EdgeInsets.all(SpacingToken.md),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(RadiusToken.lg),
          ),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedLink01,
            size: 22,
            color: scheme.onPrimaryContainer,
          ),
        ),
        trailing: HugeIcon(
          icon: HugeIcons.strokeRoundedArrowRight01,
          size: 16,
          color: scheme.onSurfaceVariant,
        ),
        title: Text(
          Uri.tryParse(url)?.host ?? url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(url, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: SpacingToken.xs),
            Text(time, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        onTap: () => _open(url),
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.surface,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusToken.lg),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}

class _LoadMoreTile extends StatefulWidget {
  final Future<void> Function() onTap;

  const _LoadMoreTile({required this.onTap});

  @override
  State<_LoadMoreTile> createState() => _LoadMoreTileState();
}

class _LoadMoreTileState extends State<_LoadMoreTile> {
  bool _loading = false;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Center(
        child: FilledButton.tonalIcon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingToken.xl,
              vertical: SpacingToken.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RadiusToken.pill),
            ),
          ),
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  try {
                    await widget.onTap();
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowDown01,
                  size: 18,
                ),
          label: Text('chat_media_timeline_load_more'.tr()),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({this.icon = HugeIcons.strokeRoundedImage01});
  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: icon,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'chat_media_timeline_empty'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final VoidCallback retry;

  const _ErrorRetry({required this.retry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAlertCircle,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: retry,
            child: Text('chat_media_timeline_retry'.tr()),
          ),
        ],
      ),
    );
  }
}

/// 骨架：沿用 chat/skeleton 占位风格（灰块 + 圆角，无第三方 shimmer）
class _MediaSkeleton extends StatelessWidget {
  const _MediaSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return GridView.builder(
      padding: const EdgeInsets.all(SpacingToken.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: SpacingToken.sm,
        crossAxisSpacing: SpacingToken.sm,
      ),
      itemCount: 18,
      itemBuilder: (context, index) => DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(RadiusToken.lg),
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.separated(
      padding: const EdgeInsets.all(SpacingToken.md),
      itemCount: 10,
      separatorBuilder: (_, _) => const SizedBox(height: SpacingToken.sm),
      itemBuilder: (context, index) => _TimelineCard(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color,
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedFile02,
              color: Colors.white38,
            ),
          ),
          title: ColoredBox(color: color, child: const SizedBox(height: 14)),
          subtitle: ColoredBox(color: color, child: const SizedBox(height: 10)),
        ),
      ),
    );
  }
}
