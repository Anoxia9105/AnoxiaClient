import 'dart:convert';
import 'dart:math' as math;

import 'package:anoxia/common/utils/emoji_util.dart';
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:anoxia/framework/protocol/message/message_payload.dart';
import 'package:flutter_quill/quill_delta.dart';

/// Quill Delta 内容处理器
///
/// 负责解析和处理富文本编辑器的 [Delta] 数据，是消息发送前的核心处理组件。
///
/// 主要功能：
/// - 提取图片/文件附件（自动替换上传后的服务器 URL）
/// - 提取 @提及用户 ID 列表
/// - 判断是否是单个 Emoji（用于特殊展示）
/// - 统计附件数量和总大小
/// - 过滤 Delta（保留文本、样式、Mention，剔除图片和文件）
///
/// [delta] Quill 编辑器的 Delta 数据
/// [uploadState] 上传状态映射：文件ID -> 服务器URL
class DeltaProcessor {
  /// Quill Delta 数据
  final Delta delta;

  /// 上传状态映射：文件ID -> 服务器URL
  final Map<String, String> uploadState;

  /// 创建 Delta 处理器
  DeltaProcessor(this.delta, this.uploadState);

  /// 获取所有附件，并自动替换为服务器 URL
  ///
  /// 从 Delta 中提取所有图片和文件附件，并用 uploadState 中的服务器 URL
  /// 替换本地路径（如果已上传成功）
  List<Attachment> get _allAttachments {
    return delta
        .toList()
        .where((op) => op.isInsert && op.data is Map)
        .map((op) {
          final data = op.data as Map;

          final embedData = data['image'] ?? data['file'];
          if (embedData == null) return null;

          final attachment = Attachment.fromEmbed(
            data['image'] ?? data['file'],
          );

          if (attachment == null) return null;
          // 自动匹配服务器 URL
          return attachment.copyWith(
            url: uploadState[attachment.id] ?? attachment.url,
          );
        })
        .whereType<Attachment>()
        .toList();
  }

  /// 获取文档中所有附件 ID（用于清理已从编辑器中删除的上传记录）
  Set<String> get attachmentIds =>
      _allAttachments.map((a) => a.id).whereType<String>().toSet();

  /// 检查是否所有附件都已上传成功
  ///
  /// 遍历所有嵌入对象，检查每个附件的 ID 是否在 uploadState 中存在对应的服务器 URL
  /// 返回 true 表示所有附件都已上传完成，可以发送消息
  bool get isAllUploaded {
    final embeds = delta.toList().where((op) => op.isInsert && op.data is Map);
    for (final op in embeds) {
      final data = op.data as Map;
      final embedData = data['image'] ?? data['file'];
      if (embedData == null) {
        continue;
      }
      final finalData = jsonDecode(embedData);
      final id = finalData['id']; // 假设你的 Attachment toJson 后有 id
      if (id != null && !uploadState.containsKey(id)) {
        return false; // 只要有一个 ID 没在 uploadState 里，就说明还没传完或失败了
      }
    }
    return true;
  }

  /// 获取文档中所有被提及的用户 ID
  ///
  /// 「@所有人」占位 ID（[kMentionAllUserId]）不计入真实用户提醒列表，
  /// 该标记通过 [mentionAll] 单独透传。
  List<int> get mentionedUserIds {
    final ids = <int>{}; // 使用 Set 去重

    for (final op in delta.toList()) {
      // 检查 op 是否是插入操作且数据是 Map (Embed 对象)
      if (op.isInsert && op.data is Map) {
        final data = op.data as Map;

        // 检查 Map 中是否包含 'mention' key (对应 QuillMentionBuild.key)
        if (data.containsKey('mention')) {
          final mentionContent = data['mention'];

          // 根据 QuillMentionBuild 的逻辑，数据可能是 String (JSON) 也可能是 Map
          final Map<String, dynamic> mentionMap = mentionContent is String
              ? jsonDecode(mentionContent)
              : mentionContent as Map<String, dynamic>;

          final int? userId = mentionMap['userId'];
          if (userId != null && userId != kMentionAllUserId) {
            ids.add(userId);
          }
        }
      }
    }

    return ids.toList();
  }

  /// 是否 @了房间内所有人（delta 中存在 @所有人 embed）
  bool get mentionAll {
    for (final op in delta.toList()) {
      if (op.isInsert && op.data is Map) {
        final data = op.data as Map;
        if (data.containsKey('mention')) {
          final mentionContent = data['mention'];
          final Map<String, dynamic> mentionMap = mentionContent is String
              ? jsonDecode(mentionContent)
              : mentionContent as Map<String, dynamic>;
          if (mentionMap['userId'] == kMentionAllUserId) return true;
        }
      }
    }
    return false;
  }

  /// 生成用于发送的 Delta：保留文本、样式、Mention，剔除图片和文件
  Delta get filteredDelta {
    final newDelta = Delta();

    for (final op in delta.toList()) {
      // 只处理 Insert 操作
      if (!op.isInsert) continue;

      if (op.data is String) {
        // 1. 保留纯文本 (带样式)
        newDelta.insert(op.data, op.attributes);
      } else if (op.data is Map) {
        final data = op.data as Map;

        // 2. 只保留 Mention，剔除 Image 和 File
        if (data.containsKey('mention')) {
          newDelta.insert(data, op.attributes);
        }
        // 如果是 image 或 file，这里什么都不做，直接丢弃
      }
    }

    // 移除末尾多余的空行 (可选，根据你的 UI 需求决定是否保留)
    // if (newDelta.isNotEmpty && newDelta.last.data == '\n') { ... }

    return newDelta;
  }

  /// 判断是否是单个 emoji（无其他内容、无图片/文件/mention）
  bool get isSingleEmoji {
    // 条件1：无图片、无文件、无@提及
    if (images.isNotEmpty ||
        videos.isNotEmpty ||
        files.isNotEmpty ||
        mentionedUserIds.isNotEmpty ||
        mentionAll) {
      return false;
    }

    return EmojiUtil.isSingleEmoji(plainText);
  }

  /// 获取所有图片附件（排除 GIF 视频？ GIF 仍视为图片）
  List<Attachment> get images =>
      _allAttachments.where((a) => a.isImage && !a.isVideo).toList();

  /// 获取所有视频附件
  List<Attachment> get videos =>
      _allAttachments.where((a) => a.isVideo).toList();

  /// 获取所有非图片非视频文件附件
  List<Attachment> get files =>
      _allAttachments.where((a) => !a.isImage && !a.isVideo).toList();

  /// 提取纯文本内容（去除所有嵌入对象）
  String get plainText => delta
      .toList()
      .where((op) => op.data is String)
      .map((op) => op.data as String)
      .join()
      .trim();

  /// 判断 Delta 是否包含样式属性
  bool get hasAttributes => delta.toList().any(
    (op) => op.attributes != null && op.attributes!.isNotEmpty,
  );

  /// 获取只包含文本的 Delta（剔除所有嵌入对象）
  Delta get textOnlyDelta {
    final newDelta = Delta();
    for (final op in delta.toList()) {
      if (op.data is String) newDelta.insert(op.data, op.attributes);
    }
    return newDelta;
  }

  /// 获取附件总数
  int get totalCount => _allAttachments.length;

  /// 获取所有附件的总大小（字节）
  int get totalSize => _allAttachments.fold(0, (sum, a) => sum + (a.size ?? 0));

  /// 格式化文件大小为可读字符串
  ///
  /// [bytes] 字节数
  /// 返回如 "1.5 MB" 的格式化字符串
  String formattedTotalSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return '${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }
}
