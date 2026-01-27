import 'package:anoxia/common/utils/fileUtil.dart';
import 'package:anoxia/common/widgets/Toast.dart';
import 'package:flutter/material.dart';

import '../../../../../framework/domain/ChatMessage.dart';
import '../../../../../framework/protocol/message/Attachment.dart';
import 'MessageRenderStrategy.dart';

class FileMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    final fileList = message.attachments;

    if (fileList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: BoxConstraints(maxWidth: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: fileList.asMap().entries.map((entry) {
          final index = entry.key;
          final file = entry.value;
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 8.0), // 文件之间的间距
            child: _buildFileItem(context, file),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, Attachment file) {
    return InkWell(
      onTap: () => Toast.showToast("准备下载或打开: ${file.name}"),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            FileUtil.buildFileIcon(file.type ?? ''),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name ?? '未知文件',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    FileUtil.formatFileSize(file.size ?? 0),
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
