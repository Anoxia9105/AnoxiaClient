import 'package:flutter/foundation.dart';

@immutable
class Attachment {
  final String url;   // 文件URL
  final String name;  // 文件名
  final int size;     // 文件大小（字节）
  final String type;  // 文件类型（mime / 自定义）

  const Attachment({
    required this.url,
    required this.name,
    required this.size,
    required this.type,
  });

  /// JSON -> Dart
  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      url: json['url'] as String,
      name: json['name'] as String,
      size: (json['size'] as num).toInt(),
      type: json['type'] as String,
    );
  }

  /// Dart -> JSON
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'name': name,
      'size': size,
      'type': type,
    };
  }

  /// 不可变对象的“修改方式”
  Attachment copyWith({
    String? url,
    String? name,
    int? size,
    String? type,
  }) {
    return Attachment(
      url: url ?? this.url,
      name: name ?? this.name,
      size: size ?? this.size,
      type: type ?? this.type,
    );
  }

  @override
  String toString() {
    return 'Attachment(url: $url, name: $name, size: $size, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Attachment &&
            url == other.url &&
            name == other.name &&
            size == other.size &&
            type == other.type;
  }

  @override
  int get hashCode =>
      url.hashCode ^ name.hashCode ^ size.hashCode ^ type.hashCode;
}
