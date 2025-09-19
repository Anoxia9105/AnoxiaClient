import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:notepadclient/features/chat/controller/ChatController.dart';
import 'package:notepadclient/shared/widgets/NoData.dart';

import '../../../core/di/injector.dart';

final ChatController chatController = getIt<ChatController>();

/// 显示消息项的数据结构
/// 包含 ChatMessage 或 时间标签 (String)，以及消息原始索引（仅 ChatMessage 有效）
class DisplayItem {
  final dynamic data;
  final int? originalIndex;

  DisplayItem({required this.data, this.originalIndex});
}

class ChatDetail extends StatefulWidget {
  const ChatDetail({super.key});

  @override
  State<ChatDetail> createState() => _ChatDetailState();
}

class _ChatDetailState extends State<ChatDetail> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 展示用列表（包括消息和时间标签）
  List<DisplayItem> displayItems = [];

  // 节流用的 Timer，防止滚动时频繁触发计算
  Timer? _throttleTimer;

  @override
  void initState() {
    super.initState();
    // 添加滚动监听器，用于监听可见项变化
    // widget.chatController.listViewController.addListener(_onVisibleItemChanged);
  }

  @override
  void dispose() {
    // 资源释放：移除监听器、取消定时器
    // widget.chatController.listViewController.removeListener(
    //   _onVisibleItemChanged,
    // );
    // _throttleTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // _updateDisplayItems(); // 初始化时构造展示数据
  }

  @override
  void didUpdateWidget(covariant ChatDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // _updateDisplayItems(); // 控制器变更时也重新构造数据
  }

  /// 构建展示列表（倒序插入时间标签 + 映射原始索引）
  //
  // void _updateDisplayItems() {
  //   final messages = widget.chatController.getMessagesForRoom();
  //   final List<DisplayItem> result = [];
  //
  //   for (int i = messages.length - 1; i >= 0; i--) {
  //     final msg = messages[i];
  //
  //     // 判断是否需要在这条消息“前面”插入时间标签
  //     if (i == messages.length - 1 || _needTimeLabel(msg, messages[i + 1])) {
  //       result.add(
  //         DisplayItem(data: DateUtil.formatMessageTimestamp(msg.timestamp!)),
  //       );
  //     }
  //
  //     // 添加消息本身
  //     result.add(DisplayItem(data: msg, originalIndex: i));
  //   }
  //
  //   displayItems = result.reversed.toList();
  // }

  @override
  Widget build(BuildContext context) {
    // final ctl = widget.chatController;

    // 聊天室为空时显示欢迎页面
    // if (ctl.chatRoom == null) return const Welcome();

    // final ChatRoom room = ctl.chatRoom;
    return Scaffold(
      key: _scaffoldKey,
      // backgroundColor: themeColor,
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        // backgroundColor: themeColor,
        // title: Text(room.roomName),
        actions: [
          // IconButton(
          //   tooltip: "视频通话",
          //   onPressed:
          //       ctl
          //               .rtcCallController
          //               .isConnected // 如果已经连接，则禁用发起通话按钮
          //           ? null
          //           : () {
          //             ctl.sendVideoCallRequest(); // 发起视频通话请求
          //           },
          //   icon: const HugeIcon(
          //     icon: HugeIcons.strokeRoundedVideo02,
          //     size: 20,
          //   ),
          // ),
          // IconButton(
          //   tooltip: "语音通话",
          //   onPressed:
          //       ctl
          //               .rtcCallController
          //               .isConnected // 如果已经连接，则禁用发起通话按钮
          //           ? null
          //           : () {
          //             ctl.sendVoiceCallRequest(); // 发起语音通话请求
          //           },
          //   icon: const HugeIcon(icon: HugeIcons.strokeRoundedCall02, size: 20),
          // ),
          // room.roomType == ChatRoomType.group
          //     ? IconButton(
          //       onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          //       icon: const HugeIcon(
          //         icon: HugeIcons.strokeRoundedAddTeam,
          //         size: 20,
          //       ),
          //     )
          //     : SizedBox.shrink(),
          IconButton(
            onPressed: () {},
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedMoreHorizontal,
              size: 22,
            ),
          ),
        ],
      ),
      /*endDrawer: Padding(
        padding: const EdgeInsets.only(top: 50, bottom: 100),
        child: Drawer(
          backgroundColor: themeColor,
          elevation: 4,
          width: 80.w,
          child: ListView.separated(
            separatorBuilder: (context, index) => Divider(height: 1),
            itemCount: room.memberIds.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: Text(
                    "群成员（${room.memberIds.length}）",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                );
              }

              final member = ctl.getUser(room.memberIds[index - 1]);
              final role = room.memberRoles[member.id] ?? ChatUserRole.member;

              return ListTile(
                visualDensity: VisualDensity.compact,
                leading: AvatarWidget(url: member.avatarUrl),
                title: Text(
                  member.nickname,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(fontSize: 14),
                ),
                trailing: Text(role.label),
                onTap: () {},
              );
            },
          ),
        ),
      ),*/
      body: Stack(
        children: [
          // 消息为空时显示暂无数据页面
          displayItems.isEmpty
              ? const NoData(title: "这里还没有消息哦", subTitle: "快来发送第一条消息，开启新的对话吧！")
              : FlutterListView(
                  reverse: true,
                  controller: chatController.listViewController,
                  delegate: FlutterListViewDelegate((context, index) {
                    final item = displayItems[index];
                    Widget messageWidget = SizedBox.shrink();
                    // 时间标签渲染
                    if (item.data is String) {
                      messageWidget = Center(
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 10.h),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                          child: Text(
                            item.data,
                            style: TextStyle(
                              fontSize: 10,
                              // color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                      );
                    }

                    // // 消息渲染
                    // if (item.data is ChatMessage) {
                    //   final ChatMessage msg = item.data;
                    //   final isMe = msg.senderId == currentUser.id;
                    //   final sender = ctl.getUser(msg.senderId);
                    //   final payload = MessagePayload(
                    //     name: sender.nickname,
                    //     type: msg.type.name,
                    //     reverse: !isMe,
                    //     avatar: sender.avatarUrl,
                    //     content: msg.content,
                    //     status: msg.status,
                    //     metadata: msg.metadata,
                    //     attachments: msg.attachments,
                    //     time:
                    //         msg.timestamp != null
                    //             ? DateUtil.formatTime(msg.timestamp!)
                    //             : '',
                    //   );
                    //   messageWidget = ChatMessageBubble(
                    //     key: ValueKey(msg.messageId), // 确保每条消息都有唯一的Key
                    //     payload: payload,
                    //   );
                    // }

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: messageWidget,
                    );
                  }, childCount: displayItems.length),
                ),
        ],
      ),
      // bottomNavigationBar: ChatInputBar(chatController: ctl),
    );
  }

  /// 滚动可见区域变化处理（节流控制，避免频繁触发）
  void _onVisibleItemChanged() {
    if (_throttleTimer?.isActive ?? false) return;

    _throttleTimer = Timer(const Duration(milliseconds: 300), () {
      final visibleItems = chatController.listViewController.sliverController
          .getVisibleIndexData();

      if (visibleItems == null) return;

      // ctl.setScrollToBottom(visibleItems.any((i) => i < 5));

      for (final index in visibleItems) {
        if (index < 0 || index >= displayItems.length) continue;
        final item = displayItems[index];
        if (item.originalIndex != null) {
          // final msg = ctl.getMessagesForRoom()[item.originalIndex!];
          // debugPrint("可见消息：${msg.messageId}");
        }
      }
    });
  }

  /// 判断是否需要插入时间标签
  /// - 跨天 或 与上一条消息间隔超过30分钟
  // bool _needTimeLabel(ChatMessage newer, ChatMessage older) {
  //   if (newer.timestamp == null || older.timestamp == null) return false;
  //   final diff = newer.timestamp!.difference(older.timestamp!);
  //   return diff.inMinutes.abs() > 30 ||
  //       !DateUtil.isSameDay(newer.timestamp!, older.timestamp!);
  // }
}
