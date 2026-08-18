/// 记事本-笔记模型
///
/// 包含树列表摘要 [NoteBrief] 与全文 [NoteDoc] 两类，支持 snake_case / camelCase 兼容解析。
library;

import 'package:flutter/foundation.dart';

/// 笔记摘要（树 / 搜索列表用）
@immutable
class NoteBrief {
  final int id;

  /// 所属文件夹ID，null=未分类(根级)
  final int? folderId;

  /// 标题
  final String title;

  /// 纯文本预览
  final String preview;

  /// 更新时间
  final DateTime? updatedAt;

  /// 是否置顶
  final bool pinned;

  /// 置顶时间
  final DateTime? pinTime;

  /// 删除时间（回收站列表用，非回收站为 null）
  final DateTime? deletedAt;

  const NoteBrief({
    required this.id,
    required this.folderId,
    required this.title,
    required this.preview,
    required this.updatedAt,
    this.pinned = false,
    this.pinTime,
    this.deletedAt,
  });

  factory NoteBrief.fromJson(Map<String, dynamic> json) {
    return NoteBrief(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      folderId: int.tryParse(json['folderId']?.toString() ?? json['folder_id']?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      preview: json['preview']?.toString() ?? '',
      updatedAt: _parseTime(json['updatedAt'] ?? json['updated_at']),
      pinned: (json['pinned']?.toString() ?? '0') == '1' ||
          (json['pinned'] is bool && json['pinned'] == true),
      pinTime: _parseTime(json['pinTime'] ?? json['pin_time']),
      deletedAt: _parseTime(json['deletedAt'] ?? json['deleted_at']),
    );
  }

  /// 预览文本（为空时回退到标题）
  String get displayPreview {
    final text = preview.trim();
    if (text.isNotEmpty) return text;
    return title.trim();
  }
}

/// 笔记全文
@immutable
class NoteDoc {
  final int id;

  /// 所属文件夹ID，null=未分类(根级)
  final int? folderId;

  /// 标题
  final String title;

  /// Quill Delta JSON 字符串
  final String content;

  /// 纯文本副本
  final String plainText;

  final DateTime? createdAt;

  final DateTime? updatedAt;

  const NoteDoc({
    required this.id,
    required this.folderId,
    required this.title,
    required this.content,
    required this.plainText,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteDoc.fromJson(Map<String, dynamic> json) {
    return NoteDoc(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      folderId: int.tryParse(json['folderId']?.toString() ?? json['folder_id']?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      plainText: json['plainText']?.toString() ?? json['plain_text']?.toString() ?? '',
      createdAt: _parseTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseTime(json['updatedAt'] ?? json['updated_at']),
    );
  }

  NoteDoc copyWith({
    int? id,
    int? Function()? folderId,
    String? title,
    String? content,
    String? plainText,
    DateTime? Function()? createdAt,
    DateTime? Function()? updatedAt,
  }) {
    return NoteDoc(
      id: id ?? this.id,
      folderId: folderId != null ? folderId() : this.folderId,
      title: title ?? this.title,
      content: content ?? this.content,
      plainText: plainText ?? this.plainText,
      createdAt: createdAt != null ? createdAt() : this.createdAt,
      updatedAt: updatedAt != null ? updatedAt() : this.updatedAt,
    );
  }
}

DateTime? _parseTime(dynamic value) {
  if (value == null) return null;
  final raw = value.toString();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

/// 级联删除结果
@immutable
class NoteDeleteResult {
  /// 删除的文件夹数
  final int folderDeleted;

  /// 删除的笔记数
  final int noteDeleted;

  const NoteDeleteResult({required this.folderDeleted, required this.noteDeleted});

  factory NoteDeleteResult.fromJson(Map<String, dynamic> json) {
    return NoteDeleteResult(
      folderDeleted: int.tryParse(json['folderDeleted']?.toString() ?? json['folder_deleted']?.toString() ?? '0') ?? 0,
      noteDeleted: int.tryParse(json['noteDeleted']?.toString() ?? json['note_deleted']?.toString() ?? '0') ?? 0,
    );
  }
}
