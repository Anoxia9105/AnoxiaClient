import 'dart:convert';

class Attachment {
  final String? url;
  final String? id;
  final String? name;
  final int? size;
  final String? type;

  Attachment({this.url, this.id, this.name, this.size, this.type});

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
    url: json['url'],
    id: json['id'],
    name: json['name'],
    size: json['size'],
    type: json['type'],
  );

  Map<String, dynamic> toJson() => {
    'url': url,
    'id': id,
    'name': name,
    'size': size,
    'type': type,
  };

  static Attachment? fromEmbed(dynamic data) {
    if (data == null) return null;
    Map<String, dynamic> props = {};
    if (data is String) {
      try {
        props = jsonDecode(data);
      } catch (_) {
        props['url'] = data;
      }
    } else if (data is Map) {
      props = data.cast<String, dynamic>();
    }
    // 这里的 id 对应你上传时生成的 Uuid().v4()
    return Attachment.fromJson(props);
  }

  Attachment copyWith({
    String? url,
    String? id,
    String? name,
    int? size,
    String? type,
  }) {
    return Attachment(
      url: url ?? this.url,
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      type: type ?? this.type,
    );
  }

  bool get isImage {
    final imageExtensions = {
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'heic',
      'bmp',
    };
    // 统一转小写进行比较，防止出现 .JPG 匹配失败
    return imageExtensions.contains(type?.toLowerCase());
  }
}
