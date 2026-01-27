import 'dart:convert';

import 'package:anoxia/framework/protocol/message/Attachment.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'dart:math' as math;

class DeltaProcessor {
  final Delta delta;
  final Map<String, String> uploadState;

  DeltaProcessor(this.delta, this.uploadState);

  // 获取所有附件，并预先替换好 URL
  List<Attachment> get _allAttachments {
    return delta
        .toList()
        .where((op) => op.isInsert && op.data is Map)
        .map((op) {
          final data = op.data as Map;
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

  // 检查是否所有附件都已经拿到了服务器 URL
  bool get isAllUploaded {
    final embeds = delta.toList().where((op) => op.isInsert && op.data is Map);
    for (final op in embeds) {
      final data = op.data as Map;
      final embedData = data['image'] ?? data['file'];
      final finalData = jsonDecode(embedData);
      final id = finalData['id']; // 假设你的 Attachment toJson 后有 id
      if (id != null && !uploadState.containsKey(id)) {
        return false; // 只要有一个 ID 没在 uploadState 里，就说明还没传完或失败了
      }
    }
    return true;
  }

  // 分类：图片
  List<Attachment> get images =>
      _allAttachments.where((a) => a.isImage).toList();

  // 分类：非图片文件
  List<Attachment> get files =>
      _allAttachments.where((a) => !a.isImage).toList();

  // 文字内容
  String get plainText => delta
      .toList()
      .where((op) => op.data is String)
      .map((op) => op.data as String)
      .join()
      .trim();

  // 是否有样式
  bool get hasAttributes => delta.toList().any(
    (op) => op.attributes != null && op.attributes!.isNotEmpty,
  );

  // 纯文本 Delta
  Delta get textOnlyDelta {
    final newDelta = Delta();
    for (final op in delta.toList()) {
      if (op.data is String) newDelta.insert(op.data, op.attributes);
    }
    return newDelta;
  }

  // 2. 统计文件总数
  int get totalCount => _allAttachments.length;

  // 3. 统计总大小（字节）
  int get totalSize => _allAttachments.fold(0, (sum, a) => sum + (a.size ?? 0));

  String formattedTotalSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return "${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}";
  }
}
