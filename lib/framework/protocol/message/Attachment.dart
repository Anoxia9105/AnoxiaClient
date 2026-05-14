import 'dart:convert';

/// 协议层文件附件模型
///
/// 定义消息中附带文件的元数据，用于网络传输。
/// 与领域层的 [domain.Attachment] 区别：此模型专用于协议解析，
/// 字段可选性更强，兼容多种数据格式。
class Attachment {
  /// 文件访问 URL
  final String? url;

  /// 文件唯一标识（上传时生成的 UUID）
  final String? id;

  /// 文件显示名称
  final String? name;

  /// 文件大小（字节）
  final int? size;

  /// 文件 MIME 类型
  final String? type;

  Attachment({this.url, this.id, this.name, this.size, this.type});

  /// 从 JSON 构造 [Attachment] 实例
  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        url: json['url'],
        id: json['id'],
        name: json['name'],
        size: json['size'],
        type: json['type'],
      );

  /// 序列化为 JSON
  Map<String, dynamic> toJson() => {
        'url': url,
        'id': id,
        'name': name,
        'size': size,
        'type': type,
      };

  /// 从嵌入数据构造附件
  ///
  /// 兼容 String（JSON 字符串）或 Map 格式的输入
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
    return Attachment.fromJson(props);
  }

  /// 创建变体副本
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

  /// 是否为图片类型
  bool get isImage {
    const imageExtensions = {
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'heic',
      'bmp',
    };
    // 统一转小写比较，避免 .JPG 匹配失败
    return imageExtensions.contains(type?.toLowerCase());
  }
}
