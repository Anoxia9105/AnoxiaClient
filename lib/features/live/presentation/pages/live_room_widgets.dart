/// 直播间页面组件库
///
/// 包含直播间 UI 的所有子组件，如底部控制栏、房间头部、弹幕面板、
/// 侧边栏、连麦控制、视频画面渲染等。
part of 'live_room_page.dart';

/// 底部控制区域组件
///
/// 整合连麦请求栏、移动端聊天面板、聊天输入框和直播控制按钮。
class _BottomControlSection extends StatelessWidget {
  /// 是否为主播
  final bool isHost;

  /// 连麦请求列表
  final List<_CohostRequest> cohostRequests;

  /// 是否已发起连麦请求
  final bool cohostRequested;

  /// 连麦是否激活
  final bool cohostActive;

  /// 是否显示移动端聊天面板
  final bool showMobileChat;

  /// 聊天消息列表
  final List<_LiveChatMessage> messages;

  /// 聊天输入控制器
  final TextEditingController chatController;

  /// 发送消息回调
  final VoidCallback onSendMessage;

  /// 接受连麦回调
  final ValueChanged<_CohostRequest> onAcceptCohost;

  /// 拒绝连麦回调
  final ValueChanged<_CohostRequest> onRejectCohost;

  /// 发起连麦请求回调
  final VoidCallback onRequestCohost;

  /// 取消连麦请求回调
  final VoidCallback onCancelCohostRequest;

  /// 切换摄像头回调
  final Future<void> Function() onToggleCamera;

  /// 切换麦克风回调
  final Future<void> Function() onToggleMic;

  /// 屏幕共享回调
  final Future<void> Function() onShareScreen;

  /// 离开回调
  final VoidCallback onLeave;

