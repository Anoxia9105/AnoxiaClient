/// 消息链接预览卡片组件。
///
/// 自动提取消息中的 URL，通过后台 Isolate 异步获取网页元数据，
/// 并以卡片形式展示标题、描述、缩略图等信息。
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// 链接预览元数据加载器类型定义。
typedef LinkPreviewLoader = Future<LinkPreviewMetadata> Function(String link);

/// 链接预览元数据。
class LinkPreviewMetadata {
  /// 页面标题。
  final String title;

  /// 页面描述。
  final String description;

  /// 预览图片 URL。
  final String? imageUrl;

  /// 站点名称。
  final String siteName;

  /// 是否已从远程加载。
  final bool loadedRemotely;

  const LinkPreviewMetadata({
    required this.title,
    required this.description,
    required this.siteName,
    this.imageUrl,
    this.loadedRemotely = false,
  });

  /// 创建仅包含域名和链接的兜底元数据。
  factory LinkPreviewMetadata.fallback(String link) {
    final host = _displayHost(link);
    return LinkPreviewMetadata(title: host, description: link, siteName: host);
  }

  /// 从后台 Isolate 返回的数据中创建元数据。
  factory LinkPreviewMetadata.fromWorker(
    String link,
    Map<Object?, Object?> data,
  ) {
    final fallback = LinkPreviewMetadata.fallback(link);
    return LinkPreviewMetadata(
      title: _safeText(data['title']) ?? fallback.title,
      description: _safeText(data['description']) ?? fallback.description,
      siteName: _safeText(data['siteName']) ?? fallback.siteName,
      imageUrl: _safeHttpUrl(data['imageUrl']?.toString(), baseUrl: link),
      loadedRemotely: data['loadedRemotely'] == true,
    );
  }
}

/// 消息链接预览卡片组件。
class MessageLinkPreview extends StatefulWidget {
  /// 卡片最小宽度。
  static const double minCardWidth = 260;

  /// 卡片最大宽度。
  static const double maxCardWidth = 420;

  /// 消息文本，用于提取 URL。
  final String text;

  /// 卡片最大宽度限制。
  final double? maxWidth;

  /// 自定义元数据加载器，为 `null` 时使用默认加载器。
  final LinkPreviewLoader? metadataLoader;

  const MessageLinkPreview({
    super.key,
    required this.text,
    this.maxWidth,
    this.metadataLoader,
  });

  @override
  State<MessageLinkPreview> createState() => _MessageLinkPreviewState();

  /// 从文本中提取第一个有效 URL。
  ///
  /// 自动处理末尾标点符号，并为 `www.` 前缀补全 `https://` 协议。
  static String? extractFirstUrl(String text) {
    final match = RegExp(
      r'((?:https?:\/\/|www\.)[^\s<>"\]\)]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return null;

    final rawUrl = match.group(1)?.trim();
    if (rawUrl == null || rawUrl.isEmpty) return null;

    var url = rawUrl;
    while (url.isNotEmpty && '.,!?;:'.contains(url[url.length - 1])) {
      url = url.substring(0, url.length - 1);
    }
    if (url.toLowerCase().startsWith('www.')) url = 'https://$url';

    final uri = Uri.tryParse(url);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    return url;
  }

  /// Fetches rich metadata through the bounded background-isolate queue.
  static Future<LinkPreviewMetadata> fetchMetadata(String link) {
    return _LinkPreviewCache.get(link);
  }
}

class _MessageLinkPreviewState extends State<MessageLinkPreview> {
  String? _link;
  Future<LinkPreviewMetadata>? _metadataFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant MessageLinkPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.metadataLoader != widget.metadataLoader) {
      _refresh();
    }
  }

  void _refresh() {
    final link = MessageLinkPreview.extractFirstUrl(widget.text);
    _link = link;
    _metadataFuture = link == null
        ? null
        : (widget.metadataLoader ?? MessageLinkPreview.fetchMetadata)(link);
  }

  @override
  Widget build(BuildContext context) {
    final link = _link;
    final future = _metadataFuture;
    if (link == null || future == null) return const SizedBox.shrink();

    return FutureBuilder<LinkPreviewMetadata>(
      future: future,
      initialData: LinkPreviewMetadata.fallback(link),
      builder: (context, snapshot) {
        final metadata = snapshot.data ?? LinkPreviewMetadata.fallback(link);
        return _ResolvedLinkPreview(
          link: link,
          metadata: metadata,
          maxWidth: widget.maxWidth,
          isLoading: snapshot.connectionState == ConnectionState.waiting,
        );
      },
    );
  }
}

