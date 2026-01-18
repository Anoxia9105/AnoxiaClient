import 'package:flutter/material.dart';

import '../../../../../framework/domain/ChatMessage.dart';
import 'MessageRenderStrategy.dart';

class FileMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(BuildContext context, ChatMessage message,Color textColor) {
    final fileName ='未知文件';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.insert_drive_file,  size: 30),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle( fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}