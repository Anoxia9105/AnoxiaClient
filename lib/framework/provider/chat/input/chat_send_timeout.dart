// 发送超时时间计算。
//
// 从 ChatInputController 抽出的纯函数，便于对动态超时算法做单元测试：
// 消息可能永远转圈（超时过长）或过早失败（超时过短）都由这里决定。
import 'package:anoxia/framework/protocol/message/attachment.dart';
import 'package:anoxia/framework/protocol/message/message_enum.dart';

/// 计算发送超时时间（秒）
///
/// 根据消息类型和附件数量动态计算：
/// - 基础值 10 秒 + 每个附件 2 秒
/// - 若为音频、文件或视频类型额外加 5 秒
/// - 最终限制在 10~30 秒之间
int resolveSendTimeoutSeconds({
  required MessageType type,
  List<Attachment>? attachments,
}) {
  final attachmentCount = attachments?.length ?? 0;
  var timeout = 10 + (attachmentCount * 2);

  if (type == MessageType.audio ||
      type == MessageType.file ||
      type == MessageType.video) {
    timeout += 5;
  }

  return timeout.clamp(10, 30);
}
