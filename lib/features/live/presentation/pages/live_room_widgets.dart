part of 'live_room_page.dart';

class _BottomControlSection extends StatelessWidget {
  final bool isHost;
  final List<_CohostRequest> cohostRequests;
  final bool cohostRequested;
  final bool cohostActive;
  final bool showMobileChat;
  final List<_LiveChatMessage> messages;
  final TextEditingController chatController;
  final VoidCallback onSendMessage;
  final ValueChanged<_CohostRequest> onAcceptCohost;
  final ValueChanged<_CohostRequest> onRejectCohost;
  final VoidCallback onRequestCohost;
  final VoidCallback onCancelCohostRequest;
  final Future<void> Function() onToggleCamera;
  final Future<void> Function() onToggleMic;
  final Future<void> Function() onShareScreen;
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
                        decoration: const InputDecoration(
                          hintText: '说点什么...',
                          hintStyle: TextStyle(color: Colors.white54),
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

class _RoomHeader extends StatelessWidget {
  final bool isHost;
  final String roomId;
  final String title;
  final LiveVisibility visibility;
  final LiveSource source;
  final String connectionState;
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

class _Badge extends StatelessWidget {
  final String label;
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

class _ChatPanel extends StatelessWidget {
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

class _LiveSidePanel extends StatelessWidget {
  final List<_LiveChatMessage> messages;
  final TextEditingController chatController;
  final bool isHost;
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
                label: const Text('发送'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveControls extends StatelessWidget {
  final bool isHost;
  final bool cohostRequested;
  final bool cohostActive;
  final VoidCallback onRequestCohost;
  final VoidCallback onCancelCohostRequest;
  final VoidCallback onToggleCamera;
  final VoidCallback onToggleMic;
  final VoidCallback onShareScreen;
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
            label: const Text('摄像头'),
          ),
        if (isHost || cohostActive)
          FilledButton.icon(
            onPressed: onToggleMic,
            icon: const Icon(Icons.mic),
            label: const Text('麦克风'),
          ),
        if (isHost)
          FilledButton.icon(
            onPressed: onShareScreen,
            icon: const Icon(Icons.screen_share),
            label: const Text('共享屏幕'),
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

class _CohostRequestBar extends StatelessWidget {
  final List<_CohostRequest> requests;
  final ValueChanged<_CohostRequest> onAccept;
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
            child: const Text('拒绝'),
          ),
          FilledButton(
            onPressed: () => onAccept(request),
            child: const Text('同意'),
          ),
        ],
      ),
    );
  }
}

class _LiveVideoSurface extends StatelessWidget {
  final Participant participant;
  final String label;

  const _LiveVideoSurface({required this.participant, required this.label});

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
