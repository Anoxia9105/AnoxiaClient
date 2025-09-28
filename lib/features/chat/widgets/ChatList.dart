import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:notepadclient/core/di/injector.dart';
import 'package:notepadclient/core/utils/DateUtil.dart';
import 'package:notepadclient/features/chat/controller/ChatController.dart';
import 'package:notepadclient/shared/widgets/AvatarWidget.dart';
import 'package:notepadclient/shared/widgets/NoData.dart';
import 'package:notepadclient/shared/widgets/VibratingBadge.dart';

final ChatController chatController = getIt<ChatController>();

/// 聊天列表
/// ListView + ListTile
class ChatList extends StatefulWidget {
  const ChatList({super.key});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  @override
  Widget build(BuildContext context) {
    final data = chatController.roomSummary?.data;
    final int roomLength = data?.length ?? 0;

    return Column(
      children: [
        SizedBox(
          height: 50.h,
          child: Row(
            children: [
              Expanded(child: Text("ccccccc")),
              IconButton(icon: const Icon(Icons.add), onPressed: () {}),
            ],
          ),
        ),
        Expanded(
          child: () {
            if (data == null || roomLength <= 0) {
              return NoData();
            }
            return ListView.builder(
              controller: chatController.scrollChatListController,
              itemCount: roomLength,
              itemBuilder: (context, index) {
                //房间名称
                String roomName = data[index].roomName ?? '';
                //房间头像
                String? roomAvatar = data[index].roomAvatar ?? '';
                //最后一条消息时间
                String lastTimestamp = DateUtil.formatTimestampToTime(data[index].lastMessage?.timestamp ?? 0 );
                //最后一条消息内容
                //未读消息数
                int? messageCount = data[index].unreadCount?.toInt() ?? 0;

                //选中背景色
                Color? selectedColor = chatController.selectIndex == index
                    ? Colors.white
                    : null;
                // var room = chatController.getRoom(index);
                return Padding(
                  padding: EdgeInsets.only(left: 2.w, right: 2.w),
                  child: ListTile(
                    // visualDensity: VisualDensity.compact,
                    // dense: true,
                    key: ValueKey(chatController.isScrolling),
                    selected: chatController.selectIndex == index,
                    selectedColor: selectedColor,
                    selectedTileColor: Theme.of(context).primaryColor,
                    hoverColor: chatController.isScrolling
                        ? Colors.transparent
                        : Theme.of(context).hoverColor,
                    leading: AvatarWidget(
                      size: 30,
                      url: roomAvatar,
                      name: roomName,
                    ),
                    title: Text(
                      roomName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(fontSize: 16),
                    ),
                    subtitle: LastMessagePreview(textColor: selectedColor),
                    trailing: Padding(
                      padding: EdgeInsets.all(4),
                      child: Column(
                        children: [
                          /// 时间
                          Text(lastTimestamp, style: TextStyle(color: selectedColor)),
                          Expanded(child: SizedBox.shrink()),

                          ///未读消息数量
                          VibratingBadge(messageCount: messageCount),
                        ],
                      ),
                    ),
                    onTap: () => chatController.setSelectIndex(index),
                  ),
                );
              },
            );
          }(),
        ),
      ],
    );
  }
}

class LastMessagePreview extends StatelessWidget {
  final Color? textColor;

  const LastMessagePreview({super.key, required this.textColor});

  @override
  Widget build(BuildContext context) {
    // if (lastMessage == null) return const SizedBox.shrink();

    final senderNickname = _getSenderNickname();
    final (contentText, icon) = _buildPreviewContent(senderNickname);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          HugeIcon(
            icon: icon,
            size: 14,
            color: textColor?.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            contentText,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(fontSize: 12, color: textColor),
          ),
        ),
      ],
    );
  }

  /// 获取发送者昵称
  String _getSenderNickname() {
    // if (lastMessage!.type == MessageType.system) return ""; // 系统消息不需要昵称
    // if (lastMessage!.senderId == currentUser?.id) return "你: ";
    // final sender = getUserById(lastMessage!.senderId);
    // return "${sender.nickname}: ";
    return "你: ";
  }

  /// 根据消息类型生成预览内容和图标
  (String, IconData?) _buildPreviewContent(String senderNickname) {
    // final msg = lastMessage!;
    // final count = msg.attachments.length;
    // final countStr = count > 1 ? "$count个" : "";
    return (
      "$senderNickname 繁体跑啦的海外渠道帮我去吃不起我才不去我",
      HugeIcons.strokeRoundedBubbleChatTranslate,
    );
    // switch (msg.type) {
    //   case MessageType.text:
    //   case MessageType.emoji:
    //     return ("$senderNickname${msg.content}", HugeIcons.strokeRoundedBubbleChatTranslate);

    //   case MessageType.file:
    //     return ("$senderNickname[ 文件$countStr ]", HugeIcons.strokeRoundedFileAttachment);

    //   case MessageType.image:
    //     return ("$senderNickname[ 图片$countStr ]", HugeIcons.strokeRoundedImage01);

    //   case MessageType.audio:
    //     return ("$senderNickname[ 语音 ]", HugeIcons.strokeRoundedAudioWave01);

    //   case MessageType.video:
    //     return ("$senderNickname[ 视频$countStr ]", HugeIcons.strokeRoundedVideoReplay);

    //   case MessageType.quill:
    //     return ("$senderNickname[ 消息 ]", HugeIcons.strokeRoundedQuillWrite01);

    //   case MessageType.system:
    //     return ("[ 通知 ] ${msg.content}", HugeIcons.strokeRoundedInstallingUpdates01);

    //   case MessageType.aiReply:
    //     return ("[ AI ] ${msg.content}", HugeIcons.strokeRoundedBot);

    //   // 通话相关统一处理
    //   case MessageType.videoCall:
    //     return ("$senderNickname[ 通话请求 ]", HugeIcons.strokeRoundedCall02);
    //   case MessageType.videoAnswer:
    //     return ("$senderNickname[ 通话中 ]", HugeIcons.strokeRoundedCall02);
    //   case MessageType.videoReject:
    //     return ("$senderNickname[ 通话拒绝 ]", HugeIcons.strokeRoundedCall02);
    //   case MessageType.videoHangup:
    //     return ("$senderNickname[ 通话结束 ]", HugeIcons.strokeRoundedCall02);
    //   case MessageType.signal:
    //     return ("$senderNickname[ 连接中 ]", HugeIcons.strokeRoundedCall02);
    //   case MessageType.voiceCall:
    //   case MessageType.voiceAnswer:
    //     return ("$senderNickname[ 通话中 ]", HugeIcons.strokeRoundedCall02);
    //   case MessageType.voiceReject:
    //     return ("$senderNickname[ 通话拒绝 ]", HugeIcons.strokeRoundedCall02);
    //   case MessageType.voiceHangup:
    //     return ("$senderNickname[ 通话结束 ]", HugeIcons.strokeRoundedCall02);
    // }
  }
}