  const _BottomControlSection({
    required this.isHost,
    required this.cohostRequests,
    required this.cohostRequested,
    required this.cohostActive,
    required this.showMobileChat,
    required this.messages,
    required this.chatController,
    required this.onSendMessage,
    required this.onAcceptCohost,
    required this.onRejectCohost,
    required this.onRequestCohost,
    required this.onCancelCohostRequest,
    required this.onToggleCamera,
    required this.onToggleMic,
    required this.onShareScreen,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isHost && cohostRequests.isNotEmpty) ...[
          _CohostRequestBar(
            requests: cohostRequests,
            onAccept: onAcceptCohost,
            onReject: onRejectCohost,
          ),
          const SizedBox(height: 8),
        ],
        if (showMobileChat) ...[
          _ChatPanel(messages: messages),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (showMobileChat) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: chatController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'live_chat_placeholder'.tr(),
                          hintStyle: const TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => onSendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onSendMessage,
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              _LiveControls(
                isHost: isHost,
                cohostRequested: cohostRequested,
                cohostActive: cohostActive,
                onRequestCohost: onRequestCohost,
                onCancelCohostRequest: onCancelCohostRequest,
                onToggleCamera: onToggleCamera,
                onToggleMic: onToggleMic,
                onShareScreen: onShareScreen,
                onLeave: onLeave,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 房间头部信息组件
///
/// 显示主播/观众身份标签、可见性、直播来源、房间标题和连接状态。
class _RoomHeader extends StatelessWidget {
  /// 是否为主播
  final bool isHost;

  /// 房间 ID
  final String roomId;

  /// 房间标题
  final String title;

  /// 直播可见性
  final LiveVisibility visibility;

  /// 直播来源
  final LiveSource source;

  /// 连接状态
  final String connectionState;

  /// 参与者数量
  final int participantCount;

  const _RoomHeader({
    required this.isHost,
    required this.roomId,
    required this.title,
    required this.visibility,
    required this.source,
    required this.connectionState,
    required this.participantCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Badge(
                label: isHost ? '主播' : '观众',
                color: isHost ? Colors.redAccent : Colors.blueAccent,
              ),
              const SizedBox(width: 8),
              _Badge(
                label: visibility.label,
                color: visibility == LiveVisibility.public
                    ? Colors.green
                    : Colors.deepPurpleAccent,
              ),
              const SizedBox(width: 8),
              _Badge(label: source.label, color: Colors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.isEmpty
                      ? (isHost ? '你正在直播 $roomId' : '你正在观看 $roomId')
                      : title,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '房间号: $roomId · 状态: $connectionState · 参与者: $participantCount',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// 标签徽章组件
///
/// 圆角矩形彩色标签，用于标识状态、角色等信息。
class _Badge extends StatelessWidget {
  /// 标签文本
  final String label;

  /// 标签颜色
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

/// 聊天面板组件
///
/// 移动端使用的弹幕消息列表，以列表形式展示聊天记录。
class _ChatPanel extends StatelessWidget {
  /// 聊天消息列表
  final List<_LiveChatMessage> messages;

  const _ChatPanel({required this.messages});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '弹幕互动',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${message.name}: ',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: message.isHost
                                ? Colors.white
                                : Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 直播侧边面板组件
///
/// 桌面端使用的侧边弹幕面板，包含消息列表、聊天输入框和发送按钮。
class _LiveSidePanel extends StatelessWidget {
  /// 聊天消息列表
  final List<_LiveChatMessage> messages;

  /// 聊天输入控制器
  final TextEditingController chatController;

  /// 是否为主播
  final bool isHost;

  /// 发送消息回调
  final VoidCallback onSend;

  const _LiveSidePanel({
    required this.messages,
    required this.chatController,
    required this.isHost,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '弹幕互动',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${message.name}: ',
                          style: TextStyle(
                            color: message.isHost
                                ? Colors.redAccent
                                : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: message.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: chatController,
                  style: const TextStyle(color: Colors.white),
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText: isHost ? '发送主播弹幕...' : '说点什么...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    counterStyle: const TextStyle(color: Colors.white30),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onSend,
                icon: const Icon(Icons.send, size: 16),
                label: Text('toolbar_send'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 直播控制按钮组
///
/// 提供摄像头、麦克风、屏幕共享、连麦和离开等控制按钮。
class _LiveControls extends StatelessWidget {
  /// 是否为主播
  final bool isHost;

  /// 是否已发起连麦请求
  final bool cohostRequested;

  /// 连麦是否激活
  final bool cohostActive;

  /// 发起连麦请求回调
  final VoidCallback onRequestCohost;

  /// 取消连麦请求回调
  final VoidCallback onCancelCohostRequest;

  /// 切换摄像头回调
  final VoidCallback onToggleCamera;

  /// 切换麦克风回调
  final VoidCallback onToggleMic;

  /// 屏幕共享回调
  final VoidCallback onShareScreen;

  /// 离开回调
  final VoidCallback onLeave;

  const _LiveControls({
    required this.isHost,
    required this.cohostRequested,
    required this.cohostActive,
    required this.onRequestCohost,
    required this.onCancelCohostRequest,
    required this.onToggleCamera,
    required this.onToggleMic,
    required this.onShareScreen,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (isHost || cohostActive)
          FilledButton.icon(
            onPressed: onToggleCamera,
            icon: const Icon(Icons.videocam),
            label: Text('live_source_camera'.tr()),
          ),
        if (isHost || cohostActive)
          FilledButton.icon(
            onPressed: onToggleMic,
            icon: const Icon(Icons.mic),
            label: Text('live_microphone'.tr()),
          ),
        if (isHost)
          FilledButton.icon(
            onPressed: onShareScreen,
            icon: const Icon(Icons.screen_share),
            label: Text('live_share_screen'.tr()),
          ),
        if (!isHost)
          FilledButton.tonalIcon(
            onPressed: cohostActive
                ? null
                : (cohostRequested ? onCancelCohostRequest : onRequestCohost),
            icon: Icon(
              cohostActive
                  ? Icons.record_voice_over
                  : (cohostRequested ? Icons.hourglass_top : Icons.call),
            ),
            label: Text(
              cohostActive ? '连麦中' : (cohostRequested ? '取消申请' : '申请连麦'),
            ),
          ),
        FilledButton.icon(
          onPressed: onLeave,
          icon: const Icon(Icons.exit_to_app),
          label: Text(isHost ? '结束直播' : '离开'),
        ),
      ],
    );
  }
}

/// 连麦请求栏组件
///
/// 显示观众的连麦申请，主播可接受或拒绝。
class _CohostRequestBar extends StatelessWidget {
  /// 连麦请求列表
  final List<_CohostRequest> requests;

  /// 接受回调
  final ValueChanged<_CohostRequest> onAccept;

  /// 拒绝回调
  final ValueChanged<_CohostRequest> onReject;

  const _CohostRequestBar({
    required this.requests,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final request = requests.first;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.record_voice_over, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${request.name} 申请连麦',
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => onReject(request),
            child: Text('notification_call_reject'.tr()),
          ),
          FilledButton(
            onPressed: () => onAccept(request),
            child: Text('notification_call_accept'.tr()),
          ),
        ],
      ),
    );
  }
}

/// 直播视频画面组件
///
/// 渲染参与者的视频轨道，优先显示屏幕共享，其次显示摄像头画面。
/// 无视频时显示占位图标。
class _LiveVideoSurface extends StatelessWidget {
  /// 参与者对象
  final Participant participant;

  /// 画面标签
  final String label;

  const _LiveVideoSurface({required this.participant, required this.label});

  /// 获取当前可显示的视频轨道
  ///
  /// 优先返回屏幕共享轨道，其次返回摄像头轨道。
  VideoTrack? _visibleVideoTrack() {
    for (final publication in participant.videoTrackPublications) {
      if (publication.isScreenShare &&
          !publication.muted &&
          publication.subscribed &&
          publication.track is VideoTrack) {
        return publication.track as VideoTrack;
      }
    }
    for (final publication in participant.videoTrackPublications) {
      if (!publication.isScreenShare &&
          !publication.muted &&
          publication.subscribed &&
          publication.track is VideoTrack) {
        return publication.track as VideoTrack;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final track = _visibleVideoTrack();
    return Stack(
      children: [
        if (track != null)
          VideoTrackRenderer(track, fit: VideoViewFit.contain)
        else
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off, size: 72, color: Colors.white54),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        Positioned(
          left: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              participant.identity,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
