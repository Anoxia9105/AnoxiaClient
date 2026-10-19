// 消息文本里的 URL 提取（P0-4 链接时间线复用口径）。
//
// 解析规则抽自 message_render/link_preview_card.dart 的
// `MessageLinkPreview.extractFirstUrl`（行为不变），抽成公共 util 供
// 聊天媒体时间线（媒体/文件/链接三 Tab）等场景复用：
// - 正则取 `http(s)://` 或 `www.` 开头、非空白/非法括起字符的串；
// - 尾部标点（.,!?;:）剥掉；
// - `www.` 前缀自动补全 `https://`；
// - `Uri.tryParse` + scheme 校验（http/https）+ host 非空。
// 链接列表用 [extractMessageUrls]（全部匹配、按出现顺序去重），
// 头条链接仍走 [extractFirstMessageUrl]（等价原函数）。
library;

/// 提取文本中的第一个有效 URL（与 link_preview_card 原口径一致）。
String? extractFirstMessageUrl(String text) {
  final urls = extractMessageUrls(text);
  return urls.isEmpty ? null : urls.first;
}

/// 提取文本中的全部有效 URL（按出现顺序去重）。
List<String> extractMessageUrls(String text) {
  if (text.isEmpty) return const [];
  final matches = RegExp(
    r'((?:https?:\/\/|www\.)[^\s<>"\]\)]+)',
    caseSensitive: false,
  ).allMatches(text);

  final urls = <String>[];
  for (final match in matches) {
    final rawUrl = match.group(1)?.trim();
    if (rawUrl == null || rawUrl.isEmpty) continue;

    var url = rawUrl;
    while (url.isNotEmpty && '.,!?;:'.contains(url[url.length - 1])) {
      url = url.substring(0, url.length - 1);
    }
    if (url.isEmpty) continue;
    if (url.toLowerCase().startsWith('www.')) url = 'https://$url';

    final uri = Uri.tryParse(url);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      continue;
    }
    if (!urls.contains(url)) urls.add(url);
  }
  return urls;
}
