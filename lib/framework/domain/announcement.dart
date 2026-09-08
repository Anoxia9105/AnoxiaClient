/// 系统公告等级。
enum AnnouncementLevel { normal, required }

/// 当前客户端适用的系统公告。
class Announcement {
  const Announcement({
    required this.id,
    required this.revision,
    required this.title,
    required this.content,
    required this.level,
    required this.publishAt,
    required this.expireAt,
    required this.read,
    required this.acknowledged,
  });

  final int id;
  final int revision;
  final String title;
  final String content;
  final AnnouncementLevel level;
  final DateTime publishAt;
  final DateTime? expireAt;
  final bool read;
  final bool acknowledged;

  String get identity => '$id:$revision';

  Announcement copyWith({bool? read, bool? acknowledged}) => Announcement(
    id: id,
    revision: revision,
    title: title,
    content: content,
    level: level,
    publishAt: publishAt,
    expireAt: expireAt,
    read: read ?? this.read,
    acknowledged: acknowledged ?? this.acknowledged,
  );

  static Announcement fromJson(Map<dynamic, dynamic> json) {
    final id = _requiredInt(json['id']);
    final revision = _requiredInt(json['revision']);
    final title = json['title'];
    final content = json['content'];
    final publishAt = DateTime.tryParse(json['publishAt']?.toString() ?? '');
    if (title is! String || content is! String || publishAt == null) {
      throw const FormatException('invalid announcement');
    }
    final rawLevel = json['level']?.toString().toUpperCase();
    final level = switch (rawLevel) {
      'NORMAL' => AnnouncementLevel.normal,
      'REQUIRED' => AnnouncementLevel.required,
      _ => throw const FormatException('invalid announcement level'),
    };
    final rawExpireAt = json['expireAt'];
    final expireAt = rawExpireAt == null
        ? null
        : DateTime.tryParse(rawExpireAt.toString());
    if (rawExpireAt != null && expireAt == null) {
      throw const FormatException('invalid announcement expiry');
    }
    if (json['read'] is! bool || json['acknowledged'] is! bool) {
      throw const FormatException('invalid announcement status');
    }
    return Announcement(
      id: id,
      revision: revision,
      title: title,
      content: content,
      level: level,
      publishAt: publishAt,
      expireAt: expireAt,
      read: json['read'] as bool,
      acknowledged: json['acknowledged'] as bool,
    );
  }

  static int _requiredInt(dynamic value) {
    final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
    if (parsed == null) throw const FormatException('invalid announcement id');
    return parsed;
  }
}

class AnnouncementPage {
  const AnnouncementPage({required this.rows, required this.total});

  final List<Announcement> rows;
  final int total;
}
