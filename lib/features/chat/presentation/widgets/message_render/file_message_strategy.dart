import 'package:anoxia/framework/provider/auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../framework/domain/chat_message.dart';
import '../../../../../framework/protocol/message/attachment.dart';
import 'base/message_render_strategy.dart';
import 'file_message_widgets.dart';

/// 文件消息渲染策略
///
/// 处理文件消息的显示和下载，支持：
/// - 显示文件列表（支持多个文件）
/// - 文件下载进度显示
/// - 自动检测已下载文件
/// - 打开文件所在位置
/// - 同名文件自动编号避免覆盖
class FileMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(
    BuildContext context,
    ChatMessage message,
    Color textColor,
  ) {
    final file = message.payload?.file;
    final fileList = file != null && file.url?.isNotEmpty == true
        ? [file]
        : <Attachment>[];

    if (fileList.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentUser = ProviderScope.containerOf(
      context,
    ).read(authControllerProvider).value;
    final isSelf = message.senderId == currentUser?.userId;

    return FileMessageList(fileList: fileList, isSelf: isSelf);
  }
}
