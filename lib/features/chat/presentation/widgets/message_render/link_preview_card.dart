import 'package:any_link_preview/any_link_preview.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageLinkPreview extends StatefulWidget {
  final String text;

  const MessageLinkPreview({super.key, required this.text});

  @override
  State<MessageLinkPreview> createState() => _MessageLinkPreviewState();

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
    if (url.isEmpty) return null;
    if (url.toLowerCase().startsWith('www.')) {
      url = 'https://$url';
    }

    return AnyLinkPreview.isValidLink(url, requireProtocol: true) ? url : null;
  }
}

class _MessageLinkPreviewState extends State<MessageLinkPreview> {
  String? _link;
  Future<_LinkPreviewResult>? _metadataFuture;

  @override
  void initState() {
    super.initState();
    _refreshFuture();
  }

  @override
  void didUpdateWidget(covariant MessageLinkPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _refreshFuture();
    }
  }

  void _refreshFuture() {
    final nextLink = MessageLinkPreview.extractFirstUrl(widget.text);
    _link = nextLink;
    _metadataFuture = nextLink == null ? null : _LinkPreviewCache.get(nextLink);
  }

  @override
  Widget build(BuildContext context) {
    final link = _link;
    final future = _metadataFuture;
    if (link == null || future == null) return const SizedBox.shrink();

    return FutureBuilder<_LinkPreviewResult>(
      future: future,
      builder: (context, snapshot) {
        final result = snapshot.data;
        if (result == null || !result.success || result.metadata == null) {
          return const SizedBox.shrink();
        }

        return _ResolvedLinkPreview(link: link, metadata: result.metadata!);
      },
    );
  }
}

class _LinkPreviewResult {
  final Metadata? metadata;
  final bool success;

  const _LinkPreviewResult.success(this.metadata) : success = true;
  const _LinkPreviewResult.failed() : metadata = null, success = false;
}

class _LinkPreviewCache {
  static final Map<String, Future<_LinkPreviewResult>> _cache = {};

  static Future<_LinkPreviewResult> get(String link) {
    return _cache.putIfAbsent(link, () => _fetch(link));
  }

  static Future<_LinkPreviewResult> _fetch(String link) async {
    try {
      final metadata = await AnyLinkPreview.getMetadata(link: link);
      if (metadata == null || !_ResolvedLinkPreview.hasUsableData(metadata)) {
        return const _LinkPreviewResult.failed();
      }
      return _LinkPreviewResult.success(metadata);
    } catch (_) {
      return const _LinkPreviewResult.failed();
    }
  }
}

class _ResolvedLinkPreview extends StatelessWidget {
  final String link;
  final Metadata metadata;

  const _ResolvedLinkPreview({required this.link, required this.metadata});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = _firstNotEmpty([metadata.title, metadata.siteName, link]);
    final desc = _firstNotEmpty([metadata.desc, metadata.url]);
    final imageUrl = _safeImageUrl(metadata.image);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openLink(link),
          child: SizedBox(
            height: 92,
            child: Row(
              children: [
                if (imageUrl != null)
                  Image.network(
                    imageUrl,
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (desc.isNotEmpty && desc != title) ...[
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _firstNotEmpty(List<String?> values) {
    for (final value in values) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }

  static String? _safeImageUrl(String? image) {
    final value = image?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.toLowerCase().startsWith('data:')) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return value;
  }

  static bool hasUsableData(Metadata metadata) {
    return _firstNotEmpty([
          metadata.title,
          metadata.desc,
          metadata.siteName,
        ]).isNotEmpty ||
        _safeImageUrl(metadata.image) != null;
  }

  static Future<void> _openLink(String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }
}
