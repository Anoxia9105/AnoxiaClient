library;

// ignore_for_file: avoid_print

// 消息载荷子类型（按载荷类型拆分）
//
// 从 [message_payload.dart] 拆分出的载荷子类型与共享解析工具，
// 便于按卡片/位置/代码等类型独立维护，同时保持对外 API 不变。
// 原文件通过 `export`/`import` 重新暴露这些类型，外部仍可直接
// `import 'message_payload.dart'` 使用。

/// 卡片消息载荷（V5 协议）
///
/// 用于表示富媒体卡片类型消息，如联系人卡片、群组卡片、链接预览等。
/// 支持灵活的字段映射，兼容服务端多种命名风格（如 `card_type` / `cardType`）。
class CardPayload {
  // ==================== 字段 ====================

  /// 卡片类型标识（如 'contact', 'group', 'link' 等）
  final String? cardType;

  /// 卡片关联的实体 ID（如用户 ID、群组 ID、文章 ID）
  final String? entityId;

  /// 卡片标题
  final String? title;

  /// 卡片摘要/描述
  final String? summary;

  /// 缩略图 URL
  final String? thumbnailUrl;

  /// 扩展属性键值对
  final Map<String, String> properties;

  // ==================== 构造函数 ====================

  /// 构造 [CardPayload] 实例。
  const CardPayload({
    this.cardType,
    this.entityId,
    this.title,
    this.summary,
    this.thumbnailUrl,
    this.properties = const {},
  });

  /// 从 JSON 反序列化，兼容多种字段命名。
  factory CardPayload.fromJson(Map<String, dynamic> json) => CardPayload(
    cardType: _readString(json, ['cardType', 'card_type', 'type']),
    entityId: _readString(json, ['entityId', 'entity_id', 'id']),
    title: _readString(json, ['title', 'name']),
    summary: _readString(json, ['summary', 'desc', 'description', 'content']),
    thumbnailUrl: _readString(json, [
      'thumbnailUrl',
      'thumbnail_url',
      'avatar',
      'image',
      'imageUrl',
      'image_url',
    ]),
    properties: _readStringMap(json['properties'] ?? json['extra']),
  );

  /// 序列化为 JSON Map。
  Map<String, dynamic> toJson() => {
    'cardType': cardType,
    'entityId': entityId,
    'title': title,
    'summary': summary,
    'thumbnailUrl': thumbnailUrl,
    'properties': properties,
  };

  /// 创建副本并选择性更新字段。
  CardPayload copyWith({
    String? cardType,
    String? entityId,
    String? title,
    String? summary,
    String? thumbnailUrl,
    Map<String, String>? properties,
  }) => CardPayload(
    cardType: cardType ?? this.cardType,
    entityId: entityId ?? this.entityId,
    title: title ?? this.title,
    summary: summary ?? this.summary,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    properties: properties ?? this.properties,
  );

  // ==================== 辅助显示 ====================

  /// 获取优先用于展示的标题，依次尝试 title、entityId、cardType。
  String get displayTitle => _firstNotEmpty([title, entityId, cardType]);

  /// 获取优先用于展示的摘要，仅尝试 summary。
  String get displaySummary => _firstNotEmpty([summary]);

  // ==================== 私有工具方法 ====================

  /// 从 Map 中按优先级读取第一个非空字符串。
  static String? _readString(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return null;
    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  /// 将任意值转换为 `Map<String, String>`。
  ///
  /// 兼容两种服务端格式：
  /// - `Map`：`{"content": "..."}`（本地缓存 / V5 本地序列化）
  /// - `List`：`[{"key": "content", "value": "..."}]`
  ///   （REST 历史接口按 V5 `StringProperty` 模型返回的键值对列表）
  static Map<String, String> _readStringMap(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val.toString()));
    }
    if (value is List) {
      final result = <String, String>{};
      for (final item in value) {
        if (item is! Map) continue;
        final key = item['key'] ?? item['k'];
        if (key == null) continue;
        final text = item['value'] ?? item['v'];
        result[key.toString()] = text?.toString() ?? '';
      }
      return result;
    }
    return const {};
  }

  /// 从字符串列表中返回第一个非空字符串（去除首尾空格）。
  static String _firstNotEmpty(List<String?> values) {
    for (final value in values) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return '';
  }

  // ==================== 字符串表示 ====================

  @override
  String toString() {
    return 'CardPayload{\n'
        '  cardType: $cardType,\n'
        '  entityId: $entityId,\n'
        '  title: $title,\n'
        '  summary: $summary,\n'
        '  thumbnailUrl: $thumbnailUrl,\n'
        '  properties: $properties\n'
        '}';
  }
}

