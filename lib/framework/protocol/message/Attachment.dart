import 'dart:convert';

/// 协议层媒体附件模型（V5 MediaAttachmentProtoV5 对齐）
class Attachment {
  final String? id; // attachment_id
  final String? url;
  final String? name;
  final String? type; // mime_type
  final int? size; // size_bytes
  final String? thumbnailUrl;
  final int? width;
  final int? height;

  const Attachment({
    this.id,
    this.url,
    this.name,
    this.type,
    this.size,
    this.thumbnailUrl,
    this.width,
    this.height,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
    id: json['id']?.toString(),
    url: json['url']?.toString(),
    name: json['name']?.toString(),
    type: json['type']?.toString(),
    size: json['size'] != null ? int.tryParse(json['size'].toString()) : null,
    thumbnailUrl: json['thumbnailUrl']?.toString(),
    width: json['width'] != null ? int.tryParse(json['width'].toString()) : null,
    height: json['height'] != null ? int.tryParse(json['height'].toString()) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'name': name,
    'type': type,
    'size': size,
    'thumbnailUrl': thumbnailUrl,
    'width': width,
    'height': height,
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
    String? url,
    String? name,
    String? type,
    int? size,
    String? thumbnailUrl,
    int? width,
    int? height,
  }) => Attachment(
    id: id ?? this.id,
    url: url ?? this.url,
    name: name ?? this.name,
    type: type ?? this.type,
    size: size ?? this.size,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    width: width ?? this.width,
    height: height ?? this.height,
  );

  bool get isImage {
    const exts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp'};
    if (exts.contains(type?.toLowerCase())) return true;
    // 通过 mime type 判断
    return type?.toLowerCase().startsWith('image/') == true;
  }
}
