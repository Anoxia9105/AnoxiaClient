import 'package:flutter/foundation.dart';

/// 文件附件模型
///
/// 表示聊天消息中附带的文件信息，支持 JSON 序列化/反序列化。
/// 设计为不可变对象（[immutable]），通过 [copyWith] 创建变体。
@immutable
class Attachment {
  /// 文件的远程访问地址
  final String url;

  /// 文件显示名称
  final String name;

  /// 文件大小（单位：字节）
  final int size;

  /// 文件 MIME 类型或自定义类型标识
  final String type;

  const Attachment({
    required this.url,
    required this.name,
    required this.size,
    required this.type,
  });

  /// 从 JSON 数据构造 [Attachment] 实例
  ///
  /// [json] 需包含 url、name、size、type 四个必填字段
  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      url: json['url'] as String,
      name: json['name'] as String,
      size: (json['size'] as num).toInt(),
      type: json['type'] as String,
    );
  }

  /// 将当前实例转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {'url': url, 'name': name, 'size': size, 'type': type};
  }

  /// 创建当前实例的变体副本
  Attachment copyWith({String? url, String? name, int? size, String? type}) {
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