class _LinkPreviewCache {
  static const int _maximumEntries = 200;
  static final LinkedHashMap<String, Future<LinkPreviewMetadata>> _cache =
      LinkedHashMap();

  static Future<LinkPreviewMetadata> get(String link) {
    final cached = _cache[link];
    if (cached != null) return cached;

    while (_cache.length >= _maximumEntries) {
      _cache.remove(_cache.keys.first);
    }
    final future = _LinkPreviewQueue.schedule(link);
    _cache[link] = future;
    return future;
  }
}

class _LinkPreviewQueue {
  static const int _maximumConcurrentWorkers = 2;
  static final Queue<_LinkPreviewJob> _pending = Queue();
  static int _activeWorkers = 0;

  static Future<LinkPreviewMetadata> schedule(String link) {
    final completer = Completer<LinkPreviewMetadata>();
    _pending.add(_LinkPreviewJob(link, completer));
    _pump();
    return completer.future;
  }

  static void _pump() {
    while (_activeWorkers < _maximumConcurrentWorkers && _pending.isNotEmpty) {
      final job = _pending.removeFirst();
      _activeWorkers++;
      unawaited(_run(job));
    }
  }

  static Future<void> _run(_LinkPreviewJob job) async {
    try {
      final metadata = await _LinkPreviewWorker.fetch(job.link);
      if (!job.completer.isCompleted) job.completer.complete(metadata);
    } catch (error, stackTrace) {
      debugPrint('[LinkPreview] ${job.link} failed: $error\n$stackTrace');
      if (!job.completer.isCompleted) {
        job.completer.complete(LinkPreviewMetadata.fallback(job.link));
      }
    } finally {
      _activeWorkers--;
      scheduleMicrotask(_pump);
    }
  }
}

class _LinkPreviewJob {
  final String link;
  final Completer<LinkPreviewMetadata> completer;

  const _LinkPreviewJob(this.link, this.completer);
}

class _LinkPreviewWorker {
  static const Duration _hardTimeout = Duration(seconds: 10);

  static Future<LinkPreviewMetadata> fetch(String link) async {
    // dart2js 暴露了 ReceivePort API，但浏览器不支持 sendPort。跨域网页
    // 通常也无法直接抓取元数据，因此 Web 保留安全的域名/链接兜底卡片。
    if (kIsWeb) return LinkPreviewMetadata.fallback(link);

    final responsePort = ReceivePort();
    Isolate? isolate;
    try {
      isolate = await Isolate.spawn<List<Object>>(
        _linkPreviewIsolateEntry,
        <Object>[responsePort.sendPort, link],
        debugName: 'link-preview:${Uri.parse(link).host}',
      );
      final response = await responsePort.first.timeout(_hardTimeout);
      if (response is Map) {
        final error = response['error'];
        if (error != null) debugPrint('[LinkPreview] $link failed: $error');
        return LinkPreviewMetadata.fromWorker(link, response);
      }
      return LinkPreviewMetadata.fallback(link);
    } on TimeoutException {
      return LinkPreviewMetadata.fallback(link);
    } catch (error) {
      debugPrint('[LinkPreview] $link worker failed: $error');
      return LinkPreviewMetadata.fallback(link);
    } finally {
      isolate?.kill(priority: Isolate.immediate);
      responsePort.close();
    }
  }
}

@pragma('vm:entry-point')
Future<void> _linkPreviewIsolateEntry(List<Object> arguments) async {
  final sendPort = arguments[0] as SendPort;
  final link = arguments[1] as String;
  try {
    sendPort.send(await _downloadAndParseMetadata(link));
  } catch (error, stackTrace) {
    sendPort.send(<String, Object?>{
      'loadedRemotely': false,
      'error': '$error\n$stackTrace',
    });
  }
}

