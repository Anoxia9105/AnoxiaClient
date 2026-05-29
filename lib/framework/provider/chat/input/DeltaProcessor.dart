import 'dart:convert';

import 'package:anoxia/framework/protocol/message/Attachment.dart';
import 'package:characters/characters.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'dart:math' as math;

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
          if (userId != null) {
            ids.add(userId);
          }
        }
      }
    }

    return ids.toList();
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
    if (images.isNotEmpty || files.isNotEmpty || mentionedUserIds.isNotEmpty) {
      return false;
    }

    // 条件2：纯文本字符数为1（用characters处理emoji多字节）
    final textCharacters = plainText.characters;
    if (textCharacters.length != 1) {
      return false;
    }

    // 条件3：这个字符是emoji
    final singleChar = textCharacters.first;
    return _isEmoji(singleChar);
  }

  /// 核心：判断单个字符是否是emoji（覆盖主流emoji Unicode区间）
  bool _isEmoji(String character) {
    if (character.isEmpty) return false;

    final runes = character.runes.toList();
    if (runes.isEmpty) return false;

    final code = runes[0];

    // 完整的emoji Unicode区间（按类型分类，覆盖99%+的常用emoji）
    return (code >= 0x1F600 && code <= 0x1F64F) || // 表情符号（😀😜😭）
        (code >= 0x1F300 && code <= 0x1F5FF) || // 符号/图标（🔥⭐🎂）
        (code >= 0x1F680 && code <= 0x1F6FF) || // 交通/地图（🚗✈️🗺️）
        (code >= 0x1F1E0 && code <= 0x1F1FF) || // 国旗/地区符号（🇨🇳🇺🇸）
        (code >= 0x2600 && code <= 0x26FF) || // 杂项符号（☀️☁️⚡）
        (code >= 0x2700 && code <= 0x27BF) || // 装饰符号（✌️❤️✏️）
        (code >= 0x1F900 && code <= 0x1F9FF) || // 补充表情（🤦‍♂️🤯🥳）
        (code >= 0x1F004 && code <= 0x1F0CF) || // 扑克牌（🃏🀄）
        (code >= 0x00A9 && code <= 0x00AE) || // 版权符号（©️®️）
        (code >= 0x203C && code <= 0x2049) || // 特殊符号（‼️⁉️）
        (code >= 0x25AA && code <= 0x25AB) || // 几何符号（▪️▫️）
        (code >= 0x25FB && code <= 0x25FE) || // 空心/实心圆（◻️◼️）
        (code >= 0x2B05 && code <= 0x2B07) || // 方向箭头（⬅️⬆️➡️）
        (code >= 0x2B1B && code <= 0x2B1C) || // 方块（⬛⬜）
        (code >= 0x2B50 && code <= 0x2B50) || // 星星（⭐）
        (code >= 0x1F170 && code <= 0x1F19A) || // 字母符号（🅰️🆗🆙）
        (code >= 0x1F18E && code <= 0x1F19A) || // 符号组合（🆘🆚🆓）
        (code >= 0x3030 && code <= 0x3030) || // 波浪线（〰️）
        (code >= 0x00B0 && code <= 0x00B0) || // 度符号（°）
        (code >= 0x20E3 && code <= 0x20E3) || // 组合符号（💯✳️）
        (code >= 0xFE0F && code <= 0xFE0F) || // 变体选择符（emoji样式切换）
        (code >= 0x1F000 && code <= 0x1F0FF) || // 麻将/多米诺（🀄🎲）
        (code >= 0x1F700 && code <= 0x1F77F) || // 几何图形（🌀⚪🟡）
        (code >= 0x1F780 && code <= 0x1F7FF) || // 扩展图形（🟦🟧🟨）
        (code >= 0x1F800 && code <= 0x1F8FF) || // 补充符号
        (code >= 0x1F900 && code <= 0x1F9FF) || // 更多补充表情
        (code >= 0x1FA00 && code <= 0x1FA6F) || // 手势/身体部位
        (code >= 0x1FA70 && code <= 0x1FAFF) || // 动物/自然
        (code >= 0x1F018 && code <= 0x1F02F); // 数字符号（🅾️🆑）
  }

  /// 获取所有图片附件
  List<Attachment> get images =>
      _allAttachments.where((a) => a.isImage).toList();

  /// 获取所有非图片文件附件
  List<Attachment> get files =>
      _allAttachments.where((a) => !a.isImage).toList();

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
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return "${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}";
  }
}
