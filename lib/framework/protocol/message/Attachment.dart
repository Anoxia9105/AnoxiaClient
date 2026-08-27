import 'dart:convert';

/// 协议层媒体附件模型（V5 MediaAttachmentProtoV5 对齐）
class Attachment {
  final String? id; // attachment_id
  final String? kind;
  final String? url;
  final String? name;
  final String? type; // mime_type
  final int? size; // size_bytes
  final String? sha256;
  final String? thumbnailUrl;
  final int? width;
  final int? height;
  final int? bitrate;
  final Map<String, String> properties;

  const Attachment({
    this.id,
    this.kind,
    this.url,
    this.name,
    this.type,
    this.size,
    this.sha256,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.bitrate,
    this.properties = const {},
  });

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
    id: (json['id'] ?? json['attachmentId'] ?? json['attachment_id'])
        ?.toString(),
    kind: (json['kind'] ?? json['mediaKind'] ?? json['media_kind'])?.toString(),
    url: json['url']?.toString(),
    name: (json['name'] ?? json['fileName'] ?? json['file_name'])?.toString(),
    type: (json['type'] ?? json['mimeType'] ?? json['mime_type'])?.toString(),
    size: _readInt(json['size'] ?? json['sizeBytes'] ?? json['size_bytes']),
    sha256: json['sha256']?.toString(),
    thumbnailUrl: (json['thumbnailUrl'] ?? json['thumbnail_url'])?.toString(),
    width: _readInt(json['width']),
    height: _readInt(json['height']),
    bitrate: _readInt(json['bitrate']),
    properties: _readStringMap(json['properties']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'url': url,
    'name': name,
    'type': type,
    'size': size,
    'sha256': sha256,
    'thumbnailUrl': thumbnailUrl,
    'width': width,
    'height': height,
    'bitrate': bitrate,
    'properties': properties,
  };

  static Attachment? fromEmbed(dynamic data) {
    if (data == null) return null;
    Map<String, dynamic> props = {};
    if (data is String) {
      try {
        props = jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {
        props['url'] = data;
      }
    } else if (data is Map) {
      props = data.cast<String, dynamic>();
    }
    return Attachment.fromJson(props);
  }

  Attachment copyWith({
    String? id,
    String? kind,
    String? url,
    String? name,
    String? type,
    int? size,
    String? sha256,
    String? thumbnailUrl,
    int? width,
    int? height,
    int? bitrate,
    Map<String, String>? properties,
  }) => Attachment(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    url: url ?? this.url,
    name: name ?? this.name,
    type: type ?? this.type,
    size: size ?? this.size,
    sha256: sha256 ?? this.sha256,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    width: width ?? this.width,
    height: height ?? this.height,
    bitrate: bitrate ?? this.bitrate,
    properties: properties ?? this.properties,
  );

  bool get isGif {
    final t = type?.toLowerCase();
    if (t == 'gif' || t == 'image/gif') return true;
    if (t?.contains('gif') == true) return true;
    if (kind?.toUpperCase() == 'GIF') return true;
    final lowerUrl = url?.toLowerCase() ?? '';
    if (lowerUrl.contains('.gif')) return true;
    final lowerName = name?.toLowerCase() ?? '';
    if (lowerName.endsWith('.gif')) return true;
    return false;
  }

  bool get isImage {
    const exts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp'};
    if (kind?.toUpperCase() == 'IMAGE') return true;
    if (exts.contains(type?.toLowerCase())) return true;
    // 通过 mime type 判断
    return type?.toLowerCase().startsWith('image/') == true;
  }

  bool get isVideo {
    const exts = {'mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v', 'flv'};
    if (kind?.toUpperCase() == 'VIDEO') return true;
    if (exts.contains(type?.toLowerCase())) return true;
    final mime = type?.toLowerCase() ?? '';
    if (mime.startsWith('video/')) return true;
    // 通过文件名后缀兜底
    final nameExt = name?.split('.').last.toLowerCase();
    if (nameExt != null && exts.contains(nameExt)) return true;
    final urlExt = url?.split('?').first.split('.').last.toLowerCase();
    if (urlExt != null && exts.contains(urlExt)) return true;
    return false;
  }

  static int? _readInt(dynamic value) =>
      value == null ? null : int.tryParse(value.toString());

  static Map<String, String> _readStringMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map((key, val) => MapEntry(key.toString(), val.toString()));
  }
}
