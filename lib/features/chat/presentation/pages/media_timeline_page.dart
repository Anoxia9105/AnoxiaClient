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
// - 三段空态/骨架/错误独立呈现；加载更多按钮随 hasMore 显隐
//   （链接节过滤后为空但源满页时仍保留加载入口）。
import 'package:anoxia/common/utils/file_util.dart';
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

/// 媒体时间线行的展示时间文案（timestamp 缺失时回退占位）
String _formatTime(ChatMessage message) {
  final ts = message.timestamp;
  if (ts == null || ts <= 0) return '';
  return DateFormat('yyyy-MM-dd HH:mm').format(
    DateTime.fromMillisecondsSinceEpoch(ts),
  );
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Text('chat_media_timeline_title'.tr()),
          bottom: TabBar(
            tabs: [
              Tab(text: 'chat_media_timeline_media'.tr()),
              Tab(text: 'chat_media_timeline_files'.tr()),
              Tab(text: 'chat_media_timeline_links'.tr()),
            ],
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
        return GridView.builder(
          // 上下内填充：九宫格不贴 TabBar 与底部边缘
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: cells.length + (state.media.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= cells.length) {
              return _LoadMoreTile(
                onTap: () => ref
                    .read(mediaTimelineControllerProvider(roomId).notifier)
                    .loadMore(section: 'media'),
              );
            }
            final (message, attachment) = cells[index];
            return _MediaCell(
              message: message,
              attachment: attachment,
              roomId: roomId,
            );
          },
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          AttachmentImageView(
            url: _thumbUrl,
            memCacheWidth: 480,
            errorWidget: (context, url, error) =>
                ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest),
          ),
          if (attachment.isVideo)
            const Center(
              child: Icon(Icons.play_circle_fill, size: 40, color: Colors.white70),
            ),
        ],
      ),
    );
  }

  /// 复用聊天内图片查看器（与大图查看/已读回执同一套 hero 口径）
  void _openViewer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageViewer(
          attachment: attachment,
          heroTag: 'media_timeline_${message.messageId}_${attachment.id ?? attachment.url}',
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
        if (state.files.isEmpty) return const _EmptyHint();
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: state.files.items.length + (state.files.hasMore ? 1 : 0),
          separatorBuilder: (_, _) => const Divider(height: 1),
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

    return ListTile(
      leading: const Icon(Icons.insert_drive_file_outlined),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(time.isEmpty
          ? (size == null ? '' : FileUtil.formatFileSize(size))
          : (size == null ? time : '$time · ${FileUtil.formatFileSize(size)}')),
      onTap: () => _open(file?.url),
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
          // 过滤后为空但源里还有未翻完的文本页 → 保留「加载更多」入口
          return state.links.hasMore
              ? ListView(
                  children: [
                    _LoadMoreTile(
                      onTap: () => ref
                          .read(mediaTimelineControllerProvider(roomId).notifier)
                          .loadMore(section: 'links'),
                    ),
                  ],
                )
              : const _EmptyHint();
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: state.links.items.length + (state.links.hasMore ? 1 : 0),
          separatorBuilder: (_, _) => const Divider(height: 1),
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
    final url = extractFirstMessageUrl(message.content) ?? message.content;
    return ListTile(
      leading: const Icon(Icons.link),
      title: Text(url, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(time),
      onTap: () => _open(url),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _LoadMoreTile extends StatelessWidget {
  final VoidCallback onTap;

  const _LoadMoreTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: OutlinedButton(
        onPressed: onTap,
        child: Text('chat_media_timeline_load_more'.tr()),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_library_outlined,
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
          Icon(
            Icons.error_outline,
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
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: 18,
      itemBuilder: (context, index) =>
          ColoredBox(color: color, child: const SizedBox.expand()),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: 10,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) => ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: const Icon(Icons.insert_drive_file_outlined, color: Colors.white38),
        ),
        title: ColoredBox(color: color, child: const SizedBox(height: 14)),
        subtitle: ColoredBox(color: color, child: const SizedBox(height: 10)),
      ),
    );
  }
}