Future<Map<String, Object?>> _downloadAndParseMetadata(String link) async {
  const maximumBodyBytes = 1024 * 1024;
  final client = http.Client();
  try {
    final request = http.Request('GET', Uri.parse(link))
      ..followRedirects = true
      ..maxRedirects = 5
      ..headers.addAll(const {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,image/*;q=0.8,*/*;q=0.5',
      });
    final response = await client
        .send(request)
        .timeout(const Duration(seconds: 6));
    if (response.statusCode < 200 || response.statusCode >= 400) {
      return <String, Object?>{'loadedRemotely': false};
    }

    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    if (contentType.startsWith('image/')) {
      return <String, Object?>{'imageUrl': link, 'loadedRemotely': true};
    }
    if (contentType.isNotEmpty &&
        !contentType.contains('text/html') &&
        !contentType.contains('application/xhtml+xml')) {
      return <String, Object?>{'loadedRemotely': false};
    }

    final bytes = <int>[];
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 4),
    )) {
      if (bytes.length + chunk.length > maximumBodyBytes) break;
      bytes.addAll(chunk);
    }
    if (bytes.isEmpty) return <String, Object?>{'loadedRemotely': false};

    final document = html_parser.parse(
      utf8.decode(bytes, allowMalformed: true),
    );
    final metadata = <String, String>{};
    for (final element in document.getElementsByTagName('meta')) {
      final key = (element.attributes['property'] ?? element.attributes['name'])
          ?.trim()
          .toLowerCase();
      final value = element.attributes['content']?.trim();
      if (key != null && value != null && value.isNotEmpty) {
        metadata.putIfAbsent(key, () => value);
      }
    }

    final title = _firstWorkerText([
      metadata['og:title'],
      metadata['twitter:title'],
      document.querySelector('title')?.text,
    ]);
    final description = _firstWorkerText([
      metadata['og:description'],
      metadata['twitter:description'],
      metadata['description'],
    ]);
    final image = _safeHttpUrl(
      _firstWorkerText([
        metadata['og:image'],
        metadata['og:image:url'],
        metadata['twitter:image'],
        metadata['twitter:image:src'],
      ]),
      baseUrl: link,
    );
    final siteName = _firstWorkerText([
      metadata['og:site_name'],
      metadata['application-name'],
    ]);

    return <String, Object?>{
      'title': _limitText(title, 300),
      'description': _limitText(description, 1000),
      'imageUrl': image,
      'siteName': _limitText(siteName, 200),
      'loadedRemotely': title != null || description != null || image != null,
    };
  } finally {
    client.close();
  }
}

class _ResolvedLinkPreview extends StatelessWidget {
  final String link;
  final LinkPreviewMetadata metadata;
  final double? maxWidth;
  final bool isLoading;

  const _ResolvedLinkPreview({
    required this.link,
    required this.metadata,
    required this.isLoading,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveMaxWidth = maxWidth == null || maxWidth! <= 0
        ? MessageLinkPreview.maxCardWidth
        : maxWidth!.clamp(0.0, MessageLinkPreview.maxCardWidth).toDouble();
    final effectiveMinWidth = MessageLinkPreview.minCardWidth
        .clamp(0.0, effectiveMaxWidth)
        .toDouble();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: effectiveMinWidth,
          maxWidth: effectiveMaxWidth,
        ),
        child: Material(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            mouseCursor: SystemMouseCursors.click,
            onTap: () => _openLink(link),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 92),
              child: Row(
                children: [
                  _PreviewThumbnail(
                    imageUrl: metadata.imageUrl,
                    isLoading: isLoading,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metadata.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            metadata.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (isLoading)
                            const Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: LinearProgressIndicator(minHeight: 2),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _openLink(String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }
}

class _PreviewThumbnail extends StatelessWidget {
  final String? imageUrl;
  final bool isLoading;

  const _PreviewThumbnail({required this.imageUrl, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 92,
      height: 92,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      alignment: Alignment.center,
      child: isLoading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.link_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
    );
    final url = imageUrl;
    if (url == null) return fallback;

    return Image.network(
      url,
      width: 92,
      height: 92,
      cacheWidth: 184,
      cacheHeight: 184,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return fallback;
      },
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

String _displayHost(String link) {
  final host = Uri.tryParse(link)?.host ?? link;
  return host.startsWith('www.') ? host.substring(4) : host;
}

String? _safeText(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text.toLowerCase() == 'null') return null;
  return text;
}

String? _firstWorkerText(List<String?> values) {
  for (final value in values) {
    final text = _safeText(value);
    if (text != null) return text;
  }
  return null;
}

String? _safeHttpUrl(String? value, {required String baseUrl}) {
  final text = _safeText(value);
  if (text == null || text.toLowerCase().startsWith('data:')) return null;
  final base = Uri.tryParse(baseUrl);
  final parsed = Uri.tryParse(text);
  if (base == null || parsed == null) return null;
  final resolved = base.resolveUri(parsed);
  if ((resolved.scheme != 'http' && resolved.scheme != 'https') ||
      resolved.host.isEmpty) {
    return null;
  }
  return resolved.toString();
}

String? _limitText(String? value, int maximumLength) {
  final text = _safeText(value);
  if (text == null || text.length <= maximumLength) return text;
  return '${text.substring(0, maximumLength)}…';
}