/// 位置消息载荷（V5 协议）
///
/// 用于表示地理位置消息，包含经纬度坐标及地点名称、地址信息。
class LocationPayload {
  // ==================== 字段 ====================

  /// 纬度
  final double? latitude;

  /// 经度
  final double? longitude;

  /// 地点名称（如“钟楼”）
  final String? title;

  /// 详细地址（如“西安市莲湖区北大街”）
  final String? address;

  // ==================== 构造函数 ====================

  const LocationPayload({
    this.latitude,
    this.longitude,
    this.title,
    this.address,
  });

  /// 从 JSON 反序列化，支持 `lat`/`lng` 别名。
  factory LocationPayload.fromJson(Map<String, dynamic> json) =>
      LocationPayload(
        latitude: _readDouble(json['latitude'] ?? json['lat']),
        longitude: _readDouble(json['longitude'] ?? json['lng']),
        title: _readString(json, ['title', 'name']),
        address: _readString(json, ['address', 'addr']),
      );

  /// 序列化为 JSON Map。
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'title': title,
    'address': address,
  };

  /// 创建副本并选择性更新字段。
  LocationPayload copyWith({
    double? latitude,
    double? longitude,
    String? title,
    String? address,
  }) => LocationPayload(
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    title: title ?? this.title,
    address: address ?? this.address,
  );

  // ==================== 辅助显示 ====================

  /// 获取优先展示的标题（首选 title，否则地址）。
  String get displayTitle => _firstNotEmpty([title, address]);

  /// 获取展示地址。
  String get displayAddress => _firstNotEmpty([address]);

  /// 是否包含有效坐标。
  bool get hasCoordinate => latitude != null && longitude != null;

  // ==================== 私有工具方法 ====================

  /// 将动态值转为 double。
  static double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// 从 Map 中按优先级读取第一个非空字符串。
  static String? _readString(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return null;
    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  /// 从字符串列表中返回第一个非空字符串。
  static String _firstNotEmpty(List<String?> values) {
    for (final value in values) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return '';
  }

  // ==================== 字符串表示 ====================

  @override
  String toString() {
    return 'LocationPayload{\n'
        '  latitude: $latitude,\n'
        '  longitude: $longitude,\n'
        '  title: $title,\n'
        '  address: $address\n'
        '}';
  }
}

// ==================== 共享解析工具（供 MessagePayload 复用） ====================

/// 将任意值安全转为 `Map<String, dynamic>`。
Map<String, dynamic>? payloadAsMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

/// 从 Map 中按优先级读取第一个非空字符串（返回空字符串而非 null）。
String payloadReadString(Map<String, dynamic>? source, List<String> keys) {
  if (source == null) return '';
  for (final key in keys) {
    final value = source[key];
    if (value == null) continue;
    final text = value.toString();
    if (text.isNotEmpty) return text;
  }
  return '';
}

/// 从 Map 中按优先级读取第一个非空字符串（可空版本，去空格）。
String? payloadReadStringNullable(
  Map<String, dynamic>? source,
  List<String> keys,
) {
  if (source == null) return null;
  for (final key in keys) {
    final value = source[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}

/// 从字符串列表中返回第一个非空字符串（去除首尾空格）。
String payloadFirstNotEmpty(List<String?> values) {
  for (final value in values) {
    final text = value?.trim();
    if (text != null && text.isNotEmpty) return text;
  }
  return '';
}

/// 将动态值转为 double。
double? payloadReadDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

/// 将动态值转为 int。
int? payloadReadInt(dynamic value) =>
    value == null ? null : int.tryParse(value.toString());

/// 将动态值转为 bool。
bool? payloadReadBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  return value.toString() == 'true';
}

/// 将动态值转为 int 列表。
List<int>? payloadReadIntList(dynamic value) {
  if (value is! List) return null;
  final result = value
      .map((e) => int.tryParse(e.toString()))
      .whereType<int>()
      .toList();
  return result.isEmpty ? null : result;
}

/// 将任意值转换为 `Map<String, String>`（兼容 List 键值对）。
Map<String, String> payloadReadStringMap(dynamic value) {
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val.toString()));
  }
  if (value is List) {
    final result = <String, String>{};
    for (final item in value) {
      if (item is! Map) continue;
      final key = item['key'] ?? item['k'];
      if (key == null) continue;
      final text = item['value'] ?? item['v'];
      result[key.toString()] = text?.toString() ?? '';
    }
    return result;
  }
  return const {};
}
